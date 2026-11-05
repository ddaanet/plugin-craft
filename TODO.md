## Remaining

- Re-run the suite inside the macOS command sandbox. The vendored toolkit is at 0.15.0, whose `check-refs.sh` and `dist.sh` pass `mktemp` a `$TMPDIR` template, so `just precommit` and the 8 bats tests that failed sandboxed on macOS should now pass; this was only verified on Linux.
- `just check-size` (shipped unwired in toolkit 0.13.0) reports `skills/verifying-plugin-changes/SKILL.md` at 10789 bytes over the 10000 `SKILL.md` cap. Split it along a when-needed seam, then decide whether `check-size` and `check-frontmatter` (0.15.0, passes today) join `precommit`.
