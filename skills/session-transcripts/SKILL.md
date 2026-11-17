---
name: session-transcripts
description: "Reading Claude Code session JSONL transcripts correctly: the structural flags to key on, where sub-agent transcripts live, how slash commands and skills are recorded, the guards a line-by-line reader needs, and how to find a transcript. Use when reading, filtering, counting or measuring a Claude Code session JSONL file (`~/.claude/projects/`), a sidechain or subagent transcript, a slash-command or skill-invocation record, or a hook reading `transcript_path` — especially when a count comes out 0%, a token reading is far too high, a command cannot be found by its text, or `jq` exits 5. Not for what a hook's stdout can do, which is `plugin-craft:hook-authoring`."
---

# Reading session transcripts

No authoritative schema exists for Claude Code session JSONL
(`~/.claude/projects/<project>/<session>.jsonl`): the official sessions doc
(`code.claude.com/docs/en/sessions.md`) calls the entry format internal and
version-unstable. Verified 2026-07-12, the best references are the
field-level community doc at `https://claude-dev.tools/docs/jsonl-format`
and the parser in `https://github.com/simonw/claude-code-transcripts`
(v0.6, Jan 2026); its code is the reference, its README documents usage only.

Two rules cover most of it. **Verify a shape against real local
transcripts before relying on it.** **Key filters on structural flags
(`isMeta`, `isSidechain`, `isCompactSummary`), never on content.**

## Symptom to cause

| Symptom | Cause | Do |
|---|---|---|
| `jq: error (at <stdin>:0): Cannot index number with "foo"`, exit 5, or `AttributeError` after `json.loads` | A line parsed to a scalar or array and passed the parse-failure filter | Guard on type after parsing: [references/reader-guards.md](references/reader-guards.md) |
| A `set -e` hook that reads the transcript dies on every call and the feature silently stops | Same: one such line in the read window kills the reader | Same file |
| Batching measured as 0%, or every message "has one tool call" | One assistant message is N `type:"assistant"` entries sharing `message.id`; per-entry counting sees one tool each | Group on `message.id` first: [references/entry-shapes.md](references/entry-shapes.md) |
| A token or context reading far above the live context, right after a compaction | The newest sample on disk is the previous API call's, taken before the boundary | Scope to entries newer than the last `isCompactSummary`: [references/entry-shapes.md](references/entry-shapes.md) |
| A slash command is not found by its literal text, and no `Skill` `tool_use` exists | It is logged as a `<command-name>` wrapper string; only agent-invoked skills are `Skill` `tool_use` | [references/entry-shapes.md](references/entry-shapes.md) |
| A filter on `Base directory for this skill:` misses skill bodies | That preamble is on only some skills; bodies are `isMeta:true` entries | Filter on `isMeta`: [references/entry-shapes.md](references/entry-shapes.md) |
| `/compact` appears posted twice | A built-in local command records two entries per submission | [references/entry-shapes.md](references/entry-shapes.md) |
| A sub-agent's usage or tool calls are missing from the transcript, or a `select(.isSidechain != true)` seems needed | Sub-agents live in sibling files; the main file carries no sidechain entries | [references/locating.md](references/locating.md) |
| A transcript is not found by mangling the project path | The mangling rule is reverse-engineered with an un-derived branch; the session id is unambiguous | Search by `<session-id>.jsonl`: [references/locating.md](references/locating.md) |
| A `jq` slice cuts mid-character, or an `index()` offset matches nothing | `index()` counts bytes on a string; slicing and `length` count codepoints | Take the offset from `split($sub)[0] \| length`: [references/reader-guards.md](references/reader-guards.md) |

## Where each node applies

- Choosing what to filter or count on: `references/entry-shapes.md`.
- Finding a main, sub-agent or archived transcript: `references/locating.md`.
- Writing the loop that reads lines: `references/reader-guards.md`.

A hook that reads `transcript_path` for context size is also in
`../hook-authoring/references/input-and-harness.md`, which covers the
`message.usage` fields and the subagent `transcript_path` quirk. A
session title is recorded as a `custom-title` entry, covered with the hook
output channels in `../hook-authoring/references/output-channels.md`.
