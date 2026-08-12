---
name: ciao-app-build
description: Build an app in Ciao from a spec file, unattended. Creates the project, sends the spec to the main agent, waits for each turn, and returns a clone link. Arg - path to the spec file.
---

Use the `ciao-app-build` skill.

Arg: path to the spec markdown. Required.

The skill runs the mechanics only — create, prompt, wait, share. What the app
should be comes from the spec and from whatever instructions the caller passes
alongside it; the skill adds none of its own.

Set `NAME` (required) and optionally `DESCRIPTION` and `FOLDER`. These are shown
wherever the project appears, including to anyone who opens the clone link, so
they are never derived from the spec's heading or filename.

This runs unattended and takes a while. Do not narrate every step; report the
clone link at the end.
