---
name: ciao-playbooks
description: List Ciao QA playbooks. Arg (optional): project name or slug to scope the list.
---

Use the `ciao-playbooks` skill to list playbooks.

If the user passed a project hint, filter by that project. Otherwise list
workspace-wide. If they ask about a specific playbook by name, look it up
and use the get-one path instead of the list.
