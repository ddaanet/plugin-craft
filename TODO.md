## Open decisions

- Release plugin-craft 0.1.5. Held by my human partner (2026-10-26); waits for them to name it. Range `v0.1.4..main` has had per-commit review only, no release review against the tag: the `plugin-creation` skill and its S7 fixes, the `claude --version` hook, the classifier no-verdict section in `verifying-plugin-changes`, and the containment reference `hook-authoring/references/plugin-agent-containment.md`, whose two ddaanet memory facts are already retired so no installed plugin-craft carries their replacement until this ships.
- Whether `hook-authoring` should carry the P1 finding: a `PermissionDenied` hook fires on an auto-mode denial, but its `additionalContext` is dropped and its `reason` reads `Classifier unavailable`, not the model-visible text (CC 2.1.311, `plans/classifier-no-verdict/probes.md`). Default: yes, one line in its output-channels node.

## Remaining

- `plans/classifier-no-verdict/plan.md` T4: after 0.1.5 ships, retire `memory/ddaanet/classifier-no-verdict-plugin-dir.md` and both index lines, repointing inbound references at `verifying-plugin-changes`; it is a write to the shared ddaanet tier, confirmed by my human partner first.
- `plans/classifier-no-verdict/plan.md` probes P3 (plugin-dir vs plain session), P4 (Edit, NotebookEdit) and P5 (heredoc) not run; none blocks anything shipped.
- Delete or commit the untracked `plans/classifier-no-verdict/t2-report.md` and `t2-review.md`; the three merged worktrees under `.claude/worktrees/` are still in place.