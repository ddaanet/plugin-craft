## Remaining

- Review state on `dev`: the session review covered everything up to the review-lows fix; the `check_python` HEAD fix and the portable cost tests have only the dispatcher's read; no release review against `main`.
- `just precommit` fails inside the macOS command sandbox: `check-refs`'s `mktemp` resolves to `/var/folders/…` (`Operation not permitted`), and the creation-status tests report "cannot create a temporary file". It passes unsandboxed and passed sandboxed on Linux.
