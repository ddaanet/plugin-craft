## Open decisions

- Run the `claude --version` matcher tests under gawk? Default: drop it — gawk is the most complete awk and the hook runs it under `LC_ALL=C`, so with mawk and macOS awk passing it would likely only confirm. Alternative: `brew install gawk`, then run the suite with a `$TMPDIR` symlink named `awk` first on PATH.

## Remaining

- Review state on `dev`: the session review covered everything up to the review-lows fix; the `check_python` HEAD fix and the portable cost tests have only the dispatcher's read; no release review against `main`.
- `just precommit` fails inside the macOS command sandbox: `check-refs`'s `mktemp` resolves to `/var/folders/…` (`Operation not permitted`), and the creation-status tests report "cannot create a temporary file". It passes unsandboxed and passed sandboxed on Linux.
- Run the `claude --version` matcher tests under gawk; mawk and macOS awk have run them (pending the open decision above).
