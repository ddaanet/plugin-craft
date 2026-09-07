# plugin-craft — changelog

Design-significant changes only: decisions reversed, subsystems built or torn down, requirements added or dropped, a rationale that turned out false. Git history is the full record.

## 2026-09-07 — a subtree-vendoring skill was offered and declined

`claude-plugin-dev` offered its one general lesson — `git subtree` grafts a ref's root tree, so a repo shipping from a subdirectory needs a second `dist-` tag cut with `subtree split` — as a candidate skill. It was declined, and the reasoning is recorded as a rejected alternative because the offer is the kind that recurs.

Grounding the brief against the tree is what settled it. The brief argued the consumer-side symptom was uncovered; `plugin-dev/README.md` states it outright, along with the mechanism, and that file ships to every consumer of the toolkit. Both call sites already refuse a source ref by name. D-5's scoping of `toolkit-release` to what the README lacks then decides the case on its own, and the only residual audience — a plugin-craft installer using `git subtree` without this toolkit — does not clear N-1's fifth-description test.

## 2026-09-03 — seeded from the ddaanet memory tier

Recall delivers the first 4096 bytes of a memory file and stops. Seven of the eight facts behind this plugin were over that, so most of each body was unreachable by the mechanism meant to reach it — `hook-output-channels` at 23% reachable, `stale-plugin-code` at 45%. `stale-plugin-code` was worse than truncated: its trigger is a symptom with no token, so no index line could ever match it. That is the fact that made a plugin worth cutting rather than a further round of memory-side splitting.

The four skills, the enforcement script and the `precommit` gate landed together, and the migrated sources were retired from the tier in the same pass.

Two decisions were open at the start and closed during it. **`toolkit-release` was in doubt at all** — the vendored `plugin-dev/README.md` already ships the procedure to every consumer, so a skill restating it would have been pure duplication. Reading the README against the memory fact settled it: five failure modes appear in the fact and in neither the README nor anywhere else, and they are what an agent needs mid-run. The skill was written scoped to those (D-5). **`my human partner` phrasing was initially treated as a defect** in text shipped to arbitrary consumers and rewritten user-neutral by the extraction. That was wrong on the `superpowers` precedent, and it was restored (D-9); the memory fact recording the extraction hazards now names the exemption explicitly so a later pass does not re-derive it.

One finding arrived after the seed brief was written and changed a section rather than adding one: `hookSpecificOutput.additionalContext` is delivered on a `PreToolUse` **deny**, not only when an allowed call then fails. The tier's own sentence claimed only the weaker thing, and a blocked call never runs, so anyone building a deny around the field was guessing. Verified against CC 2.1.258. It became FR-3, and it is why `hook-authoring`'s hub teaches the three-way audience split as the default guard-hook shape.
