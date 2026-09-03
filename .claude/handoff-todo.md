## Open decisions

- What version the first release publishes. `.claude-plugin/plugin.json` holds `0.0.0`, and a plugin that has never been released has nothing to bump from: its first `just release` takes no bump argument and publishes whatever the manifest already holds, refusing one if passed. So the manifest has to carry the intended version before the release runs. The version-guard `PreToolUse(Write|Edit)` hook refuses agent edits to `.version`, so setting it is my human partner's call and my human partner's edit.
- Memory remote `ddaanet/plugin-craft-memory` was created public, matching the public parent per gitlore's default, on the reasoning that the store was an empty scaffold at the time. Private is a GitHub settings flip if wanted.

## Remaining

- Run preflight, then `just release` if green. Two environment conditions, both necessary: run it with the command sandbox disabled, or it dies at the marketplace bump on `mv: inter-device move failed … Read-only file system` leaving a half-done release rather than a failed one; and `/add-dir` the marketplace repo first, or the auto-mode classifier refuses the push into it as an external repo outside the trusted source control org regardless of the sandbox flag. `just resume-release`, likewise unsandboxed, completes a half-done one and is idempotent.
- The release creates the `plugin-craft` row in `ddaanet/claude-plugins`' `marketplace.json` itself. `just check-version` reporting the entry missing is the expected pre-release state, not a fault to fix by hand.
- Dogfood `plugin-craft:toolkit-release` and `plugin-craft:verifying-plugin-changes` during that release. Both were written this session and neither has been read by a session that needed it; the release is the first real occasion for either.