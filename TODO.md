## Remaining

- Review state on `dev`: every commit has had its per-commit review (the `check_python` HEAD fix and the portable cost tests at medium: lows only, declined); no release review against `main`.
- `just precommit` fails inside the macOS command sandbox: `check-refs`'s `mktemp` resolves to `/var/folders/…` (`Operation not permitted`), and the creation-status tests report "cannot create a temporary file". It passes unsandboxed and passed sandboxed on Linux.
