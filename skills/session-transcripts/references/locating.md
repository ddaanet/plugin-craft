# Locating transcripts: layout, sub-agents, project directory

Open when a transcript, or the sub-agent's half of one, cannot be found.

## Sub-agents are sibling files

As of CC 2.1.222, a main session JSONL never carries `"isSidechain":true`:
the field is present on every entry and uniformly `false`. Sub-agent
transcripts live at

```
~/.claude/projects/<encoded-project>/<session-id>/subagents/agent-<agent_id>.jsonl
```

each beside an `agent-<agent_id>.meta.json`, in a session directory that also
holds `tool-results/`. Every entry in them is `isSidechain:true`. `archived/`
is not a sub-agent location: it holds retired whole sessions, each a
`<session-id>.jsonl` plus its own `<session-id>/subagents/`, the same shape
one level down.

A reader handed `transcript_path` sees the main file alone, and a sub-agent's
`message.usage` sits in a sibling directory that nothing appends from. A
`select(.isSidechain != true)` guard on such a reader is code for a case the
layout makes impossible, so leave it out. Inside a sub-agent, `transcript_path`
points at the parent; see
`../../hook-authoring/references/input-and-harness.md`.

Treat the segregation as an invariant of the current layout, not a permanent
one, and re-verify by disjointness rather than by the flag: collect the
`message.id`s carrying `message.usage` from the main transcript and from its
`subagents/*.jsonl`; the two sets must not intersect. The flag alone would
still read clean if a later release merged the files under a different marker.

## Finding a transcript: search by session id

A transcript lives at `~/.claude/projects/<mangled>/<session-id>.jsonl`.
Session ids are uuids, so the basename alone is unambiguous across every
project directory:

```sh
find "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" -name "$session_id.jsonl" -type f -print -quit
```

That is one filesystem walk, against a rule that is reverse-engineered, has an
un-derived branch, and would be a second place to get wrong. Reach for the
mangling only when there is a path and no id.

## The directory-name rule

Claude Code derives the per-project directory name by mangling the absolute
path. Undocumented officially; verified against the bundled JS in the
`claude` binary (`~/.local/share/claude/versions/*`) and against real
`~/.claude/projects/` entries. Public references: anthropics/claude-code issues
#19972 (proposed reverse-engineering) and #7009 (collision report, closed
not-planned). Treat the rule as stable but reverse-engineered.

1. `realpath()`, then Unicode NFC normalize.
2. Replace every byte not in `[A-Za-z0-9]` with `-`. A leading `/` becomes a
   leading `-`; `.`, `_`, spaces and non-ASCII all become `-`. Case is
   preserved. Consecutive specials accumulate: `/.foo` becomes `--foo`.
3. If the result exceeds 200 characters, truncate to 200 and append
   `-<base36(abs(hash(path)))>`. The hash is not visible from strings in the
   bundle, and no path tried has reached this branch (not probed).

Verified examples: `/Users/me/code/proj` becomes `-Users-me-code-proj`;
`/Users/me/.claude` becomes `-Users-me--claude`;
`/Users/me/code/x/.test-install-XXXX` becomes
`-Users-me-code-x--test-install-XXXX`.

A shell one-liner matching the common case (not the over-200 fallback):

```sh
printf '%s' "$abs_path" | LC_ALL=C sed 's/[^A-Za-z0-9]/-/g'
```

A hand-rolled `rstrip("/").replace("/", "-")` is incomplete: it misses any
directory whose path held `.`, `_`, a space or another non-alphanumeric.
