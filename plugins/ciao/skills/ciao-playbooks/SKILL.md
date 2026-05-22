---
name: ciao-playbooks
description: List or read QA playbooks for a Ciao project. Use when the user asks "what playbooks does X have", "show me the login flow playbook", "what are we testing on X".
---

# ciao-playbooks

Lists or reads QA playbooks (reusable agent recipes with markdown brief +
acceptance criteria + optional browser recordings).

## List

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"

# Workspace-wide
RESPONSE="$(ciao_api list_playbooks)"

# Or filtered to one project
PROJECT_ID="$(ciao_resolve_project "$user_project_hint")"
RESPONSE="$(ciao_api list_playbooks "$(jq -n --arg pid "$PROJECT_ID" '{project_id: $pid}')")"
```

Shape: `{ "playbooks": [ { id, name, description, mode_id, project_id, ... } ] }`.

## Get one

```bash
RESPONSE="$(ciao_api get_playbook "$(jq -n --arg id "$PLAYBOOK_ID" '{playbook_id: $id}')")"
```

Returns the full playbook (body, criteria, params_schema) plus linked
recordings with their role and ordinal.

## How to present

For lists, just names + descriptions. For a single playbook, show:

1. Name + description
2. The markdown brief (body) — keep it readable
3. Acceptance criteria
4. Linked recordings (just the names and roles, e.g. "setup: login flow")

Do not dump JSON. Translate to readable prose.

## Failures

- Empty list → tell the user they have no playbooks for this project,
  suggest creating one with `/ciao-playbook-create`
- `403 Missing required scope: playbooks:read` → re-mint the PAT
