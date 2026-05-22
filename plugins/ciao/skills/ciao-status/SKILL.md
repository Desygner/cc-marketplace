---
name: ciao-status
description: Summarize the current state of a Ciao project — installed blocks, env var names, basic metadata. Use when the user asks "what's the state of X", "what blocks does X use", "what env vars does X have".
---

# ciao-status

Returns a project's metadata, installed blocks, and env var NAMES (never
values).

## How to use

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"
PROJECT_ID="$(ciao_resolve_project "$user_project_hint")"
RESPONSE="$(ciao_api get_project "$(jq -n --arg pid "$PROJECT_ID" '{project_id: $pid}')")"
```

`RESPONSE` has three sections:

```json
{
  "project": { "id", "name", "slug", "description", "git_branch", ... },
  "blocks":  [ { "name", "display_name", "version" } ],
  "env_var_names": [ { "key", "environment" } ]
}
```

## How to present

Lead with the headline (name + slug + branch). Then:

1. **Installed blocks** — show their display names, group by purpose if
   obvious. If the list is empty, say so.
2. **Env vars** — group by `environment` (`all` vs `production` vs `test`).
   Show keys only. Make it clear values are not returned (the CLI never
   sees secret values).

Example:

```
my-landing-page (slug: my-landing-page, branch: main)
Built on a landing page generator with Supabase auth.

Blocks (2):
  · Supabase backend (v2.1.0)
  · Figma design sync (v1.4.0)

Env vars (6 keys across 2 environments):
  all:        STRIPE_PUB_KEY, ANALYTICS_ID
  production: STRIPE_SECRET_KEY, DATABASE_URL, JWT_SECRET
  test:       STRIPE_SECRET_KEY
```

## Failures

- `404 Project not found` → bad project id, list projects first
- `403 Project not in allowlist` → PAT restricted to other projects
- `403 Missing required scope: projects:read` → PAT lacks the scope
