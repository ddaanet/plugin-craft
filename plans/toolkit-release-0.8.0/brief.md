## Brief: `plugin-craft:toolkit-release` needs updating for claude-plugin-dev's next minor

2026-09-17

Written from a session in `~/code/claude-plugin-dev`. This is a note, not an
edit — nothing in plugin-craft was touched. Source of truth for everything
below is that repo's `docs/changelog.md`, `docs/references/recovery.md` and
`toolkit/release.sh`.

**Status at the time of writing: the changes are committed on `main` and NOT
yet released.** `toolkit/VERSION` still reads 0.7.2. The release is intended to
be `minor` (0.8.0). Verify the tag actually exists before writing a version
number into the skill — `git -C ~/code/claude-plugin-dev tag --list 'v0.8.*'`.

### Decisions

- **First-release detection is now by tag alone.** A plugin is at its first
  release exactly when no `vX.Y.Z` tag exists locally or on origin. The
  marketplace entry plays no part. Previously an existing entry disqualified a
  first release, so a plugin with an entry and no tag was refused; it now
  publishes. The skill's "A first release needs the version set by hand, and
  committed" section describes the surrounding behaviour correctly but predates
  this predicate.
- **The version-guard hook's agent message branches on that same predicate and
  names no route to the proposed version.** The skill currently says the hook's
  message "says to invoke the recipe instead — advice that is correct in the
  steady state and impossible here". Re-read `toolkit/version-guard.sh` before
  restating that: the first-release branch is now distinct. The steady-state
  wording is unchanged and still ships unqualified.
- **New refusal: an unreadable `marketplace.json`.** `common_preflight` now
  distinguishes `jq -e`'s exit 1 (clean no-match) from non-1 (parse error, 5 on
  jq 1.7) and refuses with `could not read <path> — nothing was done`, in both
  `release` and `--resume`, before any side effect. Previously a malformed
  marketplace file surfaced in `release` mode as an unrelated "version drift"
  message, and on `--resume` it was not caught at all: the run reached
  `create_github_release` and died inside `bump_marketplace` with jq's raw parse
  error, leaving a public GitHub release. That is a half-landed-release mode the
  skill should carry, since it is exactly its subject matter.
- **The version-drift refusal's remedies changed.** It no longer suggests
  `git checkout HEAD -- .claude-plugin/plugin.json` or `git fetch --tags`; both
  were dead on every path reaching it. It now says to set `.version` back to the
  last released version, commit that edit, and re-run with the bump that
  produces the intended version. Anyone debugging a drift refusal against the
  skill's description will see different text.
- **`url.<base>.pushInsteadOf` is a stated bound**, not a covered case, of the
  diverged-push-route check. Set, it sends the push to the rewritten repository
  while `git ls-remote origin` still reads the original. It stays unchecked
  because "refuse when set" does not generalize: the rewrite fires only when its
  base prefixes origin's URL, a non-matching base is inert, and a global
  `insteadOf`/`pushInsteadOf` rewrite is ordinary to have configured. Plain
  `url.<base>.insteadOf` needs no check — it rewrites fetch and push alike.

### Two observations from running it, worth the skill's failure-mode sections

- **The classifier denies `just release` in auto mode even with the
  `sandbox.excludedCommands` entry in place.** With `just release:*` present in
  `~/.claude/settings.json`, `just release minor` was denied outright, reason
  `[Create Public Surface]`. The skill already says the exclusion "does not
  auto-approve"; this is the concrete form that takes — a hard denial needing
  the user to re-instruct, not a permission prompt. Nothing had started, so the
  denial is safe rather than half-landing.
- **A flaky gate reads as a failed release.** `just release` runs
  `prerelease → precommit` first, and a transient suite failure aborts it before
  anything public — correct, but the operator sees the release fail with no
  signal that the gate, not the release, was the cause. Two contributing traps:
  piping the recipe through `tail` masks the real exit status, and this
  particular box (~2GB, OOM-prone) produces intermittent suite failures that do
  not reproduce on a clean re-run. Re-run the suite alone before concluding
  anything about the tree.

### Additional context

The toolkit's changelog does not ship in the dist tree. Read it from the source
checkout: `git -C ~/code/claude-plugin-dev show <tag>:docs/changelog.md`. The
entry covering the items above is
`docs/changelog/2026-09-17-refusals-that-end-in-an-act.md`; the first-release
predicate change is the entry before it,
`docs/changelog/2026-09-17-first-release-is-the-manifest-version.md`.
