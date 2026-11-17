# Entry shapes: messages, compaction, commands and skills

Open when deciding what to key a filter or a count on.

## One assistant message spans several entries

A turn issuing N parallel tool calls is written as N `type:"assistant"`
entries sharing a `message.id`, each carrying one `tool_use` block. Any
question about what the model did *in one message* (did it batch these two
writes, how many tools in this call) must group on `message.id` first.
Counting per entry makes every message look like a single tool call and
silently reports 0% batching. Measured 2026-07-26 against 2400 transcripts,
per-entry counting said "never batched" where grouping said 43%.

Each of those entries repeats the same `usage`; taking the last one rather
than summing is in `../../hook-authoring/references/input-and-harness.md`.

## Compaction

Compaction appends in the same file and session id: a
`type:"system", subtype:"compact_boundary"` entry, then the summary as a
`type:"user"` entry with `isCompactSummary: true` (no `isMeta`).

A hook reading `usage` from the transcript sees the **previous** API call's
sample: the assistant entry carrying the current call's `usage` is not
flushed when `PostToolUse` or `PostToolBatch` fires, so the newest sample on
disk is one call behind. That is harmless while a prompt grows monotonically
(a few thousand tokens against any sane threshold) and wrong across a
compaction, where the sample above the boundary measures the context just
discarded and, being the last before it, is the largest of the session.
Verified 2026-08-09: a hook read 197354 against a live context of 87253, on
the first tool batch after a compaction.

So scope any transcript measurement to entries newer than the last
`isCompactSummary`, and when nothing is newer report nothing rather than
falling back: between a compaction and its first API call there is no sample
to read. This applies to any per-call metric taken this way, not only
context size.

## Slash commands are wrapper strings, skills are tool calls

A slash command such as `/handoff:handoff` is recorded as a `type:"user"`
entry whose `message.content` is a **string** holding wrapper tags:

```
<command-name>/handoff:handoff</command-name>
<command-message>handoff:handoff</command-message>
<command-args>…</command-args>
```

The leading slash is present in `<command-name>`. It is not stored as the
literal text `/handoff:handoff`, and the slash path emits no `Skill`
`tool_use`. Search for the `<command-name>` string.

An agent-invoked skill is the opposite: an assistant `tool_use` block,
`{"type":"tool_use","name":"Skill","input":{"skill":"handoff:handoff"}}`.
Detecting "this skill ran" therefore needs both checks, the `Skill`
`tool_use` and the `<command-name>` string.

## Skill bodies are `isMeta:true` entries

On both paths the body is injected as an `isMeta:true` user entry: via the
`Skill` tool (the body entry also carries `sourceToolUseID`) and via the
slash path (no `sourceToolUseID`). The body is a `content:[{type:text,…}]`
block. It starts with the skill's own first line (for example
`# Update Config Skill`), and only some skills open with `Base directory for
this skill:`, so a text-prefix filter misses native skill bodies. A native
body can exceed 100 KB.

`isMeta:true` is the robust flag for all harness-injected non-conversation
content: skill bodies, `<local-command-caveat>`, and `## Context` or
`## Context Usage` injections. Genuine user prompts never carry it. Verified
across 20+ real transcripts 2026-05-23.

## `/compact` records twice

Built-in local commands double-record. `/compact` (verified in 5 invocations
across 4 sessions, 2026-07-17 to 07-20, typed by hand and by a watcher alike)
logs both a plain `type:"user"` entry whose content is the literal command
line and the `<command-name>` wrapper record, about 15 to 60 ms apart under
different `promptId`s. It is one submission with two records, both rendered,
which reads as "posted twice". Count one of them, or dedupe on the pair.

Queued input has its own entries: `type:"queue-operation"`
(`enqueue`/`dequeue`, with content) and `promptSource:"queued"` on the
eventual prompt. That is the authoritative signal that a submission landed
while the session was busy or finalizing.
