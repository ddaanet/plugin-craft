# Brief: annotate `claude --version` with the running session's version

From a sandbox-lies session, 2026-09-26. My human partner chose plugin-craft
as the home: the trap is "the CC running is not the CC installed". That is the
running-vs-on-disk distinction the `verifying-plugin-changes` skill is about,
applied to the harness binary.

## The trap

`claude --version` prints the version of the binary installed on disk. A
long-running session keeps the version it launched with. After an update
mid-session, the two differ, and an agent that version-stamps an observation
(as gitlore's memory-writing rules and the ddaanet conventions ask) stamps it
with the wrong number.

## The incident

A session launched on CC 2.1.281 ran `claude --version`, got `2.1.283`, and
wrote "CC 2.1.283" into six places: three docs in sandbox-lies and three in a
shared-tier memory file. It then misread a cross-day comparison as possibly
spanning two versions. The transcript's `version` field showed the session and
every subagent on 2.1.281 throughout (16,720 entries, one value).

## Proposed mechanism

A `PostToolUse` hook on `Bash`:

- Fires when the command contains `claude --version` or `claude -v` as a
  command (match on the parsed command, not a substring of an argument).
- Reads the running version from the `version` field of the last entry in the
  payload's `transcript_path` (every transcript line checked carries it).
- Compares it with the version the command printed. **Silent when they
  match**, so it only speaks in the case that causes harm.
- On mismatch, adds `additionalContext`, e.g.: "`<printed>` is the installed
  binary; this session runs `<running>`. Stamp observations with the running
  version."

## Why not block

A `PreToolUse` block (a prohibitions-style hook) would false-positive on
legitimate uses: checking what an update installed, or comparing the two on
purpose. Annotating costs nothing when the versions agree.

## Open points for the implementing session

- Whether subagent transcripts carry the same `version` field as the main one
  (they did in the incident) and which `transcript_path` a subagent's hook
  receives.
- Whether an env var exposes the running version more cheaply than reading the
  transcript tail. Not verified; do not assume one exists.
