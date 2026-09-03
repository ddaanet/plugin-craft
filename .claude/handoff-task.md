## Current task

Seed the `plugin-craft` plugin from the ddaanet memory tier, per `brief-plugin-craft-seed.md` (tracked at the repo root). The brief specifies four skills — hook authoring, skill authoring, verifying plugin code you just edited, toolkit release and vendoring — drawn from eight ddaanet memory facts now readable at `memory/ddaanet/`.

Scaffolding is finished and committed; no skill has been written yet.

Done so far:
- `git init` on `main`; `.claude-plugin/plugin.json` (name `plugin-craft`, version `0.0.0`, MIT, homepage `github.com/ddaanet/plugin-craft`); stub `justfile` whose `precommit` and `prerelease` are both `true`.
- claude-plugin-dev toolkit vendored via its own `install.sh` at `dist-v0.7.1` under `plugin-dev/`, version-guard hook wired into `.claude/settings.json` (commit `8535c71`).
- gitlore installed, then repointed off the local-only placeholder: parent remote `ddaanet/plugin-craft` (public) and memory remote `ddaanet/plugin-craft-memory` (public, gitlore's match-the-parent default — flip to private if wanted). ddaanet tier mounted at `memory/ddaanet/` and activated; `CLAUDE.md` holds only `@memory/ddaanet/shared-claude.md` (commit `442d193`, memory commit "Mount the shared ddaanet memory tier").

Nothing is pushed: `main` is ahead of `origin/main`, and memory's `live` is ahead of its remote.
