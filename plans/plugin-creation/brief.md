## Brief: a plugin-creation skill that sequences gitlore, create-plugin and the toolkit

2026-10-12, from a micro session planning the extraction of `ghmem` into its
own plugin repo.

### Decisions

- **plugin-craft gets a plugin-creation skill.** My human partner's call. It
  wraps up the whole route from an empty or freshly extracted repo to a
  ddaanet-shaped plugin, so a session does not reassemble it from three
  sources.
- **Its order: initialize gitlore, then load `/plugin-dev:create-plugin`.**
  Also my human partner's. The toolkit setup follows.

### Why it is needed

The session that prompted this planned a new plugin and hand-rolled what the
toolkit already ships: a `--plugin-dir` launch, a `PATH_add` to a sibling
checkout, a deferred marketplace listing. Nothing routed it to
`claude-plugin-dev`. The ddaanet memory fact `claude-plugin-dev` describes
the toolkit as release infrastructure and predates the dogfood launcher, so
"how do I load a plugin under development" does not reach it.

### Constraints

Read from `claude-plugin-dev` at 0.9.3 unless marked otherwise.

- **The manifest comes before the toolkit.** `install.sh` aborts without
  `.claude-plugin/plugin.json` in the working directory, and refuses a tree
  with uncommitted changes. So: create-plugin, commit, then install.
- **The plugin root is the repo root.** A plugin still nested in another
  repo cannot take the toolkit; it has to be extracted first.
- **Three acts belong to the human's shell.** `install.sh` writes
  `.claude/settings.json`, which the agent sandbox cannot. `just dogfood`
  must not run through the agent's Bash, per the toolkit manual. `direnv
  allow` follows the `.envrc` edit.
- **What `install.sh` leaves to the consumer:** `precommit` and `prerelease`
  recipes, `PATH_add plugin-dev/bin` as the last `PATH_add` after gitlore's,
  `/dist/plugin/` in `.gitignore`, then `just --list` to confirm the
  justfile still compiles.
- **A first `just release` takes no bump argument.**
- **gitlore's memory submodule needs a public `https://` remote before the
  first release.** `/plugin install` clones with `--recurse-submodules`, and
  the local placeholder url aborts the install. From the ddaanet memory fact
  `plugin-recurse-clone`; not re-verified today.

### Open, not decided

- **Hybrid Python+plugin repos.** The toolkit's design doc lists them as out
  of scope, and the plugins shipping a `bin/` today run stdlib-only code on
  the system `python3`. `ghmem` needs Python 3.14 and third-party packages,
  and neither the dogfood copy nor a marketplace cache carries a `.venv`.
  The skill should at least name the case. The micro plan's provisional
  answer is `uv tool install` beside the plugin; that is one session's
  default, not a tested route.
- **How much is a skill body and how much a script.** Most of the route is
  detectable state: is there a manifest, a `plugin-dev/`, a gitlore mount,
  the right `.envrc` order, an ignored `dist/plugin/`. A script that reports
  the first missing step would leave the body for judgement. A suggestion
  from outside; plugin-craft's call.
- **Overlap.** `toolkit-release` already covers a release that half-lands,
  and `verifying-plugin-changes` covers reload paths. Whether the new skill
  links to them or absorbs anything is plugin-craft's call.

### Additional context

The plan that would be the skill's first user is
`/Users/david/code/micro/plans/repo-split/plan.md`, Phase 3. It does not
depend on the skill existing.
