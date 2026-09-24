# What arrives at the script, and which harness fires it

## The stdin payload

Verified against the Claude Code bundle (zod schemas) — first on 2.1.168,
re-verified on **2.1.219, 2026-07-24**. This is the complement of what
`plugin-dev:hook-development` documents, not a copy of it: that skill covers
`session_id`/`transcript_path`/`cwd`/`permission_mode` and the classic events,
and carries none of the optional base fields, no `SessionStart` `source`
values, and none of the extended event union below.

The base hook input is composed via `.and(...)` into **every** hook event, so
SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, etc. all carry it:

```
{ session_id, transcript_path, cwd,
  prompt_id?, permission_mode?, agent_id?, agent_type?, model?, session_title? }
```

`cwd` is a required string. There is **no worktree-root field** in hook stdin;
`cwd` is the only directory context, and it is drift-prone (moves with `cd` /
`/add-dir`). `agent_id` is present only when the hook fires from within a
subagent; `agent_type` also appears on the main thread of an `--agent` session.
`prompt_id` correlates every event back to the user prompt that started the turn
(same value as the OTel `prompt.id` attribute), absent before the first prompt.

Beyond the classic events the input union covers `WorktreeCreate {name}`,
`WorktreeRemove {worktree_path}`, `CwdChanged {old_cwd,new_cwd}`,
`FileChanged {file_path,event:"change"|"add"|"unlink"}`,
`DirectoryAdded {directory,source}`, `InstructionsLoaded`, `ConfigChange`,
`PostToolBatch`, `PostToolUseFailure`, `PostCompact`, `Setup`, `SubagentStart`,
`StopFailure`, `PermissionRequest`, `PermissionDenied`, `MessageDisplay`,
`Elicitation`/`ElicitationResult`, `TaskCreated`/`TaskCompleted`.

**A Bash call that exits non-zero fires `PostToolUseFailure`, never
`PostToolUse`.** `PostToolUse` fires only on success and carries
`tool_response`; the failure event carries the result as one `error` string.
Each call fires exactly one of the two, and both accept
`hookSpecificOutput.additionalContext`. The Bash tool merges stderr into stdout
in emission order, sandboxed and unsandboxed alike: on success
`tool_response.stdout` holds both streams interleaved and `tool_response.stderr`
is `""` — the field exists in the schema and arrives empty — and on failure
`error` is the `Exit code N` line followed by that merged output. Both texts are
byte-identical to the `tool_result` content the model sees; the transcript's
`toolUseResult` string for a failure prepends `Error: `, the payload does not.
`tool_input.dangerouslyDisableSandbox` is absent when unset, not `false`; when
set it is `true`, and `PostToolUse` echoes it into `tool_response`. A sandboxed
write refused by the allowlist (a read-only filesystem error on a path directly
under `/tmp/`) carried no sandbox-violation annotation in the payload or in the
model's result; a network denial was not tested. Schemas read from the CC
2.1.280 bundle, payloads recorded live on 2.1.280, 2026-09-23. Unrecorded: what
`cwd` holds after a `cd` inside the call, and whether output the harness
truncates or persists arrives whole or as the model-visible preview.

**How to apply:** a hook that reads Bash output registers on both events and
takes `error` on a failure and `tool_response.stdout` on a success; a hook that
looks for an error message in `stderr` alone reads nothing. A command piped
through `tail` or ending in `|| true` reports exit 0 and arrives on
`PostToolUse`, so neither event alone is "the failures".

`tool_input.file_path` on `Write`/`Edit` is **not** always absolute, whatever
the tool's own contract says. `PreToolUse` sees what the model emitted, before
any harness normalization, so a path guard that assumes a leading `/` — a
`*/<segment>/*` glob, a prefix comparison — silently misses the relative form.
Measured over a local transcript corpus 2026-08-27: 131 of ~4100 values were
repo-root-relative (`plans/x.md`, `scripts/install.sh`, `START.md`). A hook
resolving one has only its own process cwd to resolve it against.

**`PostToolBatch` fires once per tool batch, not once per user turn.** A batch is
one assistant message's worth of calls, so a turn in which the agent takes three
batches fires it three times. Observed 2026-07-27: a `sed -i` in one message
fired the batch hooks with that message's calls, and the very next message
fired them again. A hook that stashes a pre-state at `PreToolUse` and consumes
it at `PostToolBatch` therefore has a *per-batch* baseline — treating it as
per-turn overstates how long a stash lives.

**Every hook matching one event runs in parallel, in no specified order.** The
docs say so outright — *"All matching hooks run in parallel"*
(`code.claude.com/docs/en/hooks.md`, fetched 2026-09-24) — and it holds across
plugins and between the entries of one `hooks.json`. Registration order is not
an ordering, and hooks get designed against one anyway (observed 2026-09-18: a
report relay that assumed it). Two shapes break. A shared file that each hook
read-merge-writes loses the loser's content silently — give each writer a file
of its own, so there is nothing to serialize. A consumer step placed in each of
two hooks emits everything twice on a batch that fires both — a consumer belongs
in one hook of its own. A suite that runs the hooks one after the other is green
across both defects and their fixes, since a fixed order cannot show a race:
start the hooks concurrently, or arrange the input so that the losing
interleaving is the only one possible.

**No hook event carries token counts**, and `PostToolBatch` is the only event
that fires *inside* a turn. Verified 2026-07-31 on 2.1.220 by nested `claude -p`
runs. There is no context percentage or window size on any payload, so context
size comes from the transcript: on the newest entry carrying `.message.usage`,
`input_tokens + cache_creation_input_tokens + cache_read_input_tokens` is the
prompt sent for that call (accurate after a compaction). Take the *last* such
entry rather than summing — one API response emits several JSONL entries sharing
a `message.id`, each repeating the same `usage`. Inside a subagent
`transcript_path` points at the **parent**; the subagent's own usage is at
`<session-dir>/subagents/agent-<agent_id>.jsonl`, so a naive read measures the
wrong context. `PostToolBatch` stdin also carries an undocumented `tool_calls[]`
(`tool_name`/`tool_input`/`tool_use_id`/`tool_response`, already resolved) —
absent from the binary's own schema doc-strings, visible only in a live payload.

**`hookSpecificOutput.additionalContext` reaches the model on the next API call
of the same turn**, and **`continue: false` halts a running turn** — the batched
calls still run and their results land in the transcript, then the turn ends with
no further API call and no final assistant text (`--debug hooks` names it
`requested preventContinuation`). `decision: "block"` halts too, by a different
internal path. Together these are the only levers a mid-turn hook has: inject,
message, or halt — see `output-channels.md` for the channels themselves.

**`CwdChanged` is observational only** — its `hookSpecificOutput` schema declares
nothing but `watchPaths`, and its dispatcher reads back only `watchPaths[]` +
`systemMessage`. It honors **no** `additionalContext`, **no** `decision`/block,
**no** `permissionDecision`. It cannot gate a `cd` or feed the agent.
`FileChanged` shares that dispatcher and the same restriction.

**`WorktreeCreate` is a path *provider*, not a decision gate.** Its dispatcher
takes the worktree path from the hook's stdout (or from
`hookSpecificOutput.worktreePath`, which its schema requires) and throws when no
hook ran, when every hook exited non-zero, or when none returned a path. A hook
refuses by failing — success is `exit status === 0`; `decision:"block"` plays no
part.

**A `SessionStart(clear)` payload describes the new session, and its transcript
already exists when the hook runs.** `transcript_path` names the post-`/clear`
session's file, on disk by hook time — so a `clear` hook can baseline a
transcript count and confirm a prompt submitted into the fresh session, exactly
as a `SessionStart(compact)` hook can. That payload carries no `model` where
`startup` does; the field is optional in the base schema, so read it
defensively (2.1.219).

**How to apply:** when a hook needs the project/worktree root, prefer
`CLAUDE_PROJECT_DIR` where the hook environment sets it; otherwise derive it
from the on-disk `.git` linkage starting at `.cwd` — don't expect a root field
in the payload. The payload's own `cwd` drifts with shell `cd` and `/add-dir`,
so don't trust it as the root.

## `--print` and the Agent SDK as a scripted harness

**Under `claude --print`, PostToolUse hooks fire and a properly-wrapped `additionalContext` injects.** Verified by direct test on CC 2.1.212: a PostToolUse hook ran under `--print` and its `additionalContext` steered the model's reply. A widespread belief holds the opposite (GitHub [anthropics/claude-code#37559](https://github.com/anthropics/claude-code/issues/37559) reads that way) — test before trusting it.

**`SessionStart`, `PreToolUse` and `PostToolBatch` fire under `--print` too** (probed
2026-07-22, one throwaway repo + `--setting-sources project`, a hook appending its
event name to a log). So a `--print` harness can exercise the *whole* hook set, not
just the one event that happened to be verified first. That mattered for
`gitlore`'s eval fixture, which hand-listed `PostToolUse` alone and left
composition, the commit gate, recall and add-tier dark in every eval ever run
— derive the eval's hook wiring from the plugin's real `hooks.json` instead.

**Because `SessionStart` fires, `claude -p` is not a read-only probe — it is a real session that runs your repo-mutating hooks.** A one-shot `-p` invocation used to *verify* state can destroy the state it was checking. Observed 2026-08-03: two `claude -p` probes confirming a `CLAUDE.md` `@` import resolved also ran `gitlore`'s own `SessionStart`, whose unconditional `git submodule update` re-pinned a memory tier to its recorded gitlink and walked HEAD back off a just-landed merge commit, reverting the merged fact files. Nothing reported it — the probe answered the question it was asked and the damage was in a different file. Before spending a `-p` run on a question about the working tree, ask what this repo's `SessionStart` does; where it writes, verify by reading the tree instead, or take the probe's answer knowing the tree may have moved under it.

**`additionalContext` requires `hookSpecificOutput` wrapping.** A hook printing top-level `{"additionalContext": "..."}` is silently dropped; the correct shape is:
```json
{ "hookSpecificOutput": { "hookEventName": "PostToolUse", "additionalContext": "your text" } }
```
This holds in both interactive CC and the Agent SDK. The silent top-level drop is the subtle failure to watch for.

**Scripted multi-turn works under `--print` via `--resume`.** Capture `session_id` from turn 1 (`claude --print --output-format json`), then `claude --print --resume <session_id>` for turn 2; conversation state carries (verified 2026-07-17).

**SDK vs `--print` for evals — a small startup-latency edge, nothing more.** Both fire hooks and both do multi-turn. The SDK's `query()` is **one-shot and stateless** by its own docstring ("each query is independent, no conversation state") — it spawns a subprocess per call and `resume` replays the session, exactly like `--print --resume`. `ClaudeSDKClient` is the SDK's stateful API; a `query()`-based eval runner does not use it. So **both harnesses re-prime the project context on every turn**; a claim that the SDK "holds one process so context primes once" is false for any `query()`-based runner.

Measured 2026-07-17 (trivial two-turn probe, warm cache, per two-turn trial): SDK $0.379 / 14.4s vs `--print --resume` $0.425 / 24.3s. The delta is ~5s startup per turn plus ~7k more context (the CLI loads user settings; the runner passes `setting_sources=["project"]`) — fixed overhead that does not scale with turn length. Cold-cache turn 1 creates ~40k either way, which is where the "~40k per `--print` spawn" figure came from — it is per *turn*, not per harness.

**Agent SDK details.** `setting_sources=["project"]` loads the repo's `.claude/settings.json` hooks; `permission_mode="bypassPermissions"` is needed for unattended runs (default blocks writes). Two-turn: turn 1 captures `ResultMessage.session_id`, turn 2 passes `resume=<session_id>` in `ClaudeAgentOptions` — NOT `session_id=` (that identifies the current session → "already in use").

**How to apply:** `--print` supports hook-driven flows (2.1.212). Both harnesses are viable; pick on dependency footprint, not on context reuse — the SDK buys ~$0.05 and ~10s per two-turn trial and costs a `uv` + Python + `claude-agent-sdk` dependency in an otherwise bash/bats suite. Realising the SDK's *persistent-process* advantage means rewriting the runner onto `ClaudeSDKClient`. This rationale survived two reviews because nobody read `query()`'s docstring — verify a claim against its own source.
