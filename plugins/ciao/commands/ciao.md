---
name: ciao
description: Show available Ciao plugin commands and what they do
---

Print a short help message listing the Ciao plugin's slash commands. Do
not call any API.

Reply with exactly this content:

```
Ciao plugin — drive Ciao from the terminal

Commands:
  /ciao-whoami                    Show the active workspace, user, and PAT details
  /ciao-handoff [project]         Ship the current conversation to a project as a subagent
  /ciao-projects                  List your Ciao projects
  /ciao-status [project]          Project state: blocks, env names, branch
  /ciao-playbooks [project]       List QA playbooks
  /ciao-playbook-run [playbook]   Run a playbook against an open session
  /ciao-playbook-create           Create a playbook from local context

Setup:
  Mint a token at https://app.ciao.dev → Integrations → Personal access tokens
  Save it to ~/.ciao/credentials as:
    CIAO_TOKEN=ciao_pat_...

  The workspace is encoded in the token. Optional overrides:
    CIAO_API=<integrations-api base URL>   (default: prod)
    CIAO_AGENT=<agent-runtime base URL>    (default: prod)

Docs: https://github.com/Desygner/cc-marketplace/tree/main/plugins/ciao
```
