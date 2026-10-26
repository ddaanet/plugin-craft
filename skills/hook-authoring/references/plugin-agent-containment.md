# Containing a plugin's own agents

A plugin that ships an agent whose safety depends on a hook cannot attach the
hook to the agent. This node covers why, the route that remains, and how a
session-wide hook guarding those agents fails: open until it knows the caller,
closed after.

## 1 · A plugin agent's frontmatter `hooks:` is dropped

The loader discards `hooks:` from an agent definition under a plugin's
`agents/` directory and says so only at WARN on the debug channel
(`claude --debug`, log under `~/.claude/debug/<session>.txt`):

```
Plugin agent file <path>/agents/<name>.md sets hooks, which is ignored for plugin agents. Use .claude/agents/ for this level of control.
```

Nothing else signals it. The agent is found and dispatched as
`<plugin>:<agent>`, the subagent's `.meta.json` shows
`agentType: "<plugin>:<agent>"` with no `customAgentType`, and every check that
catches the two silent gates of a `.claude/agents/` definition passes. The
plugin source being exempt from the workspace-trust check is a separate matter:
the exemption never gets a chance to apply.

Verified on **CC 2.1.296** (2026-10-13, plugin loaded through
`CLAUDE_CODE_PLUGIN_DIRS`, run twice) and re-probed on **CC 2.1.310**
(2026-10-26, `--plugin-dir`): a tripwire dispatch ran a command the frontmatter
`PreToolUse` Bash hook exists to block, the subagent's tool result shows the
command output, and the hook script never started. Not established: whether a
marketplace-installed plugin behaves the same (expected, the warning names
plugin agents generally), and whether `mcpServers` and `permissionMode` in
plugin-agent frontmatter are dropped the same way.

## 2 · The two routes

- **A plugin-level `hooks/hooks.json`** whose script reads the payload's
  `agent_type` and acts only for the plugin's own agents. Inside a plugin
  agent the value is `"<plugin>:<agent>"` (CC 2.1.296 and 2.1.310). The main
  thread's payloads carry no `agent_type` (2.1.310: the main thread's `Agent`
  dispatch logged none; the subagent's `Bash` call and its final handback call
  logged `probe-plugin:probe-agent`). `PreToolUse` and `SubagentStart` carry it
  plus an `agent_id`. A dispatch `name` leaves the value alone (the
  `.meta.json` keeps `agentType` and gains a separate `name` key), so this
  route does not inherit the named-dispatch gate of the other. An exit 2 gated
  on the value denies the call inside the agent (tool result `PreToolUse:Bash
  hook error: … This hook comes from the <plugin> plugin.`) while the same
  command on the main thread runs. The hook process gets `CLAUDE_PLUGIN_ROOT`
  and `CLAUDE_PROJECT_DIR`.
  **Cost:** the hook runs on every matching tool call of every session that
  enables the plugin, one process each, so it is a tax on sessions that never
  dispatch the agent (§3).
- **Definitions installed into the consumer's `.claude/agents/`**, where
  frontmatter hooks attach. **Cost:** the plugin cannot deliver them on its
  own; something must copy them into each consumer project, and both silent
  gates of that location apply: the exact-path workspace-trust key and the rule
  that a dispatch `name` disables the hooks.

Either way, only a tripwire (§5) proves containment.

## 3 · Fail open until the caller is identified, closed after

A session-wide hook that guards the plugin's agents splits its failures by who
is calling.

| Failure | Identified agent | Any other caller |
| --- | --- | --- |
| Payload does not parse; `agent_type` absent, not a string or not the hook's agent | n/a: not identified | exit 0, silent |
| Interpreter missing, killed (OOM), or exits other than 0 or 2; module missing or unreadable (test readability first: python3 exits 2 on a script it cannot open, which reads as a block) | exit 2, reason on stderr | exit 0, silent |
| Interpreter killed by a signal | exit 2 | exit 1 and one stderr line: a visible hook error that blocks nothing |
| `tool_input` missing or mistyped, no project directory, any exception in the module | exit 2, reason on stderr | not reached |
| Interpreter exits 0 or 2 | its own answer | its own answer |

**Failing closed everywhere was tried and rejected.** An `ERR` trap turning any
hook failure into exit 2 refused Bash, Read, Write and Edit in every session
with the plugin enabled on a machine missing a dependency, including sessions
that never dispatch the agents. Narrowing the block to identified agents does
not bring that back: only those agents stop. Blocking when the hook cannot
identify the caller is the same brick, and so is searching the raw payload for
the agent name when it does not parse, which blocks the main thread whenever a
command or an edit merely contains the string.

**Precondition:** nothing after identification may depend on an external tool.
Put the logic in one stdlib-only module run from the plugin's own tree
(`python3 -I`, so `PYTHONPATH` and the module's directory stay off `sys.path`),
found from the wrapper's own location.

## 4 · Identify the caller before anything that can die

Identifying only inside the module is not enough. A wrapper that passes
through every status but 0 and 2 lets an interpreter killed mid-check wave an
agent's call through with no trace, because nothing outside the module knew
whose call it was. So the shell wrapper identifies the caller itself, first,
with builtins only (PATH may hold nothing else): a bash regex test on the raw
payload for the structural key,

- `"agent_type"`, optional whitespace, `:`, optional whitespace, then the
  quoted `<plugin>:<agent>` alternatives.

Then run the interpreter without `exec` so its status can be read, and map
statuses per §3. A bash prefilter that starts the interpreter only when the
regex matches is a bypass, because JSON lets a payload spell the name with
escapes; the regex only picks fail-closed over fail-open when the interpreter
cannot answer, and a miss on an escaped spelling falls back to the fail-open
the interpreter's own decision would have overridden.

**No false positive:** `JSON.stringify` escapes every `"` inside a string as
`\"`, so a quoted `"agent_type"` followed by `:` can only be a structural key.
A string whose content is `agent_type` is followed by `,`, `}` or `]`, and the
Bash, Read, Write and Edit `tool_input` objects have fixed string-valued keys,
so no nested key arises. The argument depends on Claude Code serializing the
payload with `JSON.stringify` (non-ASCII left unescaped, `"` always escaped).

**Reading the payload.** `payload=$(</dev/stdin)` is a bash builtin read: fast,
drops only trailing newlines (insignificant after JSON). `read -r -d ''` reads a
pipe one byte per syscall: 3.3 s for 2 MB, paid on every matching call. But
measured 2026-10-26 on Linux (CC 2.1.310) the hook's stdin is a socket, and
`$(</dev/stdin)` fails there: `/dev/stdin: No such device or address`, status
1, empty payload. `$(cat)` and `read -r -d ''` read it. macOS is not measured.
A failed read leaves the payload empty, which reads as an unidentified caller:
every call passes, the agent's included. Check the read's status, and run the
wrapper's test with a socket on stdin rather than a pipe or a here-string.

## 5 · Make the open state visible

What still fails open is made visible from two sides.

**A `SessionStart` self-check** runs the hook's real checks, not `command -v`.
Per hook it sends one identified call that must be allowed (exit 0) and one
identified call that must be blocked (exit 2). A payload naming no agent
returns before any check runs, so it passes a broken interpreter; allow probes
alone leave a hook that allows everything unseen, and the must-block probe
catches it. Use fixed probe payloads and a fixed project directory that need
not exist, so the result does not depend on the session. On a wrong status,
report on **both** channels: `systemMessage` for the user and
`additionalContext` for the agent, telling it not to dispatch the contained
agents. Fire it on startup, resume, clear and compact alike — after `/clear` or
`/compact` the agent's copy of the warning is gone. The script builds its JSON
with `printf` when it cannot rely on another tool being present.

**An agent-opening tripwire:** each contained agent opens with two calls that
must both be blocked, a Bash `echo` and a Read of a known file. The Bash call
alone cannot show that a file-tool hook did not load; if either goes through,
the agent stops and reports itself uncontained.

**A test that the hook paths resolve proves nothing about containment.** A
plugin agent whose frontmatter paths all resolve is still uncontained (§1).

## 6 · Probing it

Dispatch the agent with a tripwire command, and read the tool result in the
subagent's transcript, not the agent's account of it. The tripwire must be one
the session's permission rules would allow: pre-allow it (`claude -p
--allowedTools 'Bash(<tripwire>)'` and the Agent tool), because a permission
denial is indistinguishable from a hook block in the agent's report. Pair it
with one command that must be allowed. For the value of `agent_type`, log it
from a plugin-level hook and read the log, one line per call, `absent` for a
payload without the key.

The version belongs beside every observation here: this is product behaviour.
Take it from the `version` field of the session transcript; `claude --version`
reports the installed binary, which may not be the one that ran.
