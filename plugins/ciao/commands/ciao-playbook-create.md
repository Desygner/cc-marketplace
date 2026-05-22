---
name: ciao-playbook-create
description: Create a new Ciao QA playbook from a local markdown brief. Args: optional name and optional project hint.
---

Use the `ciao-playbook-create` skill.

Before calling the API, gather:
1. Name (ask if not in args)
2. Body (markdown brief). Prefer to read from a file if the user points
   at one; otherwise ask them to paste it.
3. Criteria (acceptance bullets). Optional but ask once.
4. Project scoping (workspace-wide vs scoped to one project). Default to
   workspace-wide unless the user explicitly says otherwise.

Confirm before creating. Playbooks are durable.
