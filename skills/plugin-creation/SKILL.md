---
name: plugin-creation
description: "Take a new or freshly extracted repository to a working Claude Code plugin in order — gitlore memory, then `/plugin-dev:create-plugin`, then the vendored `claude-plugin-dev` toolkit and its dogfood launcher — with a script reporting the first missing step. Use when starting a plugin repo, extracting a plugin from another repo, or about to load a plugin under development with `--plugin-dir` or a hand-written PATH entry. Not for a release (`toolkit-release`) or stale loaded code (`verifying-plugin-changes`)."
---

# Creating a plugin repository

The order is decided: gitlore, then `/plugin-dev:create-plugin`, then the
`claude-plugin-dev` toolkit. A script reports where the repository stands; this
body covers only the judgement the script cannot make. Every procedure lives in
a shipped doc and is pointed at here, not restated: `plugin-dev/README.md`
(install block, Conventions), `plugin-dev/manual/dogfood.md` and
`plugin-dev/manual/dist-branch.md`.

## The loop

Run the probe by bare name, always with the repository path given explicitly,
since the session's working directory drifts:

    plugin-craft-creation-status /abs/path/to/repo

It prints one line per check, then a `next` line:
`next<TAB><check-id><TAB><actor><TAB><action>`. Act on the `next` line by its
actor, then run the probe again. Stop when it says `next none`.

- **agent** — do the action yourself.
- **shell** — a command my human partner runs in their own terminal. Print the
  action verbatim in a code block, wait, then re-run the probe. `just dogfood`,
  `bash plugin-dev/install.sh`, the toolkit install block and `direnv allow`
  never go through the agent's Bash. The install steps write
  `.claude/settings.json`, which the sandbox denies; `just dogfood` is
  excluded because the sandbox masks dotfiles in the project root, which a
  sandboxed sync would copy or delete (`plugin-dev/manual/dogfood.md`).
- **decision** — ask my human partner inline, with a stated default so the
  thread proceeds without a round-trip.

The probe computes every check independently: an extracted repository with a
manifest but no gitlore shows both facts, and `next` names only the first
missing one. A `skip` line means an earlier block made it meaningless.

## Route ids

Order: `repo`, `worktree`, `gitlore`, `manifest`, `toolkit`, `recipes`,
`envrc`, `ignore`, `dist-include`, `dogfood`, `memory-url`, `origin`, `python`.
After a `next` line, commit what the step produced before moving on, except
where the step text says otherwise.

- **`repo`** — `git init` at the plugin root. A `blocked repo` (the directory
  is inside a larger repository) ends the route: extraction is not this
  skill's job. Say so and stop.
- **`gitlore`** — run `/gitlore:install`, which confirms the memory remote with
  my human partner itself; then commit what it staged through gitlore's own
  memory gate. An installable plugin wants the memory remote public, so say so
  before the installer asks. Under auto mode the classifier may deny its
  sandbox-disabled call; relay the printed command as a shell act instead.
  "Committed" means HEAD holds the gitlore setup, not that its files are
  unmodified, so later edits to `.envrc` or `.gitmodules` do not reopen it.
- **`worktree`** — gitlore's installer refuses a linked worktree. Run the route
  in the main checkout.
- **`manifest`** — run `/plugin-dev:create-plugin` and commit
  `.claude-plugin/plugin.json`. Say two things when invoking it, since the
  command does not know them: skip its git initialisation (gitlore needed the
  repository first), and skip its Phase 7 `--plugin-dir` test, which the
  dogfood step replaces. For extracted code only its Phase 4 (manifest, README)
  applies; its discovery and component phases are for code that does not exist
  yet.
- **`toolkit`** — a shell act: the install block, or `bash plugin-dev/install.sh`
  when vendored but unwired. Then commit `plugin-dev`, `justfile` and
  `.claude/settings.json`. The probe does not check that commit.
- **`recipes`** — `precommit` and `prerelease` defined, `precommit` depending
  on `check-refs`, and `just --list` compiling. Add checks to `precommit` that
  suit the plugin's languages. Without `just` on PATH the probe reports `warn`
  and `next none` then means the recipes went unchecked.
- **`envrc`** — `PATH_add plugin-dev/bin` must be the last `PATH_add`, after
  gitlore's. The agent edits `.envrc`; `direnv allow` is a shell act.
- **`ignore`** — `/dist/plugin/` in `.gitignore`.
- **`dist-include`** — list the plugin's runtime paths, `README.md`, `LICENSE`
  and `manual` if any; never `docs` or `plans`. A gitlore-mounted plugin needs
  the list, since the plugin directory refuses a folder holding a gitlink. Any
  shipped `bin/` script, and any `lib/` it sources, must be listed.
  Commit steps `recipes` through `dist-include` together.
- **`dogfood`** — a shell act: `just dogfood`, then relaunch `claude` from the
  repository root. Afterwards verify the plugin loads against the copy (the
  create-plugin Phase 7 checklist). Never route a session to a hand-written
  `--plugin-dir` launch or a `PATH_add` to a sibling checkout.
- **`memory-url`** — the `gitlore-memory` url in `.gitmodules` must be an
  absolute https url. An ssh url is rewritten by the agent. A placeholder is a
  decision: no public memory remote exists yet, so ask whether to create one.
- **`origin`** — a GitHub remote is outward-facing: a decision.
- **`python`** — a `warn`, never a block. See below.

## A `python` warning

A shipped `bin/` script runs from the dogfood copy or a marketplace cache. The
dogfood sync drops ignored paths and `dist` holds only listed ones, so a
`.venv` reaches neither, and the script must find its interpreter and packages
outside the plugin tree. Stdlib-only code on the system `python3` needs
nothing. For third-party packages or a newer Python, the candidates are
`uv tool install` beside the plugin with `bin/` calling the installed command,
and a `uv run --script` entry point with inline dependencies. Neither is tested
as a plugin route: present both as untested, and let my human partner decide.
The toolkit treats hybrid Python and plugin repositories as out of scope.

## After `next none`

The probe deliberately leaves `MARKETPLACE_DIR`, the
`sandbox.excludedCommands` entries for `just release *` and
`just resume-release *`, and the release itself unchecked: the release
preflight refuses each before anything public and names the fix. The first
release is the README's Conventions and a bare `just release`, with no bump
argument. A release on the agent's own initiative risks a classifier denial, so
wait for my human partner to name it, and use `toolkit-release` if it goes
wrong. Code that looks stale after an edit is `verifying-plugin-changes`.
