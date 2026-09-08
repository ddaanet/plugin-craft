# plugin-craft — design

Status: seeded, unreleased.
Verified against: `ad180d6` (2026-09-03).

## Now

**Focus** — nothing in flight. The four skills are written, reviewed and committed; the sources they were cut from are retired from the shared `ddaanet` memory tier.

**Next** — add the `plugin-craft` row to `ddaanet/claude-plugins`' `marketplace.json` and cut the first release. `just check-version` reports the entry missing until then, which is the expected pre-release state; the release recipe creates the row itself.

**Do not re-litigate** — the plugin boundary (D-1), the §7 split point (D-2), the failure-mode scoping of `toolkit-release` (D-5), and the presence of `my human partner` phrasing in shipped skill text (D-9).

## Status legend

`Done` = implemented and pinned by a check. `Done (prose)` = instructions, not code, not tested. `Partial`. `Planned`.

## Functional requirements

**FR-1 · One plugin, four skills, each firing on a moment.** Every description names a moment a session is already in rather than a topic word. *Done (prose)* — the `description:` of each `skills/*/SKILL.md`.

**FR-2 · `hook-authoring` carries the whole hook surface.** The stdin payload, the stdout control surface, the channel mechanics, the `PreToolUse` permission pipeline and the scripted-harness comparison. *Done (prose)* — `skills/hook-authoring/`.

**FR-3 · A deny is taught as splitting three ways by audience.** Verdict on `permissionDecisionReason`, recovery on `additionalContext`, one line on `systemMessage`. *Done (prose)* — `skills/hook-authoring/SKILL.md` §2.

**FR-4 · `skill-authoring` carries what makes a skill findable and self-sufficient.** Description shape and its per-session cost, what `allowed-tools` grants, which second-person forms the imperative rule targets, and how a bundled script is reached when the plugin env vars are absent. *Done (prose)* — `skills/skill-authoring/SKILL.md`.

**FR-5 · `verifying-plugin-changes` fires on a symptom with no keyword.** An edit to plugin code that appears not to work while nothing errors. *Done (prose)* — the `description:` of `skills/verifying-plugin-changes/SKILL.md`; see L-1.

**FR-6 · `toolkit-release` carries only what goes wrong.** The procedure stays in the vendored `plugin-dev/README.md`, which every consumer of the toolkit already has. *Done (prose)* — `skills/toolkit-release/SKILL.md`.

**FR-7 · No shipped skill text cites the memory store.** No wikilink, no `memory/` path, no bare fact filename. *Done* — `scripts/check-skill-text.sh`, pinned by `just precommit`.

**FR-8 · Every date and build version that grounds a claim survives the move.** Stripping one turns evidence into assertion, and these are the claims most likely to rot. *Done (prose)* — all six skill files.

**FR-9 · Migrated facts are retired from the tier, and inbound pointers are repointed.** Every pointer into a retired fact, from a fact that stays, names the skill that now carries the content. *Done (prose)* — `memory/MEMORY.md` and the `ddaanet` tier.

## Non-functional requirements

**NFR-1 · A description is a recurring cost.** It is injected at session start in every repo where the plugin is enabled, not merely displayed, so its length is paid per session and is written to earn it. *Done (prose)* — the frontmatter of each `skills/*/SKILL.md`.

**NFR-2 · Skill bodies are reachable in full at invocation.** This is the property recall could not provide and the whole reason the content left memory. *Done (prose)* — `skills/`.

**NFR-3 · Release infrastructure is vendored, never hand-written.** Pinned to a `dist-` tag from `claude-plugin-dev` and never hand-edited. *Done* — `plugin-dev/`, pinned by `plugin-dev/version-guard.sh`.

**NFR-4 · FR-7 is enforced mechanically rather than by review.** The failure is silent for the consumer and invisible to the author, so a reviewer catching it is not a control. *Done* — `scripts/check-skill-text.sh`, pinned by `just precommit`.

## Architecture

A Claude Code plugin with no commands, no agents and no hooks of its own. Four skills under `skills/`, discovered from the plugin root; `hook-authoring` additionally carries `references/output-channels.md` and `references/input-and-harness.md`, which its `SKILL.md` routes to by what a reader arrives holding.

`plugin-dev/` is the `claude-plugin-dev` toolkit, vendored by `git subtree` at a `dist-vX.Y.Z` tag. It supplies `just release`, `resume-release`, `check-version` and `update-plugin-dev` through `release.just`, and a `PreToolUse(Write|Edit)` version-guard hook wired into `.claude/settings.json`. The directory is generated content: changes go to the toolkit repo and arrive here through `just update-plugin-dev`.

`memory/` is a gitlore submodule with the shared `ddaanet` tier mounted at `memory/ddaanet/`. That tier is this plugin's source material and is shared with other repositories, so it is read for content and edited only to retire what has migrated.

`justfile` imports the toolkit's recipes and defines the two the toolkit requires. `precommit` validates the plugin manifest, syntax-checks `scripts/`, and runs `check-skill-text.sh`. `prerelease` depends on `precommit` and adds nothing yet.

`scripts/check-skill-text.sh` walks `skills/**/*.md` NUL-delimited and fails on three patterns: a `[[wikilink]]`, a `memory/` path, and a bare `.md` filename matching a known source fact. It prints `file:line:text` for each hit and exits non-zero.

## Design decisions

**D-1 · Four skills, one plugin.** Context cost is per-skill, since every enabled skill's `description:` is injected at session start and counted under `/context`'s *Skills*. Packaging is therefore neutral on cost, and the plugin boundary is an enablement decision instead. These four share one moment — building or debugging on the Claude Code harness.

**D-2 · `hook-output-channels` splits at §7.** Sections 1–6 are hook mechanism and belong with the skill; §7 is prose craft, and the source file scopes its own rule to "DENY channels, not DIRECTIVE channels", which is a wording rule rather than a mechanism. §7 stays in the tier for the sibling `craft` extraction. **Reopen-if** `craft` declines the section.

**D-3 · Each description names the moment, not the topic.** "Authoring or debugging a hook", "verifying plugin code you just edited" — not "hooks" and "plugins". The hardest case is the reason the plugin exists: the stale-plugin-code symptom has no token a tool result will ever print, so an index line could never match it. Naming the topic again would reproduce that failure in a new format.

**D-4 · The hook and skill authoring skills complement `plugin-dev`, they do not replace it.** `plugin-dev:hook-development` covers configuration and event basics; `plugin-dev:skill-development` covers structure and progressive disclosure. Both ship in a marketplace plugin, so the gaps cannot be closed at their source. Each description states the delta rather than a bare "complements X", because a bare claim gives the model nothing to route on.

**D-5 · `toolkit-release` is scoped to failure modes.** `plugin-dev/README.md` ships with the vendored files to every consumer and already owns installing, updating, the two-tag scheme, the required recipes and the release conventions. What it does not carry is what goes wrong while running them — the sandbox death at the marketplace bump, what the permission classifier weighs when the push is nested in a recipe, what `error: uncommitted changes` actually excludes, the absence of any supported way for a first release to choose its version, the `just --list` check owed after a subtree pull, and reading the changelog from the source checkout. The skill covers that and points at the README for the rest. **Reopen-if** the README absorbs the failure modes.

**D-6 · Distributed skill text never cites the memory store, and a script enforces it.** Consumers do not have the store, so a wikilink or a `memory/` path dangles for every one of them. The criteria are inlined at write time. Review alone is insufficient because the failure is silent — the skill reads as complete with a dead pointer in it — so `check-skill-text.sh` runs from `precommit`.

**D-7 · `hook-authoring` is a hub plus two reference files.** Its merged source is roughly 25 KB, past the point where one file reads as a routing document. `SKILL.md` holds what a reader needs before knowing which question they have: the control surface, the three-way deny split, and how to choose a channel. The reference files hold the mechanism. The other three skills are single files and do not need the hop.

**D-8 · Migrated facts are retired from the tier; two are reduced rather than removed.** Leaving them costs index bytes against a capped loader for content now shipped in full. `hook-output-channels` keeps §7, which was not migrated here. `claude-plugin-dev` keeps the `edify`-does-not-vendor exception, which is in neither the vendored README nor the skill. Every inbound pointer from a fact that stays was repointed at the skill carrying the content.

**D-9 · `my human partner` phrasing ships as-is in skill bodies.** It reads as house voice rather than as a defect, on the `superpowers` precedent. A line carrying it is rewritten only where it is separately an imperative-form violation, and then for that reason.

## Rejected alternatives

**Naming it `craft:plugin-dev`.** `plugin-dev/` is the vendored toolkit directory and `plugin-dev:` is an existing skill namespace. A third meaning for the same word makes every reference ambiguous.

**Shipping this content from the `claude-plugin-dev` repository.** That repo is subtree-vendored infrastructure, not a marketplace plugin. Skills are discovered from `skills/` at a plugin root, not from a consumer's `plugin-dev/`, so a skill placed there would never load.

**Folding it into `craft`.** Different moment and different audience. Someone writing a design document is not building a hook, and the two sets would compete for attention in one description list.

**Leaving the content in memory and splitting each body under the recall cap.** Viable for a fact keyed on a symptom string. It is wrong here because these triggers are task-shaped: no split makes an index line fire on "I am writing a hook".

**A skill on `git subtree` grafting the wrong tree.** Offered from `claude-plugin-dev` (2026-09-07): `git subtree add|pull --prefix` grafts a ref's *root* tree and cannot filter, so a repository shipping from a subdirectory is unvendorable from its own release tag, and a consumer who pins one receives the whole working environment — most visibly a `memory` gitlink that makes a bare `git submodule status` fail repo-wide, and a `CLAUDE.md` and `.claude/settings.json` that silently reconfigure the agent reading them. The remedy is a second `dist-` tag cut from `git subtree split --prefix`. Declined because the vendored `plugin-dev/README.md` carries both the mechanism and that symptom and ships to every consumer of the toolkit, while `install.sh` and the update recipe already refuse a source ref by name and print the `dist-` one instead. D-5 scopes `toolkit-release` to what that README lacks, so a section here would be duplication of a file the reader already has. The residual audience is someone who installs plugin-craft and uses `git subtree` without vendoring this toolkit, which is a fifth description's cost against N-1's test.

**`exit 2` plus stderr as the deny mechanism.** It blocks, but carries no `ask` capability and no `systemMessage`, so a human-facing line distinct from the agent-facing reason is unavailable. Uniform stdout JSON with exit 0 keeps every script the same shape regardless of decision.

**Treating the tier's existing `additionalContext` sentence as covering a deny.** It claimed only the weaker thing — delivery when an allowed call then fails — and a blocked call never runs, so it is not a call that failed. A hook written on that assumption works with its teaching silently dropped.

**Letting review alone enforce D-6.** Rejected for the reason stated in D-6; retained here because "a careful reviewer will catch it" is the alternative that keeps suggesting itself.

## Limitations

**L-1 · Nothing guarantees a symptom-shaped description fires.** FR-5's trigger is an observation with no keyword, so the description has to supply the vocabulary a session will be holding. Whether it matches is a property of the model at match time and is not testable from inside the repository.

**L-2 · The FR-7 check cannot see every dangling identifier.** It matches wikilinks, `memory/` paths and known fact filenames. Internal requirement or decision ids (`FR5a`, `(D14)`) and paths into another repository pass it and need a reader.

## Non-goals

**N-1 · No agent-authoring skill.** Two tier facts share the moment "writing an agent definition" and both sit under the recall cap, so memory still reaches them. If a fifth description earns its cost, they are its content.

**N-2 · No wording guidance.** The user-facing curtness style and the no-actionable-phrases deny rule are `craft`'s, per D-2.

**N-3 · No eval suite.** The skills are prose; `check-skill-text.sh` covers the one property that is mechanically checkable. Whether a description triggers is L-1.

## Changelog

Design-significant changes are in `docs/changelog.md`. Git history is the full record and is not duplicated there.
