---
name: ciao-context
description: Load a Ciao project's context (CLAUDE.md, blocks, env var names) into the current conversation so local Claude has the same picture as Ciao would. Use when the user wants to reason locally about a Ciao project before handing off.
---

# ciao-context

Pulls a Ciao project's metadata into the current conversation so you can
reason about it locally before handing off. Composes on top of
`ciao-status` and presents the result as conversation context, not as a
user-facing summary.

## How to use

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"
PROJECT_ID="$(ciao_resolve_project "$user_project_hint")"
RESPONSE="$(ciao_api get_project "$(jq -n --arg pid "$PROJECT_ID" '{project_id: $pid}')")"
```

## Difference from ciao-status

- `ciao-status` is for **the user** — formatted, pretty, short.
- `ciao-context` is for **you** — structured, dense, kept in your working
  memory so subsequent reasoning uses it.

After fetching, internalize:

- Project's purpose (from `description`)
- Which blocks are active (affects what stack assumptions to make)
- What env vars exist (avoid suggesting ones already configured)
- Current branch (affects "what would change" reasoning)

Acknowledge the load with one short line, e.g. "Loaded context for
my-landing-page (Supabase + Figma blocks, 6 env vars, on main)." Do not
dump the full JSON.

## When to refresh

Once per conversation is enough unless the user mentions they just
deployed or changed something. The project rarely changes mid-session.
