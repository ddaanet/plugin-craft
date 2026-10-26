# Plan: annotate `claude --version` with the running version

Source: `brief.md` (2026-09-26, written in another repository). The brief's
mechanism, constraints and open points are input. This plan checks them,
lays out the forks, and stops before implementation. Nothing here is decided
until "Decisions pending" is answered.

Deviation note: tasks are contracts, not code, per `craft:plan-contracts`.

## Claim verification

Probed 2026-10-26 on CC 2.1.310 (this session's own version).

| # | Claim | Verdict | Settled by |
|---|-------|---------|------------|
| C1 | `claude --version` prints the on-disk binary's version | verified | `claude --version` printed `2.1.310 (Claude Code)`; `command -v claude` is a wrapper (`.gitlore/bin/claude`) resolving to the installed `versions/` dir. Output carries a ` (Claude Code)` suffix to strip |
| C2 | Transcript entries carry a `version` field | partly refuted | Not every line: in this session 42 of 107 lines have none (types `agent-name`, `mode`, `custom-title`, `last-prompt`, `atis-latch`, `api-request-blob`, `queue-operation`, `file-history-snapshot`); `user`, `assistant`, `attachment`, `system`, `api-request` carry it |
| C3 | "the last entry" carries the version | refuted | `tail -n1` had `version: null` (type `atis-latch`) in this session and in 60 of 60 recent transcripts checked. The reader must take the last entry with a non-null `version` (`jq` `select(.version)` over a tail window). Those were mostly finished sessions; the tail of a live mid-turn transcript was not observed |
| C4 | Subagent transcripts carry the same field | verified | `<session>/subagents/agent-*.jsonl`: 63 entries `2.1.310`, 12 null, no other value; same non-null rule |
| C5 | Which `transcript_path` a subagent's hook gets | verified by the skill, not re-probed | `skills/hook-authoring/references/input-and-harness.md` (checked on 2.1.220): inside a subagent it points at the parent. A subagent runs in the parent process, so the version is the same either way |
| C6 | A session keeps its launch version after an update | verified | The binary is one process per session; this session's EXECPATH is `versions/2.1.310`, the dir holds 2.1.308 to 2.1.310. The incident (launch 2.1.281, installed 2.1.283) is not reproducible without an update mid-session; mixed-version transcripts (a `claude -c` resume across an update) were looked for in 80 recent transcripts and none was found, so "last non-null" vs "first" is untested |
| C7 | An env var may expose the running version | verified in the Bash tool, unverified in a hook | Tool env holds `CLAUDE_CODE_EXECPATH=/Users/david/.local/share/claude/versions/2.1.310`. The install layout keys the filename by version, so its basename is the version of the process that launched. No dedicated `*_VERSION` var exists (`env` grep). Not shown: that a hook subprocess inherits it. A `claude -p --settings` probe with a `SessionStart` hook dumping env was blocked (API host denied by the sandbox), so the probe must be rerun unsandboxed or in the implementing session |
| C8 | `/proc/$CLAUDE_PID/exe` as a source | refuted here | `ls /proc/$CLAUDE_PID/exe` failed in the sandbox; `/proc` does not exist on macOS, so not portable anyway |
| C9 | The hook can see the printed version | verified by the skill | `PostToolUse` carries `tool_input.command` and `tool_response.stdout`; a non-zero exit goes to `PostToolUseFailure` instead (`input-and-harness.md`) |
| C10 | `PostToolUse` `additionalContext` reaches the agent | verified by the skill | `hook-authoring/SKILL.md` section 2 and `output-channels.md` |
| C11 | Another doc already states the rule | found | `plugin-agent-containment.md` ends: take the version from the transcript `version` field, since `claude --version` reports the installed binary. The trap is documented in prose; the hook is the mechanical version |

Unverifiable without more setup: behaviour in a session actually updated
mid-run (needs a second installed version and a live session), and whether
`claude --version` can differ from EXECPATH when `claude` is a wrapper
pointing at a different install than the running one.

## What the repo says about adding a hook

The brief frames this as an addition. In this repo it is a design change:

- `docs/design.md` Architecture: "A Claude Code plugin with no commands, no
  agents and no hooks of its own." FR-1 says "One plugin, four skills". The
  README says four skills. A shipped hook breaks all three statements and
  needs a decision entry plus FR/Architecture/README edits.
- `dist.include` lists only `.claude-plugin`, `skills`, `README.md`. A
  `hooks/` directory would not ship until it is added.
- Plugin `hooks/hooks.json` registration is read at session start and does
  not reload (`verifying-plugin-changes`); script bodies are read per call.
  Dogfooding therefore needs a new session, and the plugin's own `.claude/`
  tree is the wrong place to test (`plugin-dev` hooks live there).
- The plugin's ethos (D-3, D-6) is skills that fire on moments. The harness
  preference "deterministic mechanical work belongs in the harness" supports
  a hook; the cost is the first executable code the plugin ships to every
  consumer, on every `Bash` call of every enabled repo.

## Options

### O1: the transcript tail (the brief's proposal)

`claude --version` exits 0, so `PostToolUse` alone is enough. Read the last non-null `version` from
`transcript_path`, compare with the stdout.

- For: documented payload field; the same source the prose rule names; works
  for resumed sessions (latest entry wins).
- Against: needs a tail read plus `jq` on every matching call (rare, so
  cheap); a tail window may hold no versioned entry in a long tool-result
  tail; the transcript may lag the live process (not observed).

### O2: `CLAUDE_CODE_EXECPATH` basename

Compare stdout against `basename "$CLAUDE_CODE_EXECPATH"`.

- For: no file read; no `jq`; the value is the launched binary itself.
- Against: undocumented variable; unverified in hook env (C7); assumes the
  versioned install layout, which a custom install or a package manager
  would not follow. Silent breakage if the layout changes.

### O3: O2 first, O1 fallback

Use EXECPATH when its basename looks like a version, else read the
transcript; stay silent if neither yields a version. Two code paths and two
sets of tests for one trap. Worth it only if C7 verifies and O1's cost is
shown to matter, which it is not by the numbers above.

### O4: no hook; strengthen prose

Add a short paragraph to `verifying-plugin-changes` (the skill is about the
running-vs-on-disk gap, and its `description:` already names that moment)
saying `claude --version` is the installed binary and the session version
is the transcript `version` field or the `EXECPATH` basename. Zero shipped
code, no design-doc contradiction. Against: it is the same prose that
already exists in `plugin-agent-containment.md` (C11) and did not prevent
the incident, because nothing makes an agent read it at the moment it runs
`claude --version` (the trap has a keyword, `claude --version`, which is the
case for a hook rather than a skill).

### Placement (independent of O1 to O4)

- P1: ship in plugin-craft (the brief's choice, made by my human partner
  per the brief). Every consumer of the plugin gets it.
- P2: a user-level or per-repo hook, not shipped. Keeps this plugin
  hook-free; the script and tests would still live somewhere.

### Match rule and output text

Match on the parsed command: split `tool_input.command` into simple
commands (`&&`, `||`, `;`, `|`, newlines), then require the program word
`claude` with `--version` or `-v` among its arguments. Not a substring
test, so `echo "claude --version"` and `git commit -m "claude -v"` do not
fire. A wrapper (`env X=1 claude --version`, `command claude -v`) is a
residual bound to state in a comment. Output: `hookSpecificOutput`
`additionalContext` only, per the three-channel rule; no `systemMessage`
since the human sees the mismatch in the tool result.

## Recommended default (not a decision)

O1 for the source, placement P1, matcher `Bash`, `PostToolUse` only. Reason:
it is the only source whose payload field is documented, and C3 shows the
brief's own recipe needs the last-non-null correction before it works.
Verify C7 during the implementation session; if EXECPATH is present and
version-shaped in hook env, reconsider O3 only if a measured cost
motivates it. O4 is the cheap alternative if the design-doc cost of the
first shipped hook is judged too high.

## Task sketch if a hook is approved

Contracts only; sized well under the 400-line cap, one commit each where
noted. Red phases per `craft:test-discipline`: each test must fail on
unchanged code by a failed assertion.

1. **Decision record (prose, Sonnet).** Precondition: decisions below
   answered. Post: `docs/design.md` carries a decision entry for the hook,
   updated Architecture and FR-1 wording, README "skills and one hook"
   paragraph, `docs/changelog.md` line; `dist.include` gains `hooks`.
   Invariant: D-1 to D-9 not reopened; `just precommit` passes.
2. **Version extractor (red then green).** Interface:
   `scripts/running-version.sh <transcript.jsonl>` prints the last non-null
   `version`, exit 1 and empty output if none. Cases (bats, fixtures built
   from the C2 line types): trailing null-version lines after a versioned
   one; no versioned line; mixed versions (last wins); spaces in the path;
   empty file.
3. **Matcher (red then green).** Interface:
   `scripts/is-claude-version-call.sh <command-string>` exit 0 iff a simple
   command is `claude` with `--version`/`-v`. Cases: bare, `&&`-chained,
   piped, quoted-argument false positives (`echo`, `git commit -m`,
   `grep`), `-v` on other programs, `claude -p --version`? (state the
   expected result in the test), leading env assignment.
4. **Hook script.** Interface: `hooks/claude-version.sh` reads the payload
   on stdin; emits `{"hookSpecificOutput":{"hookEventName":"PostToolUse",
   "additionalContext":"..."}}` only on mismatch; otherwise no output and
   exit 0. Invariant: never exits non-zero, never blocks; any extractor
   failure is silent (log nothing) except in the mismatch path. Message text
   follows `craft:directive-writing`: states the installed and running
   versions and the act (stamp with the running one). Tests feed payload
   JSON for match, mismatch, no-match command, subagent payload (`agent_id`
   present), and missing `transcript_path`.
5. **Registration and shipping.** `hooks/hooks.json` with a
   `PostToolUse` matcher `Bash` entry using `${CLAUDE_PLUGIN_ROOT}`;
   `plugin-dev` validation passes; `dist.include` check. Precommit gains
   `bash -n hooks/*.sh` coverage (the existing `bash -n scripts/*.sh` line
   would not see it).
6. **Dogfood (same day).** New session with the plugin loaded via
   `--plugin-dir`: run `claude --version` where installed equals running
   (silent) and where it differs (annotated). The differing case needs a
   second installed version or a stubbed `claude` earlier on PATH printing
   another number; either is acceptable evidence for the annotation, only a
   real update is evidence for the incident. Record the CC version beside
   the observation.

Review: one reviewer (Sonnet floor, one rung above the implementer) for
steps 2 to 5 together; step 1 is prose and needs none.

## Decisions

My human partner accepted every default below on 2026-10-26.

1. **Ship a hook at all, or prose only (O4)?** Default: ship the hook. The
   incident was an agent that had the prose available, and the trigger
   (`claude --version`) is mechanical.
2. **Version source: O1 transcript, O2 EXECPATH, O3 both?** Default: O1.
   Documented field; O2 is unverified in hook env and layout-dependent.
3. **Placement: plugin-craft (P1) or an unshipped hook (P2)?** Default: P1,
   as the brief records my human partner's choice; the design-doc cost in
   "What the repo says" is the price.
4. **Is the design-doc change (first shipped hook, FR-1 wording, a new D-10)
   in scope for this plan?** Default: yes, as task 1, because shipping
   without it leaves the doc false.
5. **Hook language: bash plus `jq`, like the existing scripts?** Default:
   yes. Consumers without `jq` get silence, not an error; state this as a
   residual bound.
6. **Match breadth: `claude --version` and `claude -v` only, or also
   `claude version`/`/version` style forms?** Default: only the two the
   brief names; probe whether the CLI has a `version` subcommand
   before widening.
7. **Message wording and whether to name the running version only on
   mismatch.** Default: mismatch only, as the brief says; wording drafted
   in task 4 under `craft:directive-writing`.
