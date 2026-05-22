---
name: ciao-projects
description: List the user's Ciao projects in the active workspace. Use when the user asks "what are my projects", "list my Ciao apps", or before any other skill that needs a project id.
---

# ciao-projects

Lists projects the user has access to in the configured workspace.

## How to use

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"
RESPONSE="$(ciao_api list_projects)"
```

`RESPONSE` is JSON of the shape:

```json
{
  "projects": [
    {
      "id": "...",
      "name": "...",
      "slug": "...",
      "git_branch": "main",
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

## How to present

Render a short table or list. Show name + slug. Skip the id unless the
user asks for it. Sort by `updated_at` desc (most recently touched first)
since that matches user intuition better than alphabetical.

Example output:

```
3 projects:
  · my-landing-page    main       (updated 2 hours ago)
  · admin-dashboard    feat/auth  (updated yesterday)
  · invoicing-app      main       (updated last week)
```

If the list is empty, tell the user they have no projects and link them
to `https://app.ciao.dev` to create one.

## Failures

- Empty list (no error) → tell the user, link to app.ciao.dev
- `401` → expired token, ask the user to re-mint
- `429` → rate limit, wait a few seconds and retry
