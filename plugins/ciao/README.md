# Ciao plugin for Claude Code + OpenCode

Drive your [Ciao](https://ciao.dev) projects from the terminal.

## Setup

1. Open `app.ciao.dev` → click your profile picture → **Integrations**
2. Open the **Personal access tokens** tab → mint a token with the scopes
   you want (`projects:read`, `subagent:spawn`, `playbooks:*`, etc.)
3. Save the token locally:

   ```
   mkdir -p ~/.ciao && cat > ~/.ciao/credentials <<EOF
   CIAO_TOKEN=ciao_pat_<your token>
   EOF
   chmod 600 ~/.ciao/credentials
   ```

   The workspace is encoded in the token itself, so you don't need to
   set anything else for normal use.

4. Confirm the token works:

   ```
   /ciao-projects
   ```

## What's included

### Slash commands

| Command | Purpose |
|---|---|
| `/ciao-handoff` | Ship the current conversation to a Ciao project as a subagent. The killer one. |
| `/ciao-projects` | List your projects |
| `/ciao-status` | Health summary for a project (blocks, env names) |
| `/ciao-playbooks` | List QA playbooks for a project |
| `/ciao-playbook-run` | Trigger a playbook run |
| `/ciao-playbook-create` | Create a new playbook from a local markdown brief |
| `/ciao` | Help: what each command does |

### Skills

Skills are auto-invoked by Claude when the conversation is relevant.

| Skill | When it triggers |
|---|---|
| `ciao-handoff` | The conversation has reached a plan and the user wants to "send this to Ciao" |
| `ciao-projects` | The user asks "what are my Ciao projects" or similar |
| `ciao-status` | The user asks "what's the state of <project>" |
| `ciao-context` | The user wants to load a Ciao project's CLAUDE.md or block config into the current conversation |
| `ciao-playbooks` | The user asks about QA playbooks |

## How it works

Every skill and command shells out to `curl` + `jq` against the Ciao
integrations-api edge function and the agent-runtime, using the
`CIAO_TOKEN` from `~/.ciao/credentials`. The shared helper is at
`lib/ciao-api.sh`.

No daemon, no MCP server, no compile step. To inspect or extend, edit the
markdown files directly.

## Pointing at a non-prod Ciao

If you run Ciao locally or against a staging environment, override the
defaults in `~/.ciao/credentials`:

```
CIAO_TOKEN=ciao_pat_<your token from the local env>
CIAO_API=http://127.0.0.1:54321/functions/v1/integrations-api
CIAO_AGENT=http://127.0.0.1:8787
```

Both `CIAO_API` (integrations-api base URL) and `CIAO_AGENT` (agent-runtime
base URL) fall back to the prod endpoints when unset.

## Uninstall

```
/plugin uninstall ciao
```

Then remove `~/.ciao/credentials` to also drop the token.
