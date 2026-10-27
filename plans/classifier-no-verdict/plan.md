# Plan: guidance for the auto-mode classifier "no verdict" on Write

2026-10-26. Input: `plans/classifier-no-verdict/brief.md`. Claims checked
against the CC 2.1.310 binary (`~/.local/share/claude/versions/2.1.310`, read
with `mmap` and `find`; nothing was executed against real files) and against
the repo. Steps are contracts, not code. The form is O1, a skill section
(T2) - see "Decisions pending".

## Goal

When a session, main or delegate, meets
`auto mode classifier gave no verdict ... hard failure` on a file write, the
route to a written file reaches it at that moment, scoped to that error only,
and the ddaanet memory fact `classifier-no-verdict-plugin-dir` is retired in
the same change (brief; D-8 of the design).

## The brief's claims, checked

| # | Claim | Result | Source |
| - | ----- | ------ | ------ |
| 1 | The error string is as quoted | **Verified, with a correction.** The bundle composes it from a template: `<tool-label> gave no verdict<reason> ... <tool>. This is a hard failure, not a transient one: ... retrying this action will get the same answer. Don't retry it.` The quoted text is the `server_call_skipped` reason. | `find` on the 2.1.310 binary for `gave no verdict`, `it skipped this action` |
| 2 | "No verdict" is one condition | **Refuted.** Three families. Hard: `server_no_result`, `server_unrecognized_result`, `server_call_skipped`, `server_unsupported`, `server_unavailable_disabled`, `server_unavailable_error`, `..._refused`, `..._input_too_long`. Transient ("may try again once, as-is"): `server_stream_ended`, `server_thread_unsupported`, timeouts, `..._error`, `..._other`. One-retry: `server_not_requested`, `server_results_not_held`, `server_context_stale`, `..._truncated`, and `server_call_skipped` when the classifier "expected this call not to need a review". So "don't retry" holds only for the hard text, and the parenthetical names the reason. | same binary, the message builder around `Eie(...)` |
| 3 | Cause: `--plugin-dir .` marks every file sensitive | **Settled by my human partner (D5).** The Edit/Write path check `checkPathSafetyForAutoEdit` returns `ask` for every path under an inline plugin root, before acceptEdits and allow rules (read in the 2.1.283 bundle; still present in 2.1.310). That this is what the server reports as `server_call_skipped` is inferred, not traced. | memory `ddaanet/cc-plugin-dir-edits-sensitive`; `grep` on the 2.1.310 binary |
| 4 | A hook can observe the result | **Verified in the bundle, delivery unverified live.** A deny with `decisionReason.type === "classifier"` and `classifier === "auto-mode"` runs `PermissionDenied` hooks. Payload: `tool_name`, `tool_input`, `tool_use_id`, `reason` (+ common fields, `agent_id` in a delegate). Matcher is `tool_name`. The call site passes `reason ?? "Permission denied"` and does **not** gate on the no-verdict flag. | `executePermissionDeniedHooks` (`_ko`) and its caller in the tool-result path |
| 5 | `PostToolUseFailure` is the carrier | **Refuted as the likely path.** A permission deny is returned as a tool-result error built in the permission path; the failure hook is the execution-error path. Not probed live. | bundle: the deny branch calls `_ko`, not the failure executor |
| 6 | A hook can answer "may retry" | **Irrelevant.** `retry: true` is honoured only when `noVerdict` is false; the retry note is skipped for no-verdict. | same caller: `Zs && !decisionReason.noVerdict` |
| 7 | `PermissionDenied` output can carry `additionalContext` | **Unverifiable here.** The hook's declared output is `{retry}`; whether `additionalContext` is surfaced to the model was not found in the bundle read. Needs a live probe (P1). | bundle hook table text |
| 8 | Edit and NotebookEdit fail the same way | **Unverifiable.** The message takes the tool name as a parameter and the reasons are server-side and tool-agnostic, so the same family is expected. Not reproducible without a denial. | bundle (`${e}` is the tool label) |
| 9 | Delegates hit it; guidance must reach them | **Plausible, mechanism differs by form.** A session-level hook fires inside subagents (`agent_id` is in the common payload, `input-and-harness.md`). A skill does not reach a delegate unless the dispatcher carries the route into the prompt. | repo: `skills/hook-authoring/references/input-and-harness.md` |
| 10 | A `python3` script via Bash is itself classified | **Verified by construction.** Bash goes through the same pipeline; the route is not a bypass. Whether it *succeeds* in a failing session is the brief's single observation. | `output-channels.md` pipeline section |
| 11 | A heredoc is refused here | **Untested by the brief; unverifiable here.** Needs a live denial. | - |
| 12 | The plugin has no hook today | **Verified.** No `hooks/` dir; `docs/design.md` Architecture says "no commands, no agents and no hooks of its own". A hook is a first and changes that sentence and FR-1. | `ls`; `docs/design.md` |
| 13 | Memory fact exists | **Verified**, indexed in both `memory/MEMORY.md` and `memory/ddaanet/MEMORY.md`. It is in the shared ddaanet submodule, so retiring it is a write to another repo's tier (see D6). | `grep` |

Not run: any reproduction of a classifier denial, and any `claude -p` probe
that needs the sandbox off. All "needs a live denial" items are in "Probes".

## What the evidence changes about the brief

- The guidance states the cause (D5): `--plugin-dir` marks the loaded
  directory's content sensitive. It also states the *symptom* (hard-failure
  text on a file write), the *scope* (the parenthetical names the reason;
  transient and one-retry texts say to retry, so they are out of scope) and a
  *route*.
- The brief's counter-evidence (two Writes under `.claude/` succeeding) does
  not reopen the cause; P3 still checks path dependence.
- `retry` and `PostToolUseFailure` drop out; `PermissionDenied` is the only
  hook event that observes this.

## Options

**O1 - Section in `verifying-plugin-changes`.** Description gains the error
string; body gains a short section: scope, no-cause claim, the route, the
delegate line. Cost: the description is injected every session in every repo
(NFR-1) and that one is already long; fires on the string only if the model
matches it (L-1). Reaches delegates only through the dispatcher.

**O2 - New fifth skill.** Own description naming the string. Cleanest trigger,
but D-1 and N-1 set the bar for a fifth description, and the content is about
two paragraphs. Highest recurring cost per byte of content.

**O3 - `PermissionDenied` hook, matcher `Write|Edit|NotebookEdit`.** A script
reads `reason`, matches the hard-failure text and emits the route as
`additionalContext`. Fires only on the symptom, costs nothing otherwise, and
reaches delegates directly. Needs P1 (is `additionalContext` delivered), is the
plugin's first hook (design sentence and FR-1 change), pins to a message that
the bundle builds from per-reason templates that can be reworded between
versions, and `hooks.json` registration is frozen at
session start so a new hook needs a new session (`verifying-plugin-changes`).
Must match on `reason` being exactly the hard family, or it will tell a session
to switch routes on a transient failure.

**O4 - O3 hook emits a one-line pointer; O1 section carries the body.** Hook
stays tiny and version-tolerant (any `auto mode classifier` + `no verdict`),
the skill carries the nuance. Two artifacts to keep in step.

**Rejected by the brief, not reopened:** a sandbox-lies detector (wrong layer);
memory only. The stopgap fact is retired only once O1 or O3 lands (T4, D6).

Recommended default: **O1 now, O3/O4 only if P1 shows `additionalContext` is
delivered.** O1 is certain, reversible and ships in one commit; the hook's
advantage (delegates, symptom-timed) is real but rests on an unverified
channel and a version-pinned string. The default is a recommendation, not a
decision.

## Tasks

Common to all options (contract: prose edits, `just precommit` green,
`check-skill-text.sh` clean, 80-column wrap, no memory citations in shipped
text).

**T1 - Probes (human-run, before any option is built).**
Post: results recorded in a `plans/classifier-no-verdict/probes.md` with CC
version and the exact payload.
P1: register a `PermissionDenied` hook logging stdin and returning
`additionalContext`; trigger any auto-mode classifier denial (not necessarily
no-verdict); record whether the model sees the context. P2: record the
payload `reason` of a real no-verdict Write. P3: repeat a Write under `plans/`
in a shim session and a plain session (brief Q1). P4: Edit and NotebookEdit
(Q2). P5: heredoc via Bash in a failing session. All need a live denial, so
none runs inside an agent session without my human partner's go-ahead.

**T2 (O1) - Skill section.** Pre: decision D1 = skill. Post: description of
`verifying-plugin-changes` names the string within its existing size budget;
a section states scope (hard-failure family only; a refusal naming a reason is
a denial, no route), the cause (`--plugin-dir` marks the loaded directory's
content sensitive; loading from a synced copy avoids it), the Bash `python3` route as
reviewed not bypass, and a one-sentence line telling a dispatcher to carry
the route to a delegate that writes files. Invariant: heredoc not named as a
route unless P5 passes.
Update FR-5 in `docs/design.md` and add a changelog line.

**T3 (O3/O4) - Hook.** Pre: P1 passed, D1 = hook or both. Post:
`hooks/hooks.json` registers `PermissionDenied`; a script under `scripts/`
(NUL-safe, `jq` for input) emits `additionalContext` only when `reason`
matches the hard family and `tool_name` is a file-write tool; exits 0
silently otherwise. Bats test feeds a fixture payload for: hard text (emits),
transient text (silent), a reason-bearing denial (silent). Update the design
Architecture sentence, FR-1/FR-2 as needed, and the changelog. Wording follows
`craft:directive-writing`.

**T4 - Retire the stopgap.** Pre: T2 or T3 merged. Post: the memory fact and
both index lines removed and inbound pointers repointed at the skill (D-8
pattern). This writes into the shared ddaanet tier; see D6.

## Decisions pending

1. **Form.** Decided 2026-10-26: O1 now (T2). O3/O4 are revisited only if
   P1 shows `additionalContext` is delivered. P1 ran 2026-10-27: it is not
   (`probes.md`), so O3/O4 are closed and T3 is dropped.
2. **Run the probes?** P1-P5 need a real classifier denial. Default: my human
   partner runs P1 and P3 in a shim session; the rest wait.
3. **Hook gating.** If a hook: match the hard text only, or any no-verdict?
   Default hard only; a transient failure should say retry, not reroute.
4. **Name the heredoc?** Default: omit until P5, per the brief's ruling and
   that it was never tested.
5. **State the cause?** Decided 2026-10-26: yes. `--plugin-dir` marks the
   directory's content sensitive.
6. **Retiring the memory fact.** It lives in the shared ddaanet submodule, so
   the edit is outside this repo's own tree. Default: do it as a separate step
   my human partner confirms, after the shipping release exists.
7. **Description budget.** Adding the string to an already long
   `verifying-plugin-changes` description: accept, or trim another clause?
   Decided 2026-10-26: trim only if a clause is genuinely removable. The one
   documented cap is 1,536 characters for `description` plus `when_to_use`,
   truncated in the listing (code.claude.com/docs/en/skills.md); no
   listing-wide budget is documented. The description is 493 characters with
   no `when_to_use`, so adding the ~90-character string fits without a trim.
