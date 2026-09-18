# plugin-craft — changelog

Design-significant changes only: decisions reversed, subsystems built or torn down, requirements added or dropped, a rationale that turned out false. Git history is the full record.

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
