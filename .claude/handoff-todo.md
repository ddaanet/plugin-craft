## Open decisions

- Memory remote `ddaanet/plugin-craft-memory` was created public, matching the public parent per gitlore's default, on the reasoning that the store was an empty scaffold at the time. Private is a GitHub settings flip if wanted.

## Remaining

- Add the `plugin-craft` row to `ddaanet/claude-plugins`' `marketplace.json`. `just check-version` reports the entry missing, which is expected before the first release; the release recipe creates it, and that recipe needs the sandbox disabled and `/add-dir` on the marketplace repo.
- `plugin-craft:toolkit-release` and `plugin-craft:verifying-plugin-changes` are written but have never been read by a session that needed them. Dogfood both on the first real release rather than waiting for a later plan.