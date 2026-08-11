---
name: ciao-app-build
description: Build an app in Ciao from a spec file, end to end and unattended. Creates the project, drives the main agent through the build and the seed, reviews the running app against the spec, and returns a clone link. Use when a spec is ready and somebody wants the app to exist without sitting in the builder.
---

# Building an app in Ciao from a spec

One spec in, one clone link out. Everything between is this skill's job and
nobody watches it happen.

## What drives what

Prompts go to the **main agent**, one at a time. Not subagents: `/subagents/spawn`
is for parallel work that can be merged, and these prompts are foundational —
the schema, the seed, the fixes — each depending on the last. Two of them in
flight at once means two sets of edits on the same tree.

The queue enforces that for you, and `ciao_wait_idle` is how you respect it.
**Never send a prompt without waiting for the previous turn to finish.**

## The sequence

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"

SPEC_PATH="$1"
SPEC="$(cat "$SPEC_PATH")"
NAME="${2:-$(head -1 "$SPEC_PATH" | sed 's/^#\+ *//')}"
```

**1. Create the project.**

```bash
PROJECT="$(ciao_api create_project "$(jq -n --arg n "$NAME" \
  --arg d "Boilerplate built from $(basename "$SPEC_PATH")" \
  '{name: $n, description: $d}')")"
PROJECT_ID="$(echo "$PROJECT" | jq -r .project.id)"
```

**2. Wake its sandbox** before the first prompt, so the turn does not start by
waiting on a cold pod.

```bash
ciao_api ensure_session "$(jq -n --arg pid "$PROJECT_ID" '{project_id: $pid}')" >/dev/null
```

**3. Send the spec.** Inline, not attached: the API takes JSON only, and a spec
is small. Ask for the spec to be kept in the repo so later turns can re-read it
rather than being re-told.

```bash
send() {
  ciao_api send_prompt "$(jq -n --arg pid "$PROJECT_ID" --arg p "$1" \
    '{project_id: $pid, prompt: $p}')" >/dev/null
  ciao_wait_idle "$PROJECT_ID" main 2400
}

send "$(printf 'Implement this app. Keep the spec at docs/03-app.md so we can iterate against it.\n\n%s' "$SPEC")"
```

**4. Send the seed.** The spec names the tables; the seed fills them with
believable rows for the trade. Real data in a real database — see the "real
software" rule in the calling skill. Generate the SQL from the spec's schema
section and send it as its own turn.

```bash
send "$(printf 'Create a seed.sql with the demo data below and run it after the schema migration.\n\n```sql\n%s\n```' "$SEED_SQL")"
```

**5. Review, in bounded rounds.** This is the part that decides whether the app
is worth linking to, and the part most likely to go wrong.

Get the preview URL from `ciao_api get_project`, open it, and **use it** —
click through the one job the spec names, end to end. Then send one prompt per
round listing only what is actually broken.

Hard limits, because a review loop with no bound turns into a rewrite:

- **Three rounds maximum.** If it is not right after three, stop and report;
  something is wrong with the spec, not the build.
- **Only against the spec.** The one job, the vetting checklist, the language.
  Every finding must trace to a line in the spec.
- **Never add scope.** Not a feature you thought of, not a nice-to-have, not a
  refactor. If it is not in the spec it is not a finding.
- **Report nothing when nothing is broken.** An empty round ends the loop.

Check at minimum: the one job completes; data written survives a hard refresh
(if it does not, the agent built a mock and that is a build failure, not a
polish item); every visible string is in the target language; it is usable at
phone width; nothing says "example", "demo" or "TODO".

**6. Turn on sharing and take the link.**

```bash
CLONE="$(ciao_api clone_link "$(jq -n --arg pid "$PROJECT_ID" \
  '{project_id: $pid, enable: true, keys: []}')")"
CLONE_URL="$(echo "$CLONE" | jq -r '.token | "https://app.ciao.dev/clone#" + .')"
```

Pack no keys unless the spec says to. The clone gets its own database, so it
needs none of the source's credentials.

## Report back

Three lines: the clone link, how many review rounds it took, and anything still
broken that you chose not to fix. If a round hit the three-round limit with
findings outstanding, say so plainly — that is a spec problem for a human.

## Failure modes

- `403 Only a personal access token can create a project` — the token is an
  integration key, not a PAT. Mint a PAT in Integrations.
- `ciao_wait_idle` returns `timeout` — the turn is still running after 40
  minutes. Do not send another prompt on top of it. Report the project link and
  stop.
- The first build comes back with `localStorage` or an in-memory store. That is
  a review finding and round two fixes it. It is never acceptable to ship.
