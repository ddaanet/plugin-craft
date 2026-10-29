## Brief: auto-mode classifier "no verdict" on Write in a `--plugin-dir` dogfood checkout

2026-10-03, from a sandbox-lies session.

### Decisions

- **plugin-craft owns this.** It is a hazard of dogfooding a plugin with
  `claude --plugin-dir <checkout>`, which plugin-craft already covers
  (`verifying-plugin-changes`). My human partner chose plugin-craft over
  sandbox-lies.
- **The guidance should arrive with the symptom.** A hook, or a skill whose
  description names the error string, is better than a memory fact: it gives
  the guidance when the error appears and costs nothing in other sessions. Which
  of the two is plugin-craft's call.
- **Stopgap until then:** the ddaanet memory fact
  `ddaanet/classifier-no-verdict-plugin-dir`. Retire it in the change that
  ships plugin-craft's version.

### Constraints

- **Scope.** Limit it to the no-verdict case. A refusal that names a reason is
  a denial, and no route around it is sanctioned.

### Rejected approaches

- **A sandbox-lies detector.** sandbox-lies covers the command sandbox, and
  its hooks read Bash results only (its D-1). This error comes from the
  auto-mode classifier on a Write call, which is a different layer and tool.
- **Memory only.** It needs a recall step and costs index bytes in every
  ddaanet repo.

### Additional context

The exact tool result returned on Write:

> The server-side auto mode classifier gave no verdict (it skipped this
> action), so auto mode cannot determine the safety of Write. This is a hard
> failure, not a transient one: the check cannot or does not judge this
> request, so retrying this action will get the same answer. Don't retry it.

**Observed on 2026-09-28** in `/Users/david/code/sandbox-lies`, in a session
started through its `.bin/claude` shim, which execs the real `claude` with
`--plugin-dir <checkout>`. A delegate's transcript recorded CC 2.1.283.

- Four Writes of new files under `plans/sandbox-lies/reports/` failed with the
  message above: one from the main session and one from each of three
  unnamed `general-purpose` delegates.
- A Write to `$TMPDIR` succeeded.
- **Cause as stated by my human partner:** "the block comes from
  `--plugin-dir .` marking every file as sensitive". This is not probed.

**Counter-evidence, 2026-10-03, same session:** two Writes inside the same
checkout succeeded, `.claude/gitlore-memory-message` and
`.claude/gitlore-commit-memory`. So either the gate is path-dependent (`plans/`
versus `.claude/`), or the "hard failure" was a server-side state that changed
over the five days between them.

**Open questions to settle before shipping anything:**

1. **Cause.** Repeat a Write of a new file under `plans/` in a shim session and
   in a plain session on the same CC version.
2. **Tools affected.** Whether Edit and NotebookEdit fail the same way.
3. **Hook event.** Which event, if any, carries the result to a hook:
   `PostToolUseFailure` on Write, or a permission-denial path. Record the live
   payload first.
4. **Delegates.** They hit it too. Any guidance has to reach a dispatch prompt
   that asks a subagent to write a file, not only the main session.
