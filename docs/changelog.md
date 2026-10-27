# plugin-craft — changelog

Design-significant changes only: decisions reversed, subsystems built or torn down, requirements added or dropped, a rationale that turned out false. Git history is the full record.

## 2026-10-26 — `verifying-plugin-changes` names the classifier's no-verdict failure

A file write under a `--plugin-dir` checkout can end in `auto mode classifier gave no verdict ... hard failure`, and the retry fails the same way. The brief offered a hook or a skill description; the plan found `PermissionDenied` to be the only hook event that observes the failure, and the section won because whether a hook's `additionalContext` reaches the model is unverified and the hook would pin to a message the bundle builds from per-reason templates. FR-5 now has a second trigger, the error string, in the description, and the body gained a short section: the hard family only, the cause, and a `python3`-script route that is itself classified. A live probe later closed the hook: `PermissionDenied` context is not delivered, and the hook's `reason` is not the model-visible text. A heredoc is not named as a route because it was never tested.

## 2026-10-26 — a fifth skill, `plugin-creation`, and the probe behind it

A session setting up a plugin repository hand-rolled a `--plugin-dir` launch, a `PATH_add` to a sibling checkout and a deferred marketplace listing, because nothing routed "how do I load a plugin under development" to the toolkit. `plugin-creation` takes a repository through gitlore, `/plugin-dev:create-plugin` and the vendored toolkit in the order the brief decided, and routes away from the bare flag to the dogfood launcher. A fifth description is a cost taken deliberately, per D-1 and N-1: roughly 130 tokens in every session where the plugin is enabled, bounded by a `Not for` clause. D-1 was amended in place for the count and the widened moment; its boundary is untouched.

D-10 records the split: `bin/plugin-craft-creation-status` detects where a repository stands and the skill body keeps only judgement. The probe is the plugin's first executable, so the architecture no longer reads "no commands, no agents and no hooks" without the `bin/` clause. It ships as an entry script plus a sourced `lib/` of file-format readers to stay under the 400-line cap, which is why `dist.include` gained `bin` and `lib`. For the probe, a gitlore setup counts as committed when HEAD holds it, so later edits to `.envrc` and `.gitmodules` do not send the route back.

## 2026-10-26 — the plugin shipped its first hook

`claude --version` reports the installed binary, while a session runs the version it launched with, and an agent stamped an observation with the wrong one. The rule was already in prose and did not stop it, so D-11 adds a `PostToolUse` hook that annotates a mismatch. The plan's probing changed the brief's recipe: the last transcript line usually has a null `version`, so the reader takes the last non-null one. The hook made "no hooks of its own" in the Architecture and "four skills" in FR-1 false, and both were rewritten; `hooks` joined `dist.include`.

## 2026-10-26 — `skill-authoring` gained a reference node

A new rule — text a plugin puts in front of an agent carries no conditional a script could have evaluated — landed in `skill-authoring`, and it took the hub past the ~200-line cap. The bundled-scripts section and its project-root subsection, about 93 lines and needed only when a skill must run a script, moved to `references/bundled-scripts.md`, verbatim apart from heading levels; the hub keeps a short summary routing by what a reader arrives holding. D-7 now records that `skill-authoring` is a hub plus one reference file, so it is no longer true that only `hook-authoring` has reference files. The rule is a design principle across skill prose, scripts and hooks rather than a hook rule, which is why it lives in `skill-authoring` with a one-line pointer from `hook-authoring`.

## 2026-09-17 — the toolkit closed the first-release gap, and the section went with it

Toolkit 0.8.0 landed the fix for the gap the first release surfaced: detection is by tag alone, the version-guard hook's message branches on that predicate and names the maintainer's edit rather than a recipe that cannot select a version, and the shipped README documents setting the version and committing it. D-5's reopen-if fired as written, so `toolkit-release`'s first-release section was deleted rather than updated — what it carried is now in a file every consumer of the toolkit already has.

The same pull settled a second candidate the same way. An unreadable `marketplace.json` used to reach `create_github_release` on `--resume` and die in the marketplace bump, leaving a public release; 0.8.0 refuses it before any side effect, so there is no half-landing left for the skill to describe. Two additions did earn their place, both being things no shipped file states: `url.<base>.pushInsteadOf` sends the release to a rewritten repository while every preflight probe reads the original, and is left unchecked deliberately because refusing on presence does not generalize; and a `prerelease` failure aborts before anything public while looking exactly like a broken release, which piping the recipe through `tail` makes worse by masking the exit status.

The pattern worth keeping is that a skill scoped to a gap shrinks when the gap closes. Documenting the old behaviour for consumers pinned to an older toolkit was considered and dropped: the remedy for them is the pull, not a second description.

## 2026-09-08 — the first release disproved one of the skills it exercised

Cutting v0.1.0 was the first occasion any session needed `toolkit-release`, and it falsified a section. The skill claimed the marketplace push is refused by the permission classifier as an external repo "regardless of the sandbox flag, until `/add-dir` has been run." The push completed with neither `/add-dir` nor an allow rule configured. What the classifier weighs is the command as invoked, so a `git push` nested inside `release.sh` is not judged in its own right; the refusal is real, but only for a push an agent issues directly. The shared memory fact asserting the stronger claim was corrected in the same pass.

The release also surfaced a gap nothing documents: a first release publishes the manifest version verbatim and refuses a bump argument, while the version-guard hook denies the manifest edit and directs at a recipe that cannot select a version there. The only working path is a hand edit committed before the recipe runs. That is a defect in the release toolkit rather than here, so it went to that repo as a brief and is recorded in the skill as a workaround, flagged for removal once the toolkit closes it.

The general lesson is the one the plugin's own thesis predicts: prose describing a failure mode is a hypothesis until a session runs it. Two of the four skills had never been read by a session that needed them.

## 2026-09-07 — a subtree-vendoring skill was offered and declined

`claude-plugin-dev` offered its one general lesson — `git subtree` grafts a ref's root tree, so a repo shipping from a subdirectory needs a second `dist-` tag cut with `subtree split` — as a candidate skill. It was declined, and the reasoning is recorded as a rejected alternative because the offer is the kind that recurs.

Grounding the brief against the tree is what settled it. The brief argued the consumer-side symptom was uncovered; `plugin-dev/README.md` states it outright, along with the mechanism, and that file ships to every consumer of the toolkit. Both call sites already refuse a source ref by name. D-5's scoping of `toolkit-release` to what the README lacks then decides the case on its own, and the only residual audience — a plugin-craft installer using `git subtree` without this toolkit — does not clear N-1's fifth-description test.

## 2026-09-03 — seeded from the ddaanet memory tier

Recall delivers the first 4096 bytes of a memory file and stops. Seven of the eight facts behind this plugin were over that, so most of each body was unreachable by the mechanism meant to reach it — `hook-output-channels` at 23% reachable, `stale-plugin-code` at 45%. `stale-plugin-code` was worse than truncated: its trigger is a symptom with no token, so no index line could ever match it. That is the fact that made a plugin worth cutting rather than a further round of memory-side splitting.

The four skills, the enforcement script and the `precommit` gate landed together, and the migrated sources were retired from the tier in the same pass.

Two decisions were open at the start and closed during it. **`toolkit-release` was in doubt at all** — the vendored `plugin-dev/README.md` already ships the procedure to every consumer, so a skill restating it would have been pure duplication. Reading the README against the memory fact settled it: five failure modes appear in the fact and in neither the README nor anywhere else, and they are what an agent needs mid-run. The skill was written scoped to those (D-5). **`my human partner` phrasing was initially treated as a defect** in text shipped to arbitrary consumers and rewritten user-neutral by the extraction. That was wrong on the `superpowers` precedent, and it was restored (D-9); the memory fact recording the extraction hazards now names the exemption explicitly so a later pass does not re-derive it.

One finding arrived after the seed brief was written and changed a section rather than adding one: `hookSpecificOutput.additionalContext` is delivered on a `PreToolUse` **deny**, not only when an allowed call then fails. The tier's own sentence claimed only the weaker thing, and a blocked call never runs, so anyone building a deny around the field was guessing. Verified against CC 2.1.258. It became FR-3, and it is why `hook-authoring`'s hub teaches the three-way audience split as the default guard-hook shape.
