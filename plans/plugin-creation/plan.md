# Plan: the plugin-creation skill

2026-10-26. Input: `plans/plugin-creation/brief.md`. Grounded against the
vendored toolkit at 0.12.0, gitlore's working tree and
`/plugin-dev:create-plugin` as cached today. Steps are contracts, not code.
The micro plan the brief names as first user is absent at its stated path.

## Goal

A fifth skill that takes a session from an empty or freshly extracted repo to
a ddaanet-shaped plugin: gitlore mounted, a manifest from
`/plugin-dev:create-plugin`, the `claude-plugin-dev` toolkit vendored and its
dogfood launcher running, ready for a first `just release`. Detection of where
a repo stands is a script's job; the skill body keeps only judgement, and
points at the shipped docs for every procedure rather than restating them.
The order is the brief's decided one: gitlore, create-plugin, the toolkit.

## The brief's constraints, re-checked against 0.12.0

- **Manifest before toolkit — holds, and is stricter.** After 0.9.3
  `install.sh` also refuses outside a git repository and in one with no
  commits, ahead of the dirty-tree check. The dirty-tree check is
  `git diff --quiet HEAD`: tracked changes only, so an untracked manifest does
  not refuse, but `subtree add` needs a commit to attach to. Route: repo,
  gitlore committed, manifest committed, then install.
- **Plugin root is the repo root — holds.** `dogfood.sh sync` and
  `install.sh` both refuse without `.claude-plugin/plugin.json` in the working
  directory, and every recipe runs from the root.
- **Three shell acts — hold.** `install.sh` writes `.claude/settings.json`,
  which this sandbox denies (`denyWithinAllow`); `manual/dogfood.md` says to
  run `just dogfood` from the human's shell, not the agent's Bash; `direnv
  allow` follows an `.envrc` edit. Two more join them: relaunching `claude`
  from the repo root once the copy exists, and the `sandbox.excludedCommands`
  entries for `just release *` and `just resume-release *` (a settings write).
  `/gitlore:install` is a candidate sixth: its installer must run with the
  sandbox disabled, and `toolkit-release` records that flag being denied under
  auto mode (open question 4).
- **What `install.sh` leaves to the consumer — mostly holds.** The brief
  missed that a repo with no justfile gets one with `precommit` and
  `prerelease` defined (true at 0.9.3 too); only an existing justfile is left
  needing them. Still left: `PATH_add plugin-dev/bin` as the
  last `PATH_add`, after gitlore's; `/dist/plugin/` in `.gitignore`; `just
  --list` to confirm the justfile compiles. New at 0.12.0: `check-refs` as a
  `precommit` dependency (`migrations/v0.12.0.md`).
- **A first `just release` takes no bump argument — holds** (README,
  Conventions).
- **gitlore's memory needs a public https url — holds, with a trap.**
  gitlore's auto-create path (`scripts/install/create-remote.sh`) writes the
  remote's `sshUrl` into `.gitmodules`, and local-only mode writes the
  placeholder. Commit `75554a8` in this repo is that fix applied after the
  fact. Inferred, not probed: a plugin with a `dist.include` installs from the
  `dist` branch, which holds no gitlink, so the url may matter only for a
  source clone (open question 5).

Not in the brief, and on the route now:

- **`dist.include` is required for a gitlore-mounted plugin.** The plugin
  directory refuses a folder holding a gitlink (`manual/dist-branch.md`);
  sandbox-lies, handoff and gitlore all carry one. The release then needs
  `claude` on PATH for `claude plugin validate --strict`.
- **`MARKETPLACE_DIR` and an `origin` remote** are release prerequisites,
  refused by `release-preflight.sh` with the fix named.
- **`install.sh` vendors over SSH** (`TOOLKIT_URL` is `git@github.com:…`):
  one line in the body for an installer without a key.
- **create-plugin's Phase 7 tells the user to test with `cc --plugin-dir`** —
  the hand-rolled launch the brief exists to prevent. Its Phase 4 also
  initializes git "if creating new directory", which gitlore has already done.

## The route

Actors: **agent** acts itself; **shell** is a command my human partner runs in
their own terminal, which the skill prints verbatim-runnable with the real
path substituted; **decision** is my human partner's call, asked inline with a
default.

1. `repo` — `git init` at the plugin root. Agent.
2. `gitlore` — `/gitlore:install`, which confirms the memory remote with my
   human partner itself; then commit what it staged, through gitlore's own
   memory gate. Agent (open question 4).
3. `manifest` — `/plugin-dev:create-plugin`, its Phase 7 replaced by step 9's
   dogfood; commit. Agent (open question 3).
4. `toolkit` — the install block from `plugin-dev/README.md` (no vendored
   copy exists yet, so the probe prints it). Shell. Then commit
   `plugin-dev justfile .claude/settings.json`. Agent.
5. `recipes` — `precommit` and `prerelease` defined, `precommit: check-refs`,
   `just --list` compiles. Agent.
6. `envrc` — `PATH_add plugin-dev/bin` last, after `PATH_add .gitlore/bin`.
   Agent edits; shell `direnv allow`.
7. `ignore` — `/dist/plugin/` in `.gitignore`. Agent.
8. `dist-include` — the shipped paths, `manual/` not `docs/`. Agent, with
   judgement in the body; commit steps 5–8.
9. `dogfood` — `just dogfood`, then relaunch `claude` from the root. Shell.
   Then verify the plugin loads (create-plugin's Phase 7 checklist, run
   against the copy).
10. `memory-url` — `.gitmodules` url for `gitlore-memory` absolute https.
    Agent edits; decision if the memory repo is private or absent.
11. `origin` — a GitHub remote for the plugin. Decision (it is outward-facing).
12. Not probed (D-10 below): `MARKETPLACE_DIR`, the two
    `sandbox.excludedCommands` entries (shell), then a first bare
    `just release`, no bump, once my human partner names the release.

## Executable steps

**S1 — probe tests (red).** `tests/plugin-craft-route.bats` with the cases in
"Tests" below, run through `plugin-dev/run-bats.sh`; each fails for want of
the script, then for want of the behaviour it names. Sonnet authors; a
different agent reviews the red.

**S2 — probe script (green).** `bin/plugin-craft-route`, contract below. Haiku
implements against the reviewed tests; a Sonnet reviewer checks it.

**S3 — wiring.** Add `bin` to `dist.include` (today it ships `.claude-plugin`,
`skills` and `README.md` only, so the dogfood copy and the `dist` branch would
lack the script). Extend `precommit` with `shellcheck bin/plugin-craft-route`
and `plugin-dev/run-bats.sh tests/`. Run `just --list`, then `just precommit`.

**S4 — skill.** `skills/plugin-creation/SKILL.md`, under ~200 lines: the
description below, then the body's judgement (below), routed by the probe's
`next` line. `scripts/check-skill-text.sh` must pass on it.

**S5 — design doc and changelog.** The edits under "Design-doc edits". Load
`craft:design-doc-writing` first; retire, never renumber.

**S6 — README, manifest, sibling skill.** README: "Four skills" becomes five,
plus a paragraph for the new skill. `plugin.json` `description` gains the
repo-setup moment (not `.version`, which the version-guard refuses). One
sentence in `verifying-plugin-changes` (line 24): "load with `--plugin-dir`"
gains "or, with the toolkit vendored, through its dogfood launcher", since the
new skill routes away from the bare flag.

**S7 — dogfood, the day it ships.** Run `plugin-craft-route` against
plugin-craft's main checkout and, read-only, against sandbox-lies, handoff and
gitlore: each should report `next none`, and any finding is either a probe bug
or a real gap in that repo (report the second, never fix it there). Then walk a
scratch repo under `$TMPDIR` through the whole route with my human partner
taking the shell acts — or let the ghmem extraction be that walk.

One commit per step; S1 and S2 never share one, since the red review is what
proves the tests bite.

## Probe contract

`bin/plugin-craft-route [<dir>]` — bash, one file, no shim (one entry point;
`plugin-craft:skill-authoring` reserves the shim for logic with components).
The name is plugin-prefixed because every enabled plugin's `bin/` shares PATH.
Invoked by bare name from the skill body, always with the repo path given
explicitly, since the session's cwd drifts.

**Pre:** `git` and `jq` on PATH; `just` for the `recipes` check only.
**Post:** reads only, writes nothing, touches no network: the tree,
`git status --porcelain` and the index are byte-identical after a run.
**Invariant:** checks run in route order and each is computed independently,
so an extracted repo that already has a manifest but no gitlore shows both
facts; the `next` line names the first `missing` or `blocked` check only.

Output, one line per check, tab-separated (this crosses into the skill body
and the tests, so it is verbatim):

```text
<status>\t<check-id>\t<detail>
next\t<check-id>\t<actor>\t<action>
```

- `<status>` is one of `ok`, `missing`, `blocked`, `warn`, `skip`. `skip`
  marks a check an earlier `blocked` or a missing repo makes meaningless.
- `<check-id>` is one of the route ids above, plus `worktree` and `python`.
- `<actor>` is one of `agent`, `shell`, `decision`.
- Route complete: `next\tnone\t-\troute complete; first release: see
  plugin-dev/README.md, Conventions`.
- A `shell` action is a runnable command with the absolute root substituted
  and shell-quoted (`cd '<root>' && …`); a path holding a space or a quote
  must survive a paste.

Exit: 0 when no check is `missing` or `blocked`; 1 otherwise; 2 when `<dir>`
is not a directory, an option is unknown, or `git`/`jq` is absent (message on
stderr, nothing on stdout).

What each check reads:

- `repo` — inside a work tree, and `<dir>` is its toplevel. Not a repo:
  `missing`, agent `git init`. A subdirectory: `blocked`, decision "the plugin
  root must be the repo root; extract it first" — extraction is out of scope.
- `worktree` — git-dir equals the common dir. A linked worktree with gitlore
  missing is `blocked` (gitlore's installer refuses one); `ok` otherwise.
- `gitlore` — `.gitmodules` has `submodule "gitlore-memory"`, its path is a
  gitlink in HEAD, `.gitlore/bin/claude` exists, `.envrc` has
  `PATH_add .gitlore/bin`. Present but differing from HEAD: `missing`, agent
  "commit", naming the paths.
- `manifest` — `.claude-plugin/plugin.json` parses and has `name` and
  `version`; committed, as above.
- `toolkit` — `plugin-dev/VERSION` exists; `justfile` carries
  `import 'plugin-dev/release.just'`; `.claude/settings.json` carries the
  version-guard, copy-guard and session-check commands as `install.sh` spells
  them. No `plugin-dev/`: shell, the README install block. Vendored but wiring
  missing: shell, `bash plugin-dev/install.sh`. A zero-byte or non-regular
  settings file counts as absent, with "absent or a sandbox mask" in the
  detail.
- `recipes` — `just --summary` succeeds from the root and lists `precommit`
  and `prerelease`; `precommit` depends on `check-refs`.
- `envrc` — of the non-comment `PATH_add` lines, the last is
  `PATH_add plugin-dev/bin` and an earlier one is `PATH_add .gitlore/bin`.
  Order, not presence. The action names both the edit and the shell
  `direnv allow`; whether direnv was allowed is left to the toolkit's
  `SessionStart` check, which already reports it.
- `ignore` — `git check-ignore` reports `dist/plugin/` ignored whether or not
  the directory exists.
- `dist-include` — `dist.include` exists and is committed. What it lists is
  judgement; `dogfood.sh` and the release refuse a bad line themselves.
- `dogfood` — `dist/plugin/.claude-plugin/plugin.json` exists. Shell,
  `just dogfood`, then relaunch `claude` from the root.
- `memory-url` — the `gitlore-memory` url starts with `https://`. A
  placeholder: decision (no public memory remote exists). An SSH url: agent,
  the https rewrite of the same `owner/repo`.
- `origin` — `git remote get-url origin` succeeds. Decision.
- `python` — `warn` when a shipped path (`dist.include` entries, or `bin`,
  `hooks`, `scripts` without one) holds a `*.py` file or a python shebang,
  naming the first; `ok` otherwise. Never blocks.

## Tests

`tests/plugin-craft-route.bats`. Each case builds its state in a scratch repo
under `$BATS_TEST_TMPDIR` from a shared helper (no network: the toolkit is a
stub `plugin-dev/VERSION` and settings file, gitlore a `.gitmodules` entry, a
gitlink placed with `git update-index --cacheinfo 160000,…` and a stub
`.gitlore/bin/claude`), and asserts the `next` line and the exit status; the
cases marked † also assert one status line.

- `empty dir: next is repo, agent git init`
- `subdirectory of a repo: repo blocked, exit 1` †
- `linked worktree without gitlore: worktree blocked` †
- `fresh repo: next is gitlore`
- `gitlore staged, not committed: next is gitlore, commit`
- `gitlore committed, no manifest: next is manifest`
- `manifest not JSON: manifest missing`
- `extracted repo with manifest and no gitlore: manifest ok, next gitlore` †
- `manifest committed, no plugin-dev: next is toolkit, shell install block`
- `vendored, hooks unwired: next is toolkit, shell bash plugin-dev/install.sh`
- `zero-byte settings.json: treated as absent` †
- `justfile without prerelease` and `precommit without check-refs`: each
  `next is recipes`
- `envrc with plugin-dev/bin before .gitlore/bin: next is envrc`; `a PATH_add
  between .gitlore/bin and plugin-dev/bin: envrc ok` (sandbox-lies' shape)
- `dist/plugin not ignored: next is ignore`; `no dist.include: next is
  dist-include`; `no copy: next is dogfood, shell just dogfood`
- `ssh memory url: next is memory-url, agent`; `placeholder memory url: next
  is memory-url, decision`; `no origin: next is origin`
- `complete repo: next none, exit 0`
- `path with a space and a quote`: the complete case gives `next none`, and
  the toolkit case's printed `cd` runs verbatim in a subshell
- `shipped python file: python warn, exit unchanged` †
- `read-only: status, index and file listing identical before and after`
- `not a directory: exit 2, stdout empty`

## What the body keeps

The probe says where the repo stands; the body decides what to do about it.

- **Fresh versus extracted.** For extracted code, create-plugin reduces to its
  Phase 4 (manifest, README); its discovery and component phases are for code
  that does not exist yet.
- **Override create-plugin twice:** skip its git init (gitlore needed the repo
  first) and replace its Phase 7 `--plugin-dir` with the dogfood route, run
  after step 9. Say so when invoking it, since the command does not know.
- **Shell acts are relayed, never run.** Print the probe's action as a block
  for my human partner, wait, re-run the probe. `just dogfood`, `install.sh`
  and `direnv allow` never go through the agent's Bash.
- **The memory remote's visibility** is gitlore's confirmation to make, but an
  installable plugin wants it public; say so before `/gitlore:install` asks.
- **What `dist.include` ships**: the plugin's runtime paths, `README.md`,
  `LICENSE`, `manual` if any; never `docs` or `plans`.
- **What `precommit` checks** beyond the defaults, per the plugin's languages.
- **A `blocked repo`** ends the route: extraction is not this skill's. A
  `python` warning opens the Python section below.
- **After `next none`**: the first release is the README's Conventions and
  `toolkit-release`; a release on the agent's own initiative risks a
  classifier denial, so it waits for my human partner to name it.

## Description and its cost

Draft, `[what] + Use when + Not for`, 511 characters:

> Take a new or freshly extracted repository to a working Claude Code plugin
> in order — gitlore memory, then `/plugin-dev:create-plugin`, then the
> vendored `claude-plugin-dev` toolkit and its dogfood launcher — with a
> script reporting the first missing step. Use when starting a plugin repo,
> extracting a plugin from another repo, or about to load a plugin under
> development with `--plugin-dir` or a hand-written PATH entry. Not for a
> release (`toolkit-release`) or stale loaded code
> (`verifying-plugin-changes`).

**Cost, in NFR-1's terms.** The four descriptions today total 2332
characters, 583 on average; this one sits under that, roughly 130 tokens at
~4 characters a token. It is injected in every session of every repo with
plugin-craft enabled. As part of the cached prompt prefix it is billed at the
cache-write rate once and the cache-read rate after (1.25× and 0.1× base
input on the 5-minute TTL, per Anthropic's published prompt-caching rates), so a 100-call session pays about
130 × (1.25 + 99 × 0.1) ≈ 1,450 base-input-token equivalents, and it holds
~0.07% of a 200k window. The unpriced cost is one more entry competing for the
match on adjacent moments, which the `Not for` clause bounds.

**How it earns it.** The brief records a session that hand-rolled a
`--plugin-dir` launch, a `PATH_add` to a sibling checkout and a deferred
marketplace listing, because nothing routed "how do I load a plugin under
development" to the toolkit. The description carries the tokens that session
held — `--plugin-dir`, "PATH entry", "extracting a plugin" — and names a moment
(D-3), not the topic. Whether it fires is L-1's question and not testable from
here; the dogfood in S7 is the first evidence.

## Design-doc edits

All in `docs/design.md`, plus a dated `docs/changelog.md` entry.

- **FR-1** — "One plugin, five skills, each firing on a moment."
- **FR-10 (new)** — `plugin-creation` owns the sequence across gitlore,
  create-plugin and the toolkit, and nothing the shipped docs carry; it routes
  away from a bare `--plugin-dir` to the dogfood launcher. *Done (prose)*.
- **FR-11 (new)** — the route's state is read by `bin/plugin-craft-route`,
  read-only, one line per check and a `next` line. *Done* — pinned by
  `tests/plugin-craft-route.bats` in `precommit`.
- **D-1, amended in place** — "Five skills, one plugin", and the shared moment
  widens to "setting up a repository to build on the harness, building on it,
  or debugging it". This changes the count and the moment sentence; the
  boundary D-1 decides (one plugin, packaging neutral on cost) is untouched,
  so it is not a re-litigation, but D-1 sits in the do-not-re-litigate line
  and my human partner should see the wording.
- **D-10 (new)** — the script detects, the body judges. The probe checks only
  what no downstream gate reports before harm: the release preflight refuses
  a missing `MARKETPLACE_DIR`, a sandboxed run and a missing `origin` before
  anything public, naming the fix, so those are invoked, not pre-checked.
  **Reopen-if** the toolkit or gitlore absorbs a step, as D-5's did: the body
  shrinks, and the probe keeps the check only if it still reports earlier.
- **Architecture** — "no commands, no agents and no hooks" gains "and one
  `bin/` executable"; "Four skills" becomes five; the `precommit` paragraph
  adds shellcheck and the bats suite.
- **D-7** — "The other three skills" becomes "The other skills".
- **N-1, reworded, not removed** — "If a fifth description earns its cost"
  becomes "If another description earns its cost". The rejected alternative on
  `git subtree` says "a fifth description's cost against N-1's test"; same
  rewording.
- **Rejected alternatives (new)** — widening `toolkit-release` to cover setup
  (D-5 scopes it to failure modes, and the moment differs); keeping the route
  in the `claude-plugin-dev` memory fact (recall fires on a token, and the
  motivating session held none that matched it).
- **Changelog** — leads with the motivating session; records the fifth
  description as a cost taken deliberately, and D-10's split.

## The Python-hybrid case

The toolkit's design doc puts hybrid Python+plugin repos out of scope. A
shipped `bin/` script runs from the dogfood copy or a marketplace cache;
`dogfood.sh sync` drops ignored paths and `dist` holds only listed ones, so a
`.venv` reaches neither, and the script must find its interpreter and packages
outside the plugin tree.

The body names the case on a `python` warning. Stdlib-only code on the system
`python3`, which the brief reports for every plugin shipping a `bin/` today,
needs nothing. For third-party packages or a newer Python the candidates are
`uv tool install` beside the plugin, its `bin/` calling the installed command,
and a `uv run --script` entry point with inline dependencies. Neither is
tested as a plugin route, so the body prescribes neither. What settles it: one
run of each under the dogfood copy and under a marketplace install in a
scratch `CLAUDE_CONFIG_DIR`, checking first-run latency, offline behaviour and
an installer without `uv`.

## Overlap

The new skill owns the sequence and absorbs nothing. It links to
`plugin-dev/README.md`, `manual/dogfood.md`, `manual/dist-branch.md`,
`toolkit-release` for a release that goes wrong (D-5 unchanged; the route
hands over where its happy path starts) and `verifying-plugin-changes` for
code that looks stale, whose one `--plugin-dir` sentence S6 amends.

## Open questions

Each proceeds on its default unless my human partner says otherwise.

1. **Skill name.** Default `plugin-creation`, matching this plan's directory
   and the gerund-noun names beside it. Alternative: `starting-a-plugin-repo`,
   which names the moment more literally.
2. **Probe name and form.** Default `bin/plugin-craft-route`, bash, one file,
   tab-separated lines. Alternative: JSON output, which the body would parse
   with `jq` for no gain over a line it reads.
3. **create-plugin whole or split around the toolkit.** Default: the decided
   order literally — create-plugin runs through its Phase 6, its Phase 7
   moves after step 9. Alternative: its Phases 1–4, commit, the toolkit, then
   Phases 5–8 under dogfood, which loads every component edit through the
   copy but reorders the decision.
4. **`/gitlore:install` under auto mode.** Default: the agent invokes it as
   gitlore prescribes; if the classifier denies the sandbox-disabled call, the
   body relays the printed command as a shell act. The S7 walk settles it.
5. **https memory url with a `dist.include`.** Default: the probe requires
   https regardless — cheap, and what this repo just did. Settled by a keyless
   install of a dist-ref plugin, with a stub `ssh` that exits 255 first on
   PATH.
6. **`check-refs` in `precommit`: `missing` or `warn`.** Default `missing`:
   0.12.0's migration note says to wire it, and the route's goal is the full
   shape.
7. **Probing `MARKETPLACE_DIR` and `excludedCommands`.** Default no, per D-10:
   the release preflight's refusal names each fix. Alternative: a `warn` line,
   which saves one failed release call.
8. **The `verifying-plugin-changes` sentence.** Default: amend it (S6).
   Alternative: leave it, and let the new description carry the routing.
