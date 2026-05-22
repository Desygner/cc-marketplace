---
name: ciao-handoff
description: Package the current conversation into a structured prompt and hand it off to a Ciao project as a subagent. Use when the user has reached a plan locally and wants Ciao to build it.
---

# ciao-handoff

You are about to hand off the current conversation to a Ciao project. Ciao
will spawn a subagent that picks up where you left off and does the actual
build inside a sandbox.

## When to use this

The user has:
- Done research / planning locally with you
- Reached a concrete next step they want built
- Either named a Ciao project, or asked you to "send this to Ciao"

If they haven't reached a plan, finish the planning first. Handoff is for
shipping a clear ask, not for offloading half-formed thoughts.

## How to package the prompt

Compose a single self-contained prompt that includes:

1. **Goal** in one sentence. What should the subagent build or change?
2. **Context** the subagent needs: relevant files in the local repo
   (paste file paths AND key excerpts), constraints discussed, decisions
   already made.
3. **Acceptance** in 2-4 bullets: how will we know it worked?
4. **Out of scope**: things explicitly NOT to do.

Aim for under 1500 words. The subagent has its own context window and its
own copy of the project; it does not see your local repo. Be generous with
file paths and short excerpts, but do not paste entire files.

## How to fire it

Resolve the project id (from the user's hint via `ciao_resolve_project`),
then POST to `/subagents/spawn`:

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"

PROJECT_ID="$(ciao_resolve_project "$user_project_hint")"
PROMPT="$(cat <<'EOF'
<your packaged prompt here>
EOF
)"

PAYLOAD="$(jq -n \
  --arg pid "$PROJECT_ID" \
  --arg prompt "$PROMPT" \
  --arg label "$user_supplied_label_or_empty" \
  '{
    project_id: $pid,
    prompt: $prompt,
    convergence: "auto",
    plan_mode: false,
    label: (if $label == "" then null else $label end)
  } | with_entries(select(.value != null))')"

RESPONSE="$(ciao_agent_post /subagents/spawn "$PAYLOAD")"
SESSION_ID="$(echo "$RESPONSE" | jq -r .session_id)"
```

## Defaults

- `convergence: "auto"` — the subagent merges itself when it finishes.
  Override to `"manual"` if the user explicitly says they want to review
  the diff before it lands. If you find yourself overriding to `manual`
  more than once or twice for the same user, propose editing this skill
  to flip the default.
- `plan_mode: false` — planning happened locally with you. Do not double-plan.

## After firing

Report back to the user with:
- The friendly label (returned in `RESPONSE`) or the session id
- A link they can open. Build it using the workspace slug from
  `ciao_workspace_slug` and the project's slug:

  ```bash
  WS_SLUG="$(ciao_workspace_slug)"
  PROJECT_SLUG="$(echo "$projects_json" | jq -r --arg id "$PROJECT_ID" '.projects[] | select(.id == $id) | .slug')"
  LINK="https://app.ciao.dev/w/$WS_SLUG/projects/$PROJECT_SLUG/builder?subagent=$SESSION_ID"
  ```

- One line about what the subagent will do

Do not poll for status from the CLI. The user can watch in the browser.

## Failure modes

- `401 Unauthorized` → token expired or revoked. Tell the user to re-mint.
- `403 Missing required scope: subagent:spawn` → their PAT does not grant
  this scope. Send them to Integrations → Personal access tokens to mint
  a new one with the right scope.
- `403 Project not in allowlist` → their PAT is restricted to specific
  projects. Either pick an allowed project or mint a wider token.
