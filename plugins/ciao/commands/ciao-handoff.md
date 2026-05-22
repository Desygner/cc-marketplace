---
name: ciao-handoff
description: Package the current conversation and ship it to a Ciao project as a subagent. Args (all optional): project name or slug, subagent label.
---

The user wants to hand off the current conversation to a Ciao project as
a subagent. Use the `ciao-handoff` skill.

Args (whitespace-separated, all optional):
1. Project hint — name, slug, or partial match. If missing, list projects
   first and ask which one.
2. Subagent label — short friendly name for the new subagent. If missing,
   Ciao auto-generates one ("Brave Otter" etc.).

Before firing, confirm with the user:
- The project you resolved
- A one-line summary of what the subagent will do
- The convergence mode (default: `auto`)

Then proceed exactly as the skill describes.
