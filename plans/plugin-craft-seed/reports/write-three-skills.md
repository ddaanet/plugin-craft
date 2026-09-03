# Report: write-three-skills

Wrote three of the four plugin-craft skills (S2, S3, S4 of
`plans/plugin-craft-seed/inline-plan.md`). `skills/hook-authoring/` (S1) is
another agent's scope and was not touched. `memory/` was read-only, not
edited.

## Files written

- `skills/skill-authoring/SKILL.md` (9,668 B)
- `skills/verifying-plugin-changes/SKILL.md` (8,841 B)
- `skills/toolkit-release/SKILL.md` (3,426 B)

## Descriptions used

**skill-authoring** — used the plan's draft verbatim:
> How to write a skill that is found, triggered and able to reach its own scripts: description shape, what `allowed-tools` actually does, which second-person forms the imperative rule targets, and how a bundled script is invoked when the plugin env vars are absent. Use when writing or revising a skill, a plugin command or its frontmatter, or when a skill exists but is not firing. Complements `plugin-dev:skill-development`.

**verifying-plugin-changes** — used the plan's draft verbatim:
> Confirm that the plugin code actually running is the code you just edited — which reload path refreshes a skill body, a hook registration, a command or a bundled script, and which silently does not. Use when a plugin change appears to have no effect and nothing errors, before trusting any verification of an edit to plugin code, and after a `/plugin update` or a release. Not a guide to writing plugins.

**toolkit-release** — used the plan's draft verbatim:
> What goes wrong when releasing a plugin with the vendored `claude-plugin-dev` toolkit, and what to do about it: the sandbox and classifier failures that leave a release half-landed, what `error: uncommitted changes` actually excludes, and the post-pull check that catches a silently broken justfile. Use when running `just release` or `just update-plugin-dev`, when either half-lands or refuses a tree that looks clean. The happy path is in `plugin-dev/README.md`.

None needed tightening for length; all three already followed purpose → Use-when → exclusion order and read as short TUI-friendly summaries.

## Sectioning

**skill-authoring/SKILL.md** — one file, four `##` sections in plan order:
Descriptions; `allowed-tools` grants, it does not restrict; Imperative form:
what the rule targets; Bundled scripts (with a `###` subheading "Locating
the project root from a bin/ script", carried from the source verbatim as
the plan required).

**verifying-plugin-changes/SKILL.md** — opens with the source's own first
paragraph as the checkpoint (unheaded), then four `##` sections with
headings preserved from `stale-plugin-code.md`: "Marketplace cache is keyed
by version — `/plugin update` no-ops"; "Skill bodies are snapshotted at
session start"; "Hook event registration is frozen; script bodies are not";
"`claude -c` is a full restart, and keeps the conversation".

**toolkit-release/SKILL.md** — a short lead paragraph pointing at
`plugin-dev/README.md` for the happy path, then five `##` sections, one per
S4 failure-mode item: "`just release` must run unsandboxed"; "Unsandboxed is
necessary, not sufficient"; "What `error: uncommitted changes` actually
excludes"; "Check `just --list` after a subtree pull"; "Read the changelog
from the source checkout".

## Wikilinks resolved

From the plan's Constraints table (all sources read entire, resolutions applied as specified):

- `skill-bundled-scripts` → `[[sessionstart-resume-cwd]]` (source line 83): deleted the pointer; the preceding sentence about the `SessionStart(resume)` timing trap already carries the mechanism.
- `stale-plugin-code` → `[[cc-agent-discovery]]`, `[[cc-command-namespacing]]` (line 61): inlined as one clause each — "An agent type is addressed `<plugin>:<agent>` and its definition is cached per session; a command is addressed `/<plugin>:<path-under-commands>`, so a double-prefixed invocation signals a stale nested cache."
- `stale-plugin-code` → `[[skill-bundled-scripts]]` (line 93): within-set → cross-reference `plugin-craft:skill-authoring`.
- `stale-plugin-code` → `[[cc-worktree-memory-freeze]]` (line 102): deleted the parenthetical outright, plus the "D15's" prefix naming an internal plan-step id from an inaccessible repo; the sentence ("This is how the `EnterWorktree|ExitWorktree` matcher was confirmed without a restart") stands alone.
- `stale-plugin-code` → `[[hook-output-channels]]` (line 155): within-set → cross-reference `plugin-craft:hook-authoring`.
- `claude-plugin-dev` → `[[sandbox-effects]]`, `[[classifier-denied-self-config]]` (lines 99, 103), S4 scope: both deleted outright — the read-only-filesystem failure and the classifier-deny/`/add-dir` remedy were already stated inline in the same sentences, so nothing needed re-inlining.

Two wikilinks turned up in my sources that are **not** in the plan's Constraints table (it only lists links for S1/S3/S4 sources, not S2's):

- `skill-description-purpose-first` → `[[claude-plugin-dev]]` (bare "See [[claude-plugin-dev]]." after "Applies to all skills in a plugin, not just the headline one."): resolved as within-set → cross-reference `plugin-craft:toolkit-release`, since that memory fact is exactly toolkit-release's source. No elaboration invented for the connection since the original gave none.
- `imperative-form-scope` → `[[skill-description-purpose-first]]` ("Related: [[skill-description-purpose-first]]."): deleted — both facts landed as sections of the same `skill-authoring/SKILL.md`, so the pointer is redundant inside one document.

## Generalized/withheld illustrations (repo-inaccessible names)

- `imperative-form-scope`'s "handoff deliberately keeps `your post-compaction self` in `skills/precompact/SKILL.md`" → generalized to "One skill body deliberately keeps `your post-compaction self`" — dropped the plugin name and the unreachable path, kept the rule and the reasoning ("it asserts the identity continuity... which `the post-compaction agent` drops").
- `imperative-form-scope`'s "In handoff's two skill bodies, 11 grep hits..." → "In two skill bodies, 11 grep hits..." (measurement kept, plugin name dropped, matching the plan's own generalized phrasing of the figure).
- `skill-bundled-scripts`'s "see the handoff single-turn FR before using it" → generalized to "so weigh it before probing repeatedly" (drops a citation to another repo's internal fact document a reader can't open).
- `skill-bundled-scripts`'s "a throwaway `bin/handoff-probe-test` ran by name" → "a throwaway `bin/` script ran by name" (drops the specific script name from another repo).
- `stale-plugin-code`'s skill-bodies-snapshotted example named `skills/precompact/SKILL.md`, `/handoff:precompact`, and the literal path `/Users/david/code/handoff/skills/precompact` → generalized to "a skill's `SKILL.md`" / "invoking that skill" — none of those identifiers are openable by a plugin-craft consumer.
- `stale-plugin-code`'s closing `claude -c` section named "gitlore's five `gitlore.*` git-config keys, its wrappers, its memory gate" as the illustration of "every hook that writes from it" → generalized to "every hook that writes from it is re-pinned exactly as on a cold start" (this specific drop was a judgment call, not in the plan's explicit resolution table — flagged here for visibility).
- `stale-plugin-code`'s `"My human partner can invoke it with ! /reload-plugins"` and `"...needs my human partner's explicit go-ahead"` → rewritten user-neutral and verb-first: "Invoke it with `/reload-plugins`." and "so that needs the user's explicit sign-off." (David-specific phrasing from the shared CLAUDE.md convention has no place in text shipped to arbitrary plugin consumers; this doubles as an imperative-form fix on the first instance.)
- `claude-plugin-dev`'s `.claude`-exclusion example naming "the `handoff` and `precompact` frames" → generalized to "task frames" in `toolkit-release`.
- `claude-plugin-dev`'s changelog-reading command naming the literal local path `~/code/claude-plugin-dev` → generalized to `<source-checkout>` as a placeholder.

Kept as-is (judged not to need withholding): `gitlore`'s public command names (`/gitlore:resolve`, `/gitlore:gitlore:resolve`) in `verifying-plugin-changes` as an illustration — these are marketplace-plugin command names, not internal filenames or unreachable paths, in the same register as `skill-description-purpose-first`'s own worked examples (revdiff, skill-creator, mcp-builder). Also kept `plugin-dev`'s `release.sh`'s `tree_is_clean`, `MARKETPLACE_DIR`, `gitlore-memory-message`, `gitlore-memory` submodule name in `toolkit-release` — these are literal identifiers inside the vendored `plugin-dev/` toolkit every consumer actually has on disk, not a foreign repo.

## Deliberately left out of toolkit-release (README already carries it)

Per the task's scoping to failure modes only, I did not restate: what each
toolkit file is for; the two-tag scheme and the `git ls-remote`/`install.sh`
mechanics; the install block's three steps; the `precommit`/`prerelease`
recipe requirement and why it's mandatory; the update command forms and the
dist-ref refusal set; the release commit message convention; the
last-released-version/first-release rules; `origin/HEAD` auto-detection; the
version-guard hook; the migration-note mechanism itself (`plugin-dev/migrations/vX.Y.Z.md`,
printed on pull) — only its consequence ("migration notes are guidance to
apply by hand — nothing enforces them, which is why the `just --list` check
stands regardless") survived, since that's the failure-mode reasoning, not
the mechanism. Also left out `claude-plugin-dev.md`'s closing paragraph about
`edify` not vendoring the toolkit (PyPI-publish shape) — irrelevant to a
generic `plugin-craft` consumer and not one of the five S4 items.

## Anything in the plan I could not follow

None. All four sections (S2, S3, S4) and every table resolution in scope
were applied as specified; the two extra wikilinks not covered by the table
(both in S2's sources) were resolved by analogy to the table's own pattern
(delete same-document redundancy; cross-reference a within-set sibling) and
are called out above rather than silently decided.

## Verification output

```
$ cd "/Users/david/code/plugin-craft" && for d in skill-authoring verifying-plugin-changes toolkit-release; do bash scripts/check-skill-text.sh "skills/$d"; done && echo CHECK-CLEAN
CHECK-CLEAN
```
(all three invocations produced no output and exit 0, individually confirmed too)

```
$ cd "/Users/david/code/plugin-craft" && wc -c skills/skill-authoring/SKILL.md skills/verifying-plugin-changes/SKILL.md skills/toolkit-release/SKILL.md
 9668 skills/skill-authoring/SKILL.md
 8841 skills/verifying-plugin-changes/SKILL.md
 3426 skills/toolkit-release/SKILL.md
21935 total
```

```
$ cd "/Users/david/code/plugin-craft" && grep -rnoE '(verified|re-verified|Measured|measured)[^.,;)]{0,55}' skills/skill-authoring skills/verifying-plugin-changes skills/toolkit-release | sort
skills/skill-authoring/SKILL.md:100:verified 2026-07-12
skills/skill-authoring/SKILL.md:88:re-verified by the same live
skills/skill-authoring/SKILL.md:88:verified by test 2026-06-12** (CC 2
skills/verifying-plugin-changes/SKILL.md:127:verified: whether the *old* registration still fires after the
skills/verifying-plugin-changes/SKILL.md:75:verified for skill bodies only
```
(this lowercase-only grep misses capitalized sentence-initial "Verified" —
confirmed separately that "Verified against the CC 2.1.250 docs." (skill-authoring),
"Verified 2026-06-10 (CC 2.1.x)" and "Verified 2026-07-31" (verifying-plugin-changes)
are all present verbatim in the files; `toolkit-release`'s five source items
carried no "verified"-stamped clauses in `claude-plugin-dev.md` to begin with,
so its empty grep result is expected, not a gap.)

Additionally confirmed no leftover David-specific artifacts (`my human partner`,
local absolute paths, other-repo skill/script names) remain in the three files:
`grep -rn "my human partner\|~/code/\|/Users/david\|handoff:precompact\|skills/precompact\|bin/handoff-probe-test\|D15\b" skills/skill-authoring skills/verifying-plugin-changes skills/toolkit-release` → no matches (exit 1).
