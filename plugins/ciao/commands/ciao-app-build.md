---
name: ciao-app-build
description: Build an app in Ciao from a spec file, unattended. Creates the project, sends the spec and seed to the main agent, reviews the result against the spec, and returns a clone link. Args - path to the spec file, optional project name.
---

Use the `ciao-app-build` skill.

Args (whitespace-separated):
1. Path to the spec markdown. Required.
2. Project name. Optional; defaults to the spec's first heading.

This runs unattended and takes a while. Do not narrate every step; report the
clone link and the review verdict at the end.
