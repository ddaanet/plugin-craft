## Remaining

- `just precommit` fails inside the macOS command sandbox: `check-refs`'s `mktemp` resolves to `/var/folders/…` (`Operation not permitted`), and the creation-status tests report "cannot create a temporary file". It passes unsandboxed and passed sandboxed on Linux.
- Under the macOS command sandbox the probe's python check would likely skip with "cannot create a temporary file": both the probe's own `mktemp` and the vendored `dist.sh`'s `mktemp -d` need a writable temp dir. The `dist.sh` half needs a claude-plugin-dev change. Unverified on macOS.
