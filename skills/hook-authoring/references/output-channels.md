# Output channels: mechanics, the permission pipeline, and edits

## 1 · Channel mechanics (verified 2026-06-10; PreToolUse additions 2026-07-17)

- **`systemMessage`** (top-level field) — the user-visible channel, and the
  field for anything the human should see. Verified on `SessionStart`,
  `PostToolUse` and `PreToolUse`, the last rendering as
  `PreToolUse:<Tool> says: <text>` (see `SKILL.md` §2).
- **`hookSpecificOutput.additionalContext`** — injected into the model's context
  only; **never echoed to the user**. Silent by design. Honoured on
  **`PreToolUse` as well as `PostToolUse`** (both verified 2026-07-17 via nested
  `claude --print` + `--settings` scratch hooks): it arrives as a
  `<system-reminder>` attributed to `<event>:<Tool> hook`, and on `PreToolUse` it
  is delivered on a **deny** as well as when an allowed call then fails — a
  blocked call never runs, so it is not a call that failed. See `SKILL.md` §2, *A deny splits
  three ways by audience*, for what each of the three channels carries on a
  deny.
- **stdout** — consumed as JSON; not echoed. **Parsed ONLY on `exit 0`.**
- **stderr** — ignored on `exit 0`; on non-zero exit, shown to the user only with
  exit code **2**, or with `--verbose` for other codes (a "hook error" label
  appears). `SessionStart` is non-blocking — continues regardless of exit code.

**Reporting an ERROR needs `exit 0`, not merely tolerates it (2026-07-15).** The
naive "fail loudly ⇒ exit non-zero" is backwards: stdout JSON parses only on
`exit 0`, so a non-zero exit **discards the `systemMessage`** — the only reliably
user-visible channel — leaving stderr (exit 2 / `--verbose` / debug log). The
honest error path is **`systemMessage` + `exit 0`**. `|| true` and a bare
`|| exit 0` on a fallible command are dishonest error paths — check status
explicitly, report on `systemMessage`, exit 0.

**Blocking asymmetry** (don't conflate "don't exit 2" with "don't error"):

| event | can it block? |
|---|---|
| `PreToolUse` | **`exit 2` blocks the tool outright.** Other non-zero → action proceeds + "hook error" notice. |
| `PostToolUse` | **Nothing can block** — docs: *"PostToolUse hooks can't undo actions since the tool has already executed."* `exit 2` is mere feedback to the model; the exit code buys nothing. |

So "exit 0 on every path so we never block a Write" is over-broad reasoning that
lands on the right answer: `exit 0` is right for *visibility*, not for
non-blocking.

**Unresolved tension — re-verify before relying on it.** The 2026-06-10 finding
says stderr reaches the user only on exit 2 / `--verbose`. The docs (fetched
2026-07-15, `code.claude.com/docs/en/hooks-guide.md`) instead describe *any*
non-zero as showing a `<hook name> hook error` notice + the first stderr line in
the transcript, with full stderr to the debug log. Possibly a CC behavior change,
or "transcript" meaning the transcript view rather than the inline UI. The
conclusion holds under both readings — `systemMessage` + `exit 0` — but the
stderr claim itself is stale-suspect.

## 2 · `PreToolUse` decisions and the permission pipeline

**`permissionDecision` (verified CC 2.1.246).** `deny` on stdout + `exit 0`
blocks the call like `exit 2` does, and additionally carries `systemMessage`;
either way it blocks *the one call, not the turn* — the agent gets the reason
and continues. `ask` forces a human prompt in every permission mode, auto
included: a hook cannot hand a decision to the auto-mode classifier, so an
`ask` that prompts too often is fixed by narrowing the hook's trigger, never by
expecting the classifier to absorb it. `allow` skips the prompt but not
`permissions.deny`/`ask` rules. `defer` exists but is print-mode-only and
solo-tool-only.

**`updatedInput` alone defers; `permissionDecision` settles (bundle read of CC
2.1.233, checked against 2.1.246–247).** `PreToolUse` hooks run before any
permission evaluation. `updatedInput` *with no decision* → the caller replaces
the working input and runs the **full** pipeline over the rewritten command:
deny and ask rules, the read-only auto-allow, then the auto-mode classifier.
`updatedInput` is schema-validated against the tool's `inputSchema`, and a
validation failure converts to a deny. `updatedInput` **with**
`permissionDecision: "allow"` → the caller treats the call as settled by the
hook; the only re-check is a narrow one for a matching deny rule, a matching ask
rule, or two fixed ask reasons, a `passthrough` from rule matching yields
`null`, and the classifier is never consulted. The two are separable and the
difference is the whole gate: **`allow` + `updatedInput` is a permission bypass,
not a rewrite.** A hook that inspects a *prefix* and rewrites — the shape of
every `cd`-restore or unsandbox helper — pre-approves an **arbitrary tail** it
never looked at. Emit `updatedInput` on its own and let the pipeline decide;
there is no turn cost, since the rewrite still saves the block-and-reissue turn
and a read-only tail is auto-allowed locally anyway.

Not probe-observable from inside a session: deny and ask rules are re-checked
under `allow` too, so neither discriminates, classifier verdicts are not
persisted, and a Bash `toolUseResult` carries no permission decision — the
bypass leaves no trace in the transcript. The durable check is a unit assertion
that the key is **absent**; an assertion written against the working output
will instead *require* the bypass. Two plugins shipped this:
`unsandbox-git-status` (retired 2026-08-26, confirmed live with
`true && git status --porcelain` running unchecked) and `cwd-safety` (its `cd`-restore
rewrite, fixed 2026-08-28). One matching `excludedCommands` segment
unsandboxes the whole call, statically, and does not auto-approve it.

**The classifier scores safety, not convention** — it passes an unprompted
`Edit` of a pre-existing file in a sibling repo even against a CLAUDE.md rule
or a custom `autoMode.soft_deny` — so a convention-level gate on `Write`/`Edit`
needs a hook; only Bash-path writes are covered by the sandbox's write
allowlist. Evidence: the `prohibitions` plugin's design notes record an
unprompted off-project note drop passing without asking.

**Obliging the agent to reach a checkpoint at all** is a separate mechanism
from injecting text: a `PreToolUse` deny on the first durable write of an
episode is self-scoping (no edit, no gate), where a `Stop` block would fire on
every turn including conversational ones.

## 3 · Rewriting a result: `updatedToolOutput`

**`updatedToolOutput` is validated against the tool's own output shape**, and a
mismatch is rejected with `PostToolUse hook returned updatedToolOutput that does
not match <tool>'s output shape` (string present in 2.1.232). So rewriting what
a tool reported is not a free-text channel: a hook that corrects, say, an `Edit`
result has to reproduce that tool's result object, not substitute prose for it.
Budget for establishing the shape before designing around this channel;
`additionalContext` carries a correction with no shape contract at all, at the
cost of leaving the original result in context beside it.

**For `Edit` that channel corrects nothing the model reads.** The result object
is `{filePath, oldString, newString, originalFile, structuredPatch,
userModified, replaceAll}`, but what reaches the model is a fixed string — `The
file <path> has been updated successfully. (file state is current in your
context — no need to Read it back)` — carrying no diff (uniform across 12,407
`Edit` results in the local transcript corpus; CC 2.1.232). So the agent's model
of an edited file comes from the edit it asked for, never from the tool's
report, and rewriting that report cannot move it. A hook that repairs the file
on disk restores agreement on its own; `additionalContext` is the only channel
that can say the bytes changed after the tool answered.

## 4 · Emitting file bodies the agent must edit

**Two limits make emitted bytes the wrong choice when the agent must *edit*
what it is shown.** A large `additionalContext` is not delivered whole: at
15.6KB the harness wrote it to a `tool-results/…-additionalContext.txt` file
and inlined only a ~2KB preview, so a hook emitting several file bodies
silently delivers a fraction of them unless the agent notices the pointer and
reads that file. And injected text does not register in the file-read ledger —
the ledger is keyed off actual `Read` calls — so `Edit` on a file whose bytes
arrived by `additionalContext` still fails until the agent Reads it, paying for
the content twice. There is no supported way to prime the ledger. Where the
recalled file is going to be edited, emit a directive naming the exact `Read`
calls instead of the bytes: two round trips, but no truncation and the file
lands editable.
