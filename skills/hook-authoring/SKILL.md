---
name: hook-authoring
description: "What a Claude Code hook receives on stdin and what its stdout JSON can actually do — the control surface, the three output channels and their audiences, and how a `PreToolUse` decision meets the permission pipeline. Use when writing or debugging a hook script, choosing between `systemMessage`, `additionalContext` and stderr, or working out why a block, a rewrite or injected text did not land. Complements `plugin-dev:hook-development`, which covers configuration and the event basics; this covers the payload fields and channel behaviour it omits. Not a style guide for hook message wording."
---

## 1 · The control surface: no hook injects a tool call

No hook can inject a `tool_use`, force a `Read`, or enqueue a tool call. Only
the agentic loop generates tool calls. Hooks can block
(`PreToolUse.permissionDecision`, `Stop`/`PostToolBatch` `decision: "block"`),
rewrite input (`updatedInput`), rewrite a result (`updatedToolOutput`), and
inject text (`additionalContext`) — nothing more.

Verified 2026-07-22 against the shipped binary
(`~/.local/share/claude/versions/2.1.217`), not only the docs: zero occurrences
of `injectToolCall`, `requestTool`, `forceRead`, `injectTool`, `forceToolUse`,
`requestedTools`, `injectedToolCalls`. The four `triggerRead` hits are Node
stream internals (`stream._read = triggerRead`). Controls present in the same
grep: `additionalContext` 180, `updatedInput` 249, `permissionDecision` 34,
`PostToolBatch` 46, `InstructionsLoaded` 27, `systemMessage` 54.

**How to apply:** to get file contents into the model's context
deterministically, don't try to make the agent Read them — have the hook read
them and emit the bytes as `additionalContext`. That is strictly better than a
forced Read: one round trip instead of two, no tool-permission surface, and the
selection stays in a script rather than in agent judgement. `additionalContext`
is honoured at `PreToolUse` as well as `PostToolUse`, and arrives on a deny as
well as when an allowed call then fails (§2 below), so a deny-reason and the injected
bodies can land in the same turn. Two limits apply when the agent must
*edit* what it is shown (see `references/output-channels.md` §4).

`InstructionsLoaded` fires when `CLAUDE.md` and `.claude/rules/*.md` load
(matchers `session_start`, `nested_traversal`, `path_glob_match`, `include`,
`compact`) but is side-effects-only: no decision control, exit code ignored.

## 2 · A deny splits three ways by audience

`hookSpecificOutput.additionalContext` is delivered on a `PreToolUse` **deny**,
not only when a tool call is allowed and then fails. A call the hook blocks
never runs, so it is not a call that failed.

Verified against **CC 2.1.258**, with a scratch `--settings` hook under a
nested `claude --print`. What the three channels do on a deny:

- **`permissionDecisionReason`** becomes the `tool_result` content, with
  `is_error: true`. This is what renders beside the intercepted call.
- **`additionalContext`** lands as a separate transcript entry of
  `"type": "attachment"`, whose `attachment.type` is `hook_additional_context`,
  carrying `hookName`, `hookEvent`, and the **`toolUseID` of the denied call**.
  It is not echoed to the user.
- **`systemMessage`** surfaces as a `type: "system"`, `subtype:
  "informational"` event rendered `PreToolUse:<Tool> says: <text>`.

Teach this as the default shape for a guard hook: **a deny splits three ways
by audience, not two.** The verdict goes on `permissionDecisionReason`; the
recovery — the form the action should take instead — goes on
`additionalContext`; one curt lowercase line goes on `systemMessage`.

The recovery does not belong on the deny reason. Putting it there means the
instructional prose renders beside every block: noise for the human, and no
better targeted for the agent, which reads both channels either way.

The stamp is a version rather than a date on purpose, and the probe is worth
re-running before relying on this: the failure mode is silent — a future CC that stopped delivering
`additionalContext` on a deny would leave the guard working and only the
teaching gone, which looks like nothing. The probe needs an **unsandboxed**
nested `claude`; a sandboxed `claude -p` silently drops `SessionStart` hooks
and is not a trustworthy harness for this. Reproducing it means reading the
on-disk session transcript JSONL, not the `--output-format stream-json`
stream — the attachment never appears as its own event in that stream, only in
the transcript file.

## 3 · Which channel to reach for

Decide explicitly who the audience is. User-only → `systemMessage`. Agent-only →
`additionalContext`. Both → emit both fields in the same hook JSON. Don't assume
`systemMessage` is general-purpose.

A hook that emits only `{"systemMessage": "..."}` is **invisible to the agent**.
If the agent needs to know what the hook did, it must get an agent-facing
channel, or it redundantly verifies with `ls`/`cat`. Observed live: two of the
`handoff` plugin's hooks emitted only `systemMessage` when wiping prior handoff
files; the wipe ran correctly but the agent then ran
`ls .claude/handoff-task.md .claude/handoff.md` to check — exactly the wasted
work the hook existed to avoid.

**That redundant verification is the norm, not an anecdote, and it is worth
about two round trips per event.** Measured 2026-07-26 over ~2179 transcripts,
grouping `type:"assistant"` entries by `message.id` first: `gitlore`'s
memory-commit hook commits the memory submodule on a file trigger and reports
success only on `systemMessage`. The agent then re-checked the outcome after
**62 of 68** successful commits (91%) — `ls` the IPC files, then
`git -C memory log`/`status` — costing a mean 1.97 extra assistant messages and
a median 6.4 s (quartiles 4.7 / 6.4 / 9.6) each. The control is the same repo's
other commit path, where the outcome comes back inside a Bash tool result the
model reads: **5 of 14** (35%). Rate tracks the channel, not the prompt — the
handoff directive that mentions checking was present for 58/64 of the blind
cases and absent for 4/4, with no difference. So when a hook acts on the
agent's behalf, pair the channels and **state the outcome as authoritative**; a
blind agent does not wait quietly, it goes looking. A hook's *instructional*
branches are worse than wasteful on the wrong channel — they are dead text: the
same script's deferred-retry branch fired 144 times and the agent never
learned.

Per event: `UserPromptSubmit` → `additionalContext`. `PreToolUse` →
`additionalContext` **and** `permissionDecisionReason` on a deny (§2), plus
`systemMessage` for the human; stderr + exit 2 also surfaces. `PostToolUse` → `additionalContext`; stderr + exit 2 feeds back to the
model. `PostToolUseFailure` routes the same way, and a non-zero Bash exit fires
it instead of `PostToolUse` (`references/input-and-harness.md`).

Route user-facing notices through `systemMessage`, not stderr-on-exit-0 and **not** via the agent —
`additionalContext` saying "tell the user…" is model-dependent on the hot path.

## 4 · Routing

- **`permissionDecision`, `updatedInput`, the auto-mode classifier,
  `updatedToolOutput`, a guard that must fail closed, or emitting file bodies
  the agent must edit** → `references/output-channels.md`.
- **What arrives on stdin, which harness (`--print`, the Agent SDK) fires
  which event, or two hooks on one event sharing a file or a step** →
  `references/input-and-harness.md`.
