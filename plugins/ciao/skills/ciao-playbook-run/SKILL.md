---
name: ciao-playbook-run
description: Trigger a Ciao QA playbook run. Use when the user asks "run the login flow playbook", "kick off the smoke test on X".
---

# ciao-playbook-run

Starts a playbook execution. The playbook's mode (e.g. `qa-buddy`) opens
a session, the agent reads the brief + criteria, runs the linked
recordings, and reports a verdict.

## How to use

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"

PAYLOAD="$(jq -n \
  --arg sid "$AGENT_SESSION_ID" \
  --argjson params "${PARAMS:-{}}" \
  '{agent_session_id: $sid, params: $params}')"

RESPONSE="$(ciao_agent_post "/playbooks/$PLAYBOOK_ID/runs" "$PAYLOAD")"
```

Returns the playbook body, criteria, and the run id. The caller is
expected to attach a WebSocket and send the first prompt — but the CLI
flow stops at "run registered." Report the run id and a browser link.

## When to prefer the browser

If the playbook has runtime parameters (params_schema is non-empty), the
form rendering belongs in the browser. Resolve the workspace slug with
`ciao_workspace_slug` and link the user to the QA dashboard at
`https://app.ciao.dev/w/$WS_SLUG/qa/playbooks`. The CLI is best for
parameterless playbooks.

## Failures

- `403 Missing required scope: playbooks:run` → re-mint the PAT
- `404 playbook not found` → bad id, list playbooks first
- `400 agent_session_id required` → the run needs an existing session;
  spawn one with `/ciao-handoff` first, then chain the run
