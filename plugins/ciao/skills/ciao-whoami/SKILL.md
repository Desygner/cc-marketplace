---
name: ciao-whoami
description: Show which Ciao workspace + user the current PAT belongs to, plus the token's scopes and allowlist. Use when the user wants to confirm their CLI setup, or before any other skill that needs the workspace slug for browser deep links.
---

# ciao-whoami

Resolves the active CLI identity: which workspace + user the PAT
represents, and what the token is allowed to do.

## How to use

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"
RESPONSE="$(ciao_api whoami)"
```

Response shape:

```json
{
  "workspace": { "id": "...", "slug": "...", "name": "..." },
  "user":      { "id": "...", "email": "...", "display_name": "..." },
  "token":     { "id": "...", "name": "...", "token_prefix": "ciao_pat_xx",
                 "scopes": [...], "project_allowlist": [...] | null,
                 "expires_at": "..." | null, "last_used_at": "..." | null },
  "auth":      { "kind": "pat", "scopes": [...] }
}
```

`user` and `token` are present for PAT auth, null for integration api_read
keys (which have no human identity).

## How to present

When the user asks "who am I" or runs `/ciao-whoami`, print a compact
summary:

```
Workspace: Acme (slug: acme)
User:      Ignacio <ziroargentino@gmail.com>
Token:     my-laptop · ciao_pat_xx… · 5 scopes · no expiry
Scopes:    projects:read, subagent:spawn, playbooks:read, playbooks:run, playbooks:write
Allowlist: all projects (token is workspace-wide)
```

When another skill needs the workspace slug for a deep link, call this
silently, extract `workspace.slug`, and use it in the URL.

## Failures

- `401 Unauthorized` → token missing, expired, or revoked. Ask the user
  to re-mint at https://app.ciao.dev → Integrations → Personal access tokens.
- `403` does not apply here (whoami requires no scope).
