# Rejected alternatives — the arguments

Part of `docs/design.md`: one entry per rejected alternative, carrying the argument behind the hub's one-line conclusion. Read the entry before re-proposing an alternative or changing what it argues; the hub's line and the entry here change in the same commit.

**Widening `toolkit-release` to cover setup.** D-5 scopes it to failure modes, and the moment differs: setup is a route taken in order, a release failure is a symptom met mid-run.

**Keeping the route in the `claude-plugin-dev` memory fact.** Recall fires on a token, and the session that motivated `plugin-creation` held none that matched it.

**Prose only for the `claude --version` trap (D-11).** The rule was already written down and did not stop the incident; the trigger is a literal command, which suits a hook better than a skill.

**A `PermissionDenied` hook for the classifier's no-verdict (FR-5).** It fires on the denial, but its `additionalContext` never reaches the model, and its `reason` reads `Classifier unavailable` rather than the text the model sees (probed on CC 2.1.311, `plans/classifier-no-verdict/probes.md`). **Reopen-if** Claude Code delivers context from that event.

**Reading the version from `CLAUDE_CODE_EXECPATH`.** Undocumented, unverified inside a hook's environment, and dependent on the versioned install layout, so a different install fails silently. The transcript field is documented.

**Naming it `craft:plugin-dev`.** `plugin-dev/` is the vendored toolkit directory and `plugin-dev:` is an existing skill namespace. A third meaning for the same word makes every reference ambiguous.

**Shipping this content from the `claude-plugin-dev` repository.** That repo is subtree-vendored infrastructure, not a marketplace plugin. Skills are discovered from `skills/` at a plugin root, not from a consumer's `plugin-dev/`, so a skill placed there would never load.

**Folding it into `craft`.** Different moment and different audience. Someone writing a design document is not building a hook, and the two sets would compete for attention in one description list.

**Leaving the content in memory and splitting each body under the recall cap.** Viable for a fact keyed on a symptom string. It is wrong here because these triggers are task-shaped: no split makes an index line fire on "I am writing a hook".

**A skill on `git subtree` grafting the wrong tree.** Offered from `claude-plugin-dev` (2026-09-07): `git subtree add|pull --prefix` grafts a ref's *root* tree and cannot filter, so a repository shipping from a subdirectory is unvendorable from its own release tag, and a consumer who pins one receives the whole working environment — most visibly a `memory` gitlink that makes a bare `git submodule status` fail repo-wide, and a `CLAUDE.md` and `.claude/settings.json` that silently reconfigure the agent reading them. The remedy is a second `dist-` tag cut from `git subtree split --prefix`. Declined because the vendored `plugin-dev/README.md` carries both the mechanism and that symptom and ships to every consumer of the toolkit, while `install.sh` and the update recipe already refuse a source ref by name and print the `dist-` one instead. D-5 scopes `toolkit-release` to what that README lacks, so a section here would be duplication of a file the reader already has. The residual audience is someone who installs plugin-craft and uses `git subtree` without vendoring this toolkit, which is another description's cost against N-1's test.

**`exit 2` plus stderr as the deny mechanism.** It blocks, but carries no `ask` capability and no `systemMessage`, so a human-facing line distinct from the agent-facing reason is unavailable. Uniform stdout JSON with exit 0 keeps every script the same shape regardless of decision.

**Treating the tier's existing `additionalContext` sentence as covering a deny.** It claimed only the weaker thing — delivery when an allowed call then fails — and a blocked call never runs, so it is not a call that failed. A hook written on that assumption works with its teaching silently dropped.

**Letting review alone enforce D-6.** Rejected for the reason stated in D-6; retained here because "a careful reviewer will catch it" is the alternative that keeps suggesting itself.
