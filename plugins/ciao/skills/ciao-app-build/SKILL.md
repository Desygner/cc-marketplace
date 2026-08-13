---
name: ciao-app-build
description: Build an app in Ciao from a spec file, end to end and unattended. Creates the project, drives the main agent through the build, waits for each turn, and returns a clone link. Use when a spec is ready and somebody wants the app built without sitting in the builder.
---

# Building an app in Ciao from a spec

Spec in, clone link out. This skill owns the mechanics only: creating the
project, sending prompts in order, waiting for each turn, and turning on
sharing.

**What the app should be is the caller's business.** The spec says that. This
skill is installed in every Ciao workspace, so anything it asserts about scope,
design, quality or naming is one team's opinion imposed on everyone else's
builds. Carry the caller's instructions; add none.

## What drives what

Prompts go to the **main agent**, one at a time. Not subagents:
`/subagents/spawn` is for parallel work that can be merged, and these prompts
are foundational — the schema, the seed, the fixes — each depending on the last.
Two in flight at once means two sets of edits on the same tree.

The queue enforces that, and `ciao_wait_idle` is how you respect it. **Never
send a prompt without waiting for the previous turn to finish.**

## The sequence

```bash
source "$CLAUDE_SKILL_DIR/../../lib/ciao-api.sh"

SPEC_PATH="$1"
SPEC="$(cat "$SPEC_PATH")"
NAME="${NAME:?a project name is required}"
DESCRIPTION="${DESCRIPTION:-}"
FOLDER="${FOLDER:-}"            # optional; created on demand if named
```

`NAME` and `DESCRIPTION` are inputs, never derived. They render verbatim
wherever the project appears, including the clone landing page, so a name taken
from the spec's heading or a description built from its filename leaks the
caller's filing to whoever opens the link. If they are missing, ask — do not
invent them from the path.

**1. Create the project.**

```bash
PROJECT="$(ciao_api create_project "$(jq -n --arg n "$NAME" --arg d "$DESCRIPTION" \
  --arg f "$FOLDER" \
  '{name: $n, description: $d} + (if $f == "" then {} else {folder: $f} end)')")"
PROJECT_ID="$(echo "$PROJECT" | jq -r .project.id)"
```

**2. Wake its sandbox** before the first prompt, so the turn does not begin by
waiting on a cold pod.

```bash
ciao_api ensure_session "$(jq -n --arg pid "$PROJECT_ID" '{project_id: $pid}')" >/dev/null
```

**3. Send the spec as an attachment, never inside the prompt.**

A prompt is capped at 10,000 characters and a spec is longer than that. Attach
it: the file is delivered into the sandbox at `/home/sandbox/uploads/<name>`
before the turn starts, and the agent is told in its system prompt that it is
there. The prompt then only has to say what to do with it.

```bash
send() {                              # send "<prompt>" [attach-path ...]
  local prompt="$1"; shift
  local atts="[]"
  for path in "$@"; do
    atts="$(jq -n --argjson a "$atts" --arg n "$(basename "$path")" \
      --rawfile c "$path" '$a + [{name: $n, content: $c}]')"
  done
  ciao_api send_prompt "$(jq -n --arg pid "$PROJECT_ID" --arg p "$prompt" \
    --argjson a "$atts" \
    '{project_id: $pid, prompt: $p} + (if ($a|length) == 0 then {} else {attachments: $a} end)')" >/dev/null
  ciao_wait_idle "$PROJECT_ID" main 2400
}

send "Read /home/sandbox/uploads/$(basename "$SPEC_PATH"), copy it to docs/spec.md so later turns can read it, then implement it." "$SPEC_PATH"
```

Attaching also buys a better model. The effort scorer sets a floor when a
prompt carries attachments, so the build does not land on the bottom rung the
way a bare one-line prompt does.

If the caller supplied further instructions — a design brief, a seed file,
house rules — send each as its own turn, in the order given, waiting between
them. Long ones are attachments too; `send` takes as many paths as you give it.
A migration or a seed is better attached than pasted, because the agent can
then apply the file rather than retype it. Do not add instructions of your own.

**4. Review, if the caller asked for it.** Get the preview URL from `ciao_api
get_project`, open it, and check it against **the spec** rather than your own
taste. One prompt per round, listing only what is broken.

Bounds, because a review loop without them becomes a rewrite:

- Three rounds maximum, then stop and report.
- Every finding traces to a line in the spec.
- Never add scope. If it is not in the spec it is not a finding.
- An empty round ends the loop.

### One page, reused, then closed

A review has many checks and needs one tab for all of them. Every browser page
is a separate process holding over a hundred megabytes for as long as it is
open, so a loop that opens a page per check quietly costs a gigabyte and keeps
it until the machine reboots.

- Start with `list_pages`. If a page is already there, `select_page` it. Only
  call `new_page` when there is nothing to reuse.
- Move with `navigate_page`, never by opening another tab. Reloading is
  `navigate_page` to the same URL.
- Check widths with `resize_page`, not with a second window. Phone and desktop
  are two sizes of one page.
- `close_page` when the review ends, including when it ends badly. A run that
  gave up still closes what it opened.

**5. Turn on sharing and take the link.**

```bash
CLONE="$(ciao_api clone_link "$(jq -n --arg pid "$PROJECT_ID" \
  '{project_id: $pid, enable: true, keys: []}')")"
CLONE_URL="$(echo "$CLONE" | jq -r '.token | "https://app.ciao.dev/clone#" + .')"
```

Pack no keys unless the caller says to. The clone provisions its own database,
so it needs none of the source's credentials.

## Report back

Two lines: what exists now with the clone link, and what the caller should do
next. Anything unresolved belongs in their spec directory, not in chat. If the
three-round limit was reached with findings outstanding, say so — that is a
spec problem for a human.

## Failure modes

- `403 Only a personal access token can create a project` — the token is an
  integration key, not a PAT. Mint a PAT in Integrations.
- `ciao_wait_idle` returns `timeout` — the turn is still running after forty
  minutes. Do not send another prompt on top of it. Report the project and stop.
- `413 The prompt is N characters and the limit is 10,000` — attach the long
  text instead of pasting it. Do not chop the spec into fragments to squeeze
  under the limit: the agent then holds a quarter of the brief per turn and
  builds accordingly.

## Believe the sandbox, not the preview

When a turn reports work you cannot see, check what actually changed before
concluding the runtime is broken. `get_project` returns a preview URL that can
serve a stale bundle, and reading an old page from it looks exactly like an
agent that did nothing.

The evidence that settles it is in the turn itself: `turn_status` and the
project's chat messages carry a `commit_sha` and a unified diff per file. A
turn with a diff did the work. If the preview disagrees with the diff, the
preview is what is wrong, and that is worth reporting on its own.
