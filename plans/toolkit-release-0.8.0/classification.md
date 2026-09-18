# Classification — toolkit-release skill for claude-plugin-dev 0.8.0

Source: `inbox/brief-toolkit-release-skill-updates.md` (2026-09-17). Implicit
bundling: the brief carries discrete items, each classified below.

Verified: `v0.8.0` and `dist-v0.8.0` exist in `~/code/claude-plugin-dev`;
plugin-craft vendors `plugin-dev/` at 0.7.1.

Shared across items:

- **Classification:** Simple
- **Implementation certainty:** High — prose edits to one skill file plus its
  coupled description, `docs/design.md` D-5 and the tier's `claude-plugin-dev`
  fact
- **Requirement stability:** Moderate — which items the skill should carry at
  all is an open call per item (D-5 scopes it to what the shipped README lacks)
- **Behavioral code check:** No — `skills/toolkit-release/SKILL.md` is prose
- **Work type:** Production
- **Artifact destination:** agentic-prose

Items:

- **A · First release.** The 0.8.0 README now documents set-and-commit and the
  guard's first-release wording names the maintainer's edit. D-5's reopen-if
  fires for this section; residual value is consumers vendoring < 0.8.0.
- **B · Unreadable `marketplace.json`.** Refused before side effects in 0.8.0;
  on < 0.8.0, `--resume` publishes the GitHub release, then dies in
  `bump_marketplace`. Half-landing is the skill's subject.
- **C · Drift refusal remedies.** The refusal prints its own remedy; the skill
  does not describe it today.
- **D · `url.<base>.pushInsteadOf`.** Silent wrong-target push, recorded only in
  the source repo's `recovery.md` and a `release.sh` comment — not the README.
- **E · Classifier denies top-level `just release`** as *[Create Public
  Surface]*, despite the `excludedCommands` entry. Contrasts with plugin-craft
  0.1.0, where the same recipe passed; the difference is unexplained.
- **F · Failing gate reads as failed release.** `prerelease → precommit` aborts
  before anything public; `| tail` masks the exit status. The OOM flakiness is
  host-specific.

Evidence: `claude-plugin-dev` changelog entries
`2026-09-17-first-release-is-the-manifest-version.md` and
`2026-09-17-refusals-that-end-in-an-act.md`; `dist-v0.8.0:README.md` lines
178–187; `v0.8.0:toolkit/version-guard.sh` lines 147–158; recalled
`ddaanet/claude-plugin-dev.md` and `ddaanet/classifier-denied-self-config.md`.
