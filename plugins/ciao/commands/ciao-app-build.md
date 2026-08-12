---
name: ciao-app-build
description: Build an app in Ciao from a spec file, unattended. Creates the project, sends the spec and seed to the main agent, reviews the result against the spec, and returns a clone link. Arg - path to the spec file.
---

Use the `ciao-app-build` skill.

Arg: path to the spec markdown. Required, and the only one.

The project's name and description are written by the skill as product copy in
the recipient's language, never derived from the spec's heading or filename —
those get read by the person on the clone landing page.

This runs unattended and takes a while. Do not narrate every step; report the
clone link and the review verdict at the end.
