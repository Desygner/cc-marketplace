---
name: ciao-playbook-create
description: Create a new Ciao QA playbook from a local markdown brief plus acceptance criteria. Use when the user has written a test scenario locally and wants it stored in Ciao for repeated runs.
---

# ciao-playbook-create

Packages a local markdown brief + criteria into a stored playbook. Once
created, the playbook can be run from the QA dashboard or via
`/ciao-playbook-run`.

## What you need

- A **name** (1-200 chars). What the user will see in the QA dashboard.
- A **body** (markdown). The brief the agent reads at launch. Includes
  "what to do", in conversational prose.
- A **criteria** (markdown, optional but recommended). How the agent
  knows it worked. Bullet list of pass conditions.
- A **project_id** (optional). If set, the playbook is scoped to one
  project. Otherwise it's workspace-wide.

If the user has these in local files, read them with the `Read` tool.

## How to use

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"

PROJECT_ID="${PROJECT_ID:-}" # optional
PAYLOAD="$(jq -n \
  --arg name "$NAME" \
  --arg body "$BODY" \
  --arg criteria "$CRITERIA" \
  --arg pid "$PROJECT_ID" \
  '{
    name: $name,
    body: $body,
    criteria: (if $criteria == "" then null else $criteria end),
    project_id: (if $pid == "" then null else $pid end)
  } | with_entries(select(.value != null))')"

RESPONSE="$(ciao_api create_playbook "$PAYLOAD")"
```

Returns the new playbook (id, name, etc.). Report the id and a browser
link: `https://app.ciao.dev/w/<workspace>/qa/playbooks/<id>`.

## Before creating

Ask the user one quick confirmation: "I'm about to create the playbook
'<name>' in <project or workspace>. OK?" Playbook creation writes a
durable row; better to confirm than to litter the dashboard with drafts.

If the user wants to test the playbook before saving, suggest they kick
off a one-off subagent first (`/ciao-handoff`) with the brief, see how
the agent interprets it, then come back to create the playbook once they
like the wording.

## Failures

- `403 Missing required scope: playbooks:write` → re-mint the PAT
- `400 mode_id` failures → the default `qa-buddy` mode should always
  exist; if not, the workspace is misconfigured
- `403 create_playbook requires a personal access token` → the caller is
  using an integration api_read key, not a PAT. Mint a PAT instead.
