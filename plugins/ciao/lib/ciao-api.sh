#!/usr/bin/env bash
# Ciao plugin: shared helpers for skills and slash commands.
#
# Skills source this file and call `ciao_api <action> [json_body]`. The
# helper handles loading the token, building the request, and surfacing
# clean error messages.
#
# Sourcing pattern:
#   source "$(dirname "$0")/../lib/ciao-api.sh"
#   ciao_api list_projects
#
# Required tools: bash, curl, jq.
#
# Environment / credentials file (~/.ciao/credentials):
#   CIAO_TOKEN     required — the PAT minted in the Ciao app
#   CIAO_API       optional — integrations-api base URL (default: prod)
#   CIAO_AGENT     optional — agent-runtime base URL (default: prod)
#
# The workspace is encoded in the PAT itself, so the CLI does NOT need to
# know it. Every PAT-gated endpoint derives workspace_id from the token.

set -euo pipefail

CIAO_API_DEFAULT="https://usnucnguvktksltkwjkn.supabase.co/functions/v1/integrations-api"
CIAO_AGENT_DEFAULT="https://app.ciao.dev/api/agent-runtime"
CIAO_CREDENTIALS_FILE="${CIAO_CREDENTIALS_FILE:-$HOME/.ciao/credentials}"

ciao_die() {
  echo "ciao: $*" >&2
  exit 1
}

ciao_require_tools() {
  command -v curl >/dev/null 2>&1 || ciao_die "curl is required but not installed"
  command -v jq   >/dev/null 2>&1 || ciao_die "jq is required but not installed"
}

ciao_load_token() {
  if [[ -n "${CIAO_TOKEN:-}" ]]; then
    return 0
  fi
  if [[ ! -f "$CIAO_CREDENTIALS_FILE" ]]; then
    ciao_die "no token found. Mint one at https://app.ciao.dev → Integrations → Personal access tokens, then save it to $CIAO_CREDENTIALS_FILE as CIAO_TOKEN=..."
  fi
  # shellcheck disable=SC1090
  source "$CIAO_CREDENTIALS_FILE"
  if [[ -z "${CIAO_TOKEN:-}" ]]; then
    ciao_die "$CIAO_CREDENTIALS_FILE exists but CIAO_TOKEN is empty"
  fi
}

# ciao_api <action> [extra_json_body]
#
# Calls the integrations-api edge function. `action` is the dispatch key.
# `extra_json_body` (optional) is a JSON object merged with the action key.
# The server derives workspace_id from the PAT, so the client never sends it.
# Returns the response body on stdout (JSON). Non-2xx responses extract
# `.error` and exit non-zero.
ciao_api() {
  ciao_require_tools
  ciao_load_token
  local action="$1"
  local extra="${2:-{}}"
  local base="${CIAO_API:-$CIAO_API_DEFAULT}"

  local payload
  payload="$(jq -n --arg action "$action" --argjson extra "$extra" \
    '{action: $action} + $extra')"

  local response
  local http_code
  response="$(curl -sS -w '\n%{http_code}' \
    -X POST \
    -H "Authorization: Bearer $CIAO_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "$base")"
  http_code="$(echo "$response" | tail -n1)"
  local body
  body="$(echo "$response" | sed '$d')"

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$body"
    return 0
  fi

  local err
  err="$(echo "$body" | jq -r '.error // empty' 2>/dev/null || true)"
  if [[ -z "$err" ]]; then
    err="HTTP $http_code"
  fi
  ciao_die "$err"
}

# ciao_agent_post <path> <json_body>
#
# Calls the Ciao agent-runtime (POST). Used for /subagents/spawn and
# /playbooks/:id/runs.
ciao_agent_post() {
  ciao_require_tools
  ciao_load_token
  local path="$1"
  local payload="$2"
  local base="${CIAO_AGENT:-$CIAO_AGENT_DEFAULT}"

  local response
  local http_code
  response="$(curl -sS -w '\n%{http_code}' \
    -X POST \
    -H "Authorization: Bearer $CIAO_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "${base}${path}")"
  http_code="$(echo "$response" | tail -n1)"
  local body
  body="$(echo "$response" | sed '$d')"

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$body"
    return 0
  fi

  local err
  err="$(echo "$body" | jq -r '.error // empty' 2>/dev/null || true)"
  if [[ -z "$err" ]]; then
    err="HTTP $http_code"
  fi
  ciao_die "$err"
}

# Resolve a project's id from either a UUID, slug, or partial name.
# Echoes the resolved id on success, exits non-zero on no/many matches.
ciao_resolve_project() {
  local hint="$1"
  local projects
  projects="$(ciao_api list_projects)"
  # Try exact id match first, then slug, then partial name (case-insensitive)
  local hit
  hit="$(echo "$projects" | jq -r --arg q "$hint" \
    '.projects[] | select(.id == $q or .slug == $q) | .id' | head -n1)"
  if [[ -n "$hit" ]]; then
    echo "$hit"
    return 0
  fi
  hit="$(echo "$projects" | jq -r --arg q "$hint" \
    '.projects[] | select((.name | ascii_downcase) | contains($q | ascii_downcase)) | .id')"
  local count
  count="$(echo "$hit" | grep -c . || true)"
  if [[ "$count" -eq 1 ]]; then
    echo "$hit"
  elif [[ "$count" -eq 0 ]]; then
    ciao_die "no project matched '$hint'. Run /ciao-projects to list."
  else
    ciao_die "multiple projects matched '$hint'. Be more specific or pass the slug."
  fi
}
