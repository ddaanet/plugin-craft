---
name: toolkit-release
description: "What goes wrong when releasing a plugin with the vendored `claude-plugin-dev` toolkit, and what to do about it: the sandbox and classifier failures that leave a release half-landed, what `error: uncommitted changes` actually excludes, why a first release cannot set its own version through the recipe, and the post-pull check that catches a silently broken justfile. Use when running `just release` or `just update-plugin-dev`, when either half-lands or refuses a tree that looks clean, or when cutting a plugin's first release. The happy path is in `plugin-dev/README.md`."
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

The durable fix is a `just release:*` entry in `sandbox.excludedCommands`,
which sets the unsandboxing flag on the call unconditionally. It does **not**
auto-approve: an excluded command still goes through full permission
validation. What it buys is that the exclusion is static, so nothing depends
on an agent choosing to pass an override flag.

Validation applies to the command as invoked. With that exclusion in place and
no `/add-dir` on the marketplace repo, `just release` completed including the
marketplace push — the nested `git push` inside `release.sh` is not classified
in its own right (verified against Claude Code 2.1.263). Issuing a cross-repo
push directly is the case that gets refused, as an *external repo outside the
trusted source control org*; `/add-dir` on that repo, or an allow rule, is
what clears it. Reaching for `dangerouslyDisableSandbox` on such a call does
not help, since that route is itself subject to the same validation.

## A first release needs the version set by hand, and committed

A plugin that has never been released has no previous version to bump from, so
`just release` takes no bump argument and publishes whatever the manifest
holds; passing one is refused. The intended version therefore has to be in
`plugin.json` before the recipe runs, and two things obstruct putting it there.

The version-guard hook denies the edit and its message says to invoke the
recipe instead — advice that is correct in the steady state and impossible
here, because no recipe invocation can select a version on a first release.
And the recipe's first-release branch creates **no commit**: it tags `HEAD` and
requires the manifest to already hold the version on a clean tree. Editing the
manifest and going straight to `just release` therefore fails on `error:
uncommitted changes`, from the same gate described below.

The working sequence is to write the version into the manifest, commit it, then
run `just release` with no argument. Editing a guarded file is my human
partner's call to make, not something to route around on your own initiative.

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
