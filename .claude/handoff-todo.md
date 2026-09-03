## Open decisions

- Whether the toolkit release-and-vendoring skill belongs in this plugin at all, or whether the procedure is better left in `claude-plugin-dev`'s `toolkit/README.md`, which already ships with the vendored files. The brief raises this as its own open question and says to settle it before writing that skill; the other three do not depend on it.
- Memory remote visibility: created public to match the public parent, on the reasoning that the store was an empty scaffold at the time. Private is a GitHub settings flip if preferred.

## Remaining

- Write the four skills under `skills/`, per the brief's decisions: `hook-output-channels` §1–6 only (§7 goes to `craft`), descriptions naming the moment rather than the topic, purpose → "Use when" → exclusions, verification dates carried through, and no `[[wikilink]]` or memory-file citation in distributed skill text.
- Fill in the `justfile`'s stub `precommit` once there is something to check.
- Push `main` and memory's `live`.
- Add the `plugin-craft` row to `ddaanet/claude-plugins`' `marketplace.json` (`just check-version` currently reports the entry missing, which is expected pre-release).
- `brief-additionalcontext-survives-deny.md` appeared untracked at the repo root during the session and has not been read — decide whether it belongs in this repo.
- Do not edit or retire the eight source facts in `memory/ddaanet/`: that tier is shared with nine repos and retiring them is a separate gitlore-side pass. Their removal is what would bring `memory/MEMORY.md` (25,846 bytes) back under the ~24,985-byte loader cutoff it currently exceeds.
