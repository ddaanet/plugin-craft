---
name: toolkit-release
description: "What goes wrong when releasing a plugin with the vendored `claude-plugin-dev` toolkit, and what to do about it: the sandbox and classifier failures that leave a release half-landed, what `error: uncommitted changes` actually excludes, and the post-pull check that catches a silently broken justfile. Use when running `just release` or `just update-plugin-dev`, when either half-lands or refuses a tree that looks clean. The happy path is in `plugin-dev/README.md`."
---

# Toolkit release failure modes

Installing, updating, the two-tag scheme, the install block, the release
conventions, and the mandatory `prerelease` recipe are documented in
`plugin-dev/README.md`, which ships with the vendored toolkit in every
consumer. This skill covers only what goes wrong — the part that
README does not carry.

## `just release` must run unsandboxed

The marketplace bump is the recipe's last step and its only write outside the
repo, so under the sandbox it dies there on `mv: inter-device move failed …
unable to remove target: Read-only file system` against the marketplace path.
Everything before it — version commit, tag, branch push, GitHub release — has
already landed, so a sandboxed run leaves a half-done release rather than a
failed one; `just resume-release`, likewise unsandboxed, completes it and is
idempotent.

## Unsandboxed is necessary, not sufficient

The marketplace lives in a sibling repo, and the push into it is refused by
the auto-mode classifier as an *external repo outside the trusted source
control org* regardless of the sandbox flag, until `/add-dir` has been run on
that repo.

## What `error: uncommitted changes` actually excludes

`release.sh`'s `tree_is_clean` gates on `git diff --quiet HEAD` with two
pathspec exclusions: `.claude` (agent working state — task frames staged for
"whatever commit lands next", `settings.json`) and
the gitlore memory mount path, read from `.gitmodules` by the submodule name
`gitlore-memory`. `.claude-plugin` is **not** excluded — git pathspecs match
at the path separator — so a dirty manifest still refuses. Anything staged
under `.claude` rides the release commit. The same check runs against
`MARKETPLACE_DIR`, where an unrelated dirty file fails the release at its
last step. A consumer whose vendored `plugin-dev/` predates the `.claude`
exclusion still refuses on a staged frame; read its `tree_is_clean` before
blaming the tree.

## Check `just --list` after a subtree pull

A toolkit version that requires a consumer-side change (the `prerelease`
recipe was one) makes `just` refuse to compile *any* recipe, so the breakage
is invisible until the next unrelated recipe run. Land the consumer-side fix
as its own commit, separate from the subtree-pull merge commit: the merge
commit is toolkit content, the fix is the consumer repo's own. The `just --list`
check stands regardless of the migration notes, which nothing enforces.

## Read the changelog from the source checkout

Read the toolkit's `docs/changelog.md` from a local clone of the source
repo, never from `plugin-dev/` — the `dist-` tree ships no `docs/`. Crossing
more than a patch version rewards checking it: its pointer lines say outright
when a release is breaking. `git -C <source-checkout> show
<tag>:docs/changelog.md` reads a specific version without checking it out.
