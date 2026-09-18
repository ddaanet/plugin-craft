---
name: toolkit-release
description: "What goes wrong when releasing a plugin with the vendored `claude-plugin-dev` toolkit, and what to do about it: the sandbox and classifier failures that leave a release half-landed, what `error: uncommitted changes` actually excludes, the push-route rewrite no preflight catches, and the post-pull check that catches a silently broken justfile. Use when running `just release` or `just update-plugin-dev`, when either half-lands, refuses a tree that looks clean, or fails in its gate before publishing anything. The happy path is in `plugin-dev/README.md`."
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

The classifier also weighs whether the release is what the user asked for.
Reached for on the agent's own initiative — mid-way through executing a task
file, with no user message naming a release — `just release minor` was denied
outright as *[Create Public Surface]*, with the exclusion in place; a denial,
not a prompt, so nothing had started and nothing half-landed. The recovery is
to report it and let the user re-instruct, naming the release. Two runs are the
whole evidence, from different repositories ten days apart, so read this as the
shape of the risk rather than a decision rule.

Validation applies to the command as invoked. With that exclusion in place and
no `/add-dir` on the marketplace repo, `just release` completed including the
marketplace push — the nested `git push` inside `release.sh` is not classified
in its own right (verified against Claude Code 2.1.263). Issuing a cross-repo
push directly is the case that gets refused, as an *external repo outside the
trusted source control org*; `/add-dir` on that repo, or an allow rule, is
what clears it. Reaching for `dangerouslyDisableSandbox` on such a call does
not help, since that route is itself subject to the same validation.

## The push-route check has a stated gap

`common_preflight` refuses when `remote.origin.pushurl`,
`branch.<name>.pushRemote` or `remote.pushDefault` is set, because each sends
the push somewhere `git ls-remote origin` does not read. A
`url.<base>.pushInsteadOf` rewrite produces the same split and is **not**
checked: the release publishes to the rewritten repository while every probe
reads the original. Checking it was declined deliberately — the rewrite fires
only when its base prefixes origin's URL, a non-matching base is inert, and a
global rewrite is an ordinary thing to have configured, so refusing on presence
would be wrong. Rule it out by hand before releasing on a machine that carries
one. Plain `url.<base>.insteadOf` needs no check: it rewrites fetch and push
alike.

## A failing gate is not a failed release

`release` depends on `prerelease`, so a gate failure aborts the run before
anything public happens — correct behaviour that looks identical to a release
that broke. Piping the recipe through `tail` compounds it by masking the real
exit status. Re-run the gate on its own before concluding anything about the
tree or the toolkit.

## `error: uncommitted changes` names its own exemptions

The refusal prints the dirty paths and the exclusions it actually applied — for
the plugin repo and for `MARKETPLACE_DIR` alike, the latter with what a dirty
marketplace repo means for a run that already got that far — so read it rather
than reconstructing the rule. One thing it does not say: `.claude` is exempt
from the check but not from the commit. The release commit takes the whole
index, so anything staged under `.claude` rides it.

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
