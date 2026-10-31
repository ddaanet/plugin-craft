## Remaining

- Inside the macOS command sandbox, `just precommit` fails at `check-refs` and the probe's python check always skips (8 bats tests fail): macOS `mktemp` with no template writes to `/var/folders`, ignoring `$TMPDIR`, and the sandbox grants only `$TMPDIR`. The probe's own call is fixed; the bare calls left are in the vendored `check-refs.sh` and `dist.sh`, briefed to claude-plugin-dev's `inbox/`. Take the fix with `just update-plugin-dev` once a dist tag carries it, then re-run the suite sandboxed on macOS.
