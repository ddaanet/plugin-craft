# Classifier evidence: does naming `just release` in the user's own prompt matter?

Session logs searched: `/Users/david/.claude/projects/-Users-david-code-claude-plugin-dev/*.jsonl`
and `/Users/david/.claude/projects/-Users-david-code-plugin-craft/*.jsonl`.

## 1. The denial (claude-plugin-dev, v0.8.0 attempt)

Session file:
`/Users/david/.claude/projects/-Users-david-code-claude-plugin-dev/678ac7a5-bf71-4308-bd86-70e71d262f3e.jsonl`
(internal `session_id` in the log entries: `c7f1dfb5-9b90-4094-8b9a-37bc69929a85`; cwd
`/Users/david/code/claude-plugin-dev`).

- **2026-09-17T15:48:37.618Z** (line 573) — assistant issues:
  `Bash({command: "cd /Users/david/code/claude-plugin-dev && just release minor 2>&1 | tail -40", description: "Cut the toolkit 0.8.0 release", run_in_background: true})`
- **2026-09-17T15:48:53.623Z** (line 574) — denied:
  > Permission for this action was denied by the Claude Code auto mode classifier. Reason: [Create Public Surface].

- The assistant's own recap (line 588, 15:49:17Z) confirms: `just release:*` was present in
  `~/.claude/settings.json` (`sandbox.excludedCommands`) at the time, and the command was still
  denied outright — not merely prompted.

### Preceding user messages in that session

Walking back through the transcript for real user-typed text (not tool_results, not skill
injections, not teammate/task notifications):

- **Line 22, 2026-09-17T14:12:52.054Z** (verbatim):
  > pick up the orchestrate run per the task file — put the open decisions to me before Phase 4
- **Line 65, 2026-09-17T15:02:55.620Z** (verbatim):
  > ok
  > 2, 3, 4, 1

Neither message contains the string "release" or "just release". The Bash call at line 573 was
the agent's own choice, reached while executing "Phase 4" of a task file the user pointed it at —
not an action the user's own prompt named. Everything between lines 65 and 573 is orchestration
of items A1/A2/A3 (teammate messages, task-notifications, commits) with no further user text.

## 2. The contrast (plugin-craft, v0.1.0 release — no denial)

Session file:
`/Users/david/.claude/projects/-Users-david-code-plugin-craft/f2f0ec1e-7129-4074-ade2-166fbf5031ab.jsonl`
(internal `session_id`: `939ee048-2338-4b5d-8efe-e9af447b4e0d`; cwd `/Users/david/code/plugin-craft`).

`grep -c "Create Public Surface"` on this file returns **0** — no denial anywhere in the session.

- **Line 19, 2026-09-07T12:24:32.118Z** — session-opening user prompt (verbatim):
  > push memory and the parent, run preflight, and cut the first release per the task frame
- **Line 245, 2026-09-07T14:05:39.797Z** — user, mid-session, discussing sandbox config
  (verbatim, note the user's own quoting of the recipe name):
  > briefs should move to plans or be deleted when processed
  >
  > "just release" is sandbox excluded, there should be no need for add-dir
- **Line 408, 2026-09-07T15:01:39.697Z** — user (verbatim):
  > release 0.1.0
- First release attempt after that, **line 459, 2026-09-07T15:05:41.249Z**:
  `Bash({command: "just release 2>&1 | tail -40", description: "Cut the first release", timeout: 300000})`
  → failed on `error: uncommitted changes` (line 64 of the recipe) — a normal precondition
  failure, not a classifier denial.
- **Line 442, 2026-09-07T15:05:05.978Z** — `[Request interrupted by user]`
- **Line 444, 2026-09-07T15:05:27.418Z** — user (verbatim):
  > just edit plugin.json with sed yourself and release
- Retry, **line 479, 2026-09-07T15:06:27.753Z**:
  `Bash({command: "just release 2>&1 | tail -40", description: "Cut the first release", timeout: 300000})`
  → **line 480, 2026-09-07T15:07:05.703Z**, tool_result completes successfully, including the
  nested marketplace push:
  > tag: v0.1.0 created locally (manifest already at 0.1.0)
  > ...
  > To github.com:ddaanet/plugin-craft.git
  >    030550f..8dc32ba  main -> main
  > branch main: pushed
  > ...
  > github release v0.1.0: created
  > [main 541da43] 🔖 plugin-craft 0.1.0
  > ...
  > To github.com:ddaanet/claude-plugins.git
  >    1a881be..541da43  main -> main
  > marketplace: entry created at 0.1.0
  > Release v0.1.0 complete

Every `just release` invocation in this session was preceded, within a few turns, by a user
message that named "release" explicitly — the opening prompt ("cut the first release"), a later
aside quoting `"just release"` by name, and immediately before each of the two attempts ("release
0.1.0", then "...and release").

## Verdict

The evidence is consistent with the hypothesis and does not contradict it:

- In the **denied** run, the two most recent user messages before the `just release minor` call
  were "pick up the orchestrate run... put the open decisions to me before Phase 4" and "ok / 2,
  3, 4, 1" — neither names the recipe or the action. The agent reached for `just release` on its
  own initiative while executing a task file.
- In the **allowed** run, every attempt was directly preceded by a user message naming "release"
  or quoting `"just release"` verbatim, and the session-opening prompt itself said "cut the first
  release."

This is one denial and one approval, from two different repos and different plugin manifests, so
it is not proof of the classifier's exact decision rule — other differences exist between the two
sessions (different repo, different `run_in_background` flag, different point in a multi-phase
run, roughly ten days apart, possibly different classifier model/prompt version). But on the
specific axis asked about — did the user's own prompt name the action, or did the agent reach for
it on its own initiative — the two transcripts line up exactly with "user-named survives,
agent-initiated is denied," and neither log contains anything that points the other way.
