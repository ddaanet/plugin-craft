# Review focus: plugin-craft 0.1.5 release (`main..dev`)

This is a release review of everything on `dev` since `main`. Each commit had a
per-commit review when it landed; this pass looks at the range as a whole.
Read every file named below in full. A `git diff --stat` and a shellcheck run
are not a review: a previous native-review pass did only that, and its
"no actionable regressions" carries no weight.

## What ships

`dist.include` decides the shipped plugin: `.claude-plugin`, `skills`,
`README.md`, `bin`, `lib`, `hooks`. Anything outside those paths matters only
as a gate (`justfile`, `scripts/`, `tests/`) or as the record of a decision
(`docs/`).

## Settled — do not relitigate

- The decisions recorded in `docs/design.md`, especially D-10 (creation-status
  probe in `bin/` plus a sourced `lib/`, skill body keeps judgement only) and
  D-11 (a `PostToolUse` hook annotating a `claude --version` mismatch). Report
  a place where the code or the skill text contradicts a decision. Do not
  argue that a decision was wrong.
- A fifth skill description (`plugin-creation`) is a deliberate per-session
  cost (D-1, N-1).
- The classifier no-verdict *hook* option is closed: probe P1
  (`plans/classifier-no-verdict/probes.md`) found that a `PermissionDenied`
  hook's `additionalContext` is not delivered. Use that file as the source for
  claims about it; do not propose the hook.
- Residual bounds a script states in its header comment (wrappers,
  path-qualified `claude`, reserved-word leaders, tab or newline in a path,
  the 400-line transcript window) are accepted. Report a bound only when the
  comment misstates what the code does.
- Out of scope: everything under `plans/` (frozen planning records), `TASK.md`,
  `TODO.md`, the `memory` submodule bump, and `plugin-dev/` (vendored,
  generated).

## Code — read in full, then probe

1. `hooks/claude-version.sh`, `hooks/is-claude-version-call.sh`,
   `hooks/running-version.sh`, `hooks/hooks.json`. The hook runs after *every*
   Bash call in every session that has the plugin enabled, so:
   - Can it ever block, emit malformed JSON, write to stderr in a way the
     harness surfaces, or exit non-zero? The header promises none of these.
   - What does it cost on a Bash call with very large stdout or a very long
     command string? `is-claude-version-call.sh` is a per-character bash loop;
     check that the cheap pre-filters really keep ordinary calls out of it.
   - The tokenizer: find a realistic command that matches and should not (a
     false annotation), or that should match and does not, *outside* the
     stated residual bounds. Try `#` comments, `$'...'`, escaped quotes inside
     double quotes, `claude -v` after a newline, and `claude` as an argument
     rather than the program word.
   - Field names: is `tool_response.stdout` what a Bash `PostToolUse` payload
     actually carries, and is `hookSpecificOutput.additionalContext` with
     `hookEventName: "PostToolUse"` delivered to the model? Check against
     `skills/hook-authoring/references/output-channels.md` and
     `input-and-harness.md`, and say which source you relied on.
   - `running-version.sh`: a transcript with no versioned line in the window,
     a half-written last line, a path containing spaces.
2. `bin/plugin-craft-creation-status` and `lib/creation-status-readers.sh`.
   - The header claims it only reads: no writes, no network, `git` with
     `--no-optional-locks`. Find a `git` call or a file operation that breaks
     this.
   - Whitespace and quoting: paths with spaces, quotes or a leading `-`, both
     in what is read and in the shell `action` it prints for a human to paste
     (`shq`). The printed action must be runnable verbatim.
   - The exit-code contract (0 / 1 / 2) and the rule that `next` names the
     *first* `missing` or `blocked` check in route order. Find an input where
     `next` names the wrong check or the exit code disagrees with the lines.
   - Unsetting `git rev-parse --local-env-vars` when run from inside a git
     hook: does every `git` call go through it, and does `g` aim at `ROOT`?
3. `scripts/check-skill-text.sh` (+142) with `tests/check-skill-text.bats`:
   what it now enforces, and whether a violation it is meant to catch slips
   past it (false negative) or a legitimate text trips it (false positive).
4. `justfile` `precommit`: does every new script reach `bash -n`/`shellcheck`,
   and does `plugin-dev/run-bats.sh tests/*.bats` run the whole suite?
   `dist.include`: does the built plugin carry exactly what `hooks.json` and
   the skills reference (executable bits included), and nothing from `tests/`
   or `scripts/`?
5. Tests (`tests/*.bats`): for each code file above, name a behaviour its
   header or the skill text promises that no test pins. Run the suite if your
   sandbox allows (`plugin-dev/run-bats.sh tests/*.bats`). If it cannot create
   scratch repos, say so, and label any git-behaviour finding *inferred*, not
   reproduced.

## Prose — check claims against their sources

These are agent-facing skills. A wrong claim is a defect: an agent acts on it.

- `skills/plugin-creation/SKILL.md` against `bin/plugin-craft-creation-status`:
  check ids, statuses, actors, output format, and how the script is invoked
  when the plugin env vars are absent.
- `skills/verifying-plugin-changes/SKILL.md`, the classifier no-verdict section,
  against `plans/classifier-no-verdict/probes.md`: no claim beyond what was
  probed, and the error string exactly as the probe recorded it.
- `skills/hook-authoring/SKILL.md`, `references/output-channels.md` and
  `references/plugin-agent-containment.md`: internal consistency, and
  consistency with what the new hook in `hooks/` relies on.
- `skills/skill-authoring/SKILL.md` and `references/bundled-scripts.md`: the
  move is meant to be verbatim apart from heading levels. Find content lost,
  duplicated, or left pointing at a heading that moved.
- `skills/toolkit-release/SKILL.md`, `README.md`, `docs/design.md`,
  `docs/changelog.md`: a statement the range made false. For example, a count
  of skills, hooks or reference files, or an architecture line saying the
  plugin has no executables or hooks.
- Size caps: a `SKILL.md` hub is capped at ~200 lines, a `references/` node at
  400. Report any file over its cap.

## Findings format

For each finding:

- **Severity**: high (wrong behaviour or a false claim an agent will act on in
  normal use), medium (wrong in a state that real use reaches, though not
  usually), low (cosmetic, or a state nothing in practice produces).
- **Location**: `path:line`.
- **Failure scenario**: concrete input or state, then the wrong output.
- **Evidence**: reproduced (show the command and its output) or inferred
  (say from what).
- **Fix**: one or two sentences, no patch.

Order findings by severity. End with the list of checks you actually ran, so a
check you skipped shows as missing. If you found nothing in a section, say so
by section rather than once for the whole review.
