# Probes for the classifier no-verdict plan

## P1 — is `PermissionDenied` `additionalContext` delivered? No.

2026-10-27, CC 2.1.311, headless, my human partner's go-ahead.

Fixture under `/tmp/claude/p1`: a minimal plugin (`plug/.claude-plugin/plugin.json`
only) and a `PermissionDenied` hook, matcher `""`, registered through
`--settings`. The hook appended its stdin to a log and printed:

```json
{"hookSpecificOutput":{"hookEventName":"PermissionDenied","additionalContext":"P1-MARKER-7731: the PermissionDenied hook spoke."}}
```

Run from `plug/`:
`claude -p --permission-mode auto --plugin-dir /tmp/claude/p1/plug --settings <hook>`,
asking for one `Write` to `plug/notes/a.md` and a verbatim report of any
context received after it.

- The `Write` got the hard-failure text: `The server-side auto mode classifier
  gave no verdict (it skipped this action), so auto mode cannot determine the
  safety of Write. This is a hard failure, not a transient one: ...`
- The hook fired; its log holds the payload below.
- The model reported no context after the call, and the marker string occurs
  nowhere in the session transcript. The transcript's hook attachments are the
  `SessionStart` and `Stop` hooks only, so the `PermissionDenied` output was
  dropped rather than rendered.

**Result:** the hook observes the denial but cannot speak to the model through
`additionalContext`. O3 and O4 cannot carry the route; D1 stays O1.

## P2 — the payload of a real no-verdict Write (by-product of P1)

```json
{"session_id":"82a0e38e-ffc3-4f46-8ae9-facc01e0ec34","transcript_path":"…","cwd":"/tmp/claude/p1/plug","prompt_id":"…","permission_mode":"auto","effort":{"level":"high"},"hook_event_name":"PermissionDenied","tool_name":"Write","tool_input":{"file_path":"/tmp/claude/p1/plug/notes/a.md","content":"hello\n"},"tool_use_id":"toolu_01LLtnQGC5oKegLGAFZtsgYQ","reason":"Classifier unavailable"}
```

`reason` is `Classifier unavailable`, not the text the model sees. A hook
matching the hard-failure text in `reason`, as O3 specified, would never fire.

## P3 side observation

A `Write` under a directory loaded with `--plugin-dir`, with no `.claude`
path segment, got the hard no-verdict on the first attempt. One run; the
plain-session comparison P3 asks for was not made.

Not run: P3 proper, P4, P5.

## P6 — does the dogfood load avoid it? Yes; and P3 proper

2026-10-27, CC 2.1.311 (the installed binary, called directly, bypassing the
gitlore shim), headless, my human partner's go-ahead.

Fixture under `/tmp/claude/p6`: `plug/` and `copy/`, each a bare
`.claude-plugin/plugin.json`. Every run started in `plug/` with
`claude -p --permission-mode auto` and asked for one `Write` to
`plug/notes/<arm>-<n>.md`, no retry, then the tool result verbatim. Two runs
per arm, all six in parallel:

| Arm | Load | Result |
| --- | --- | --- |
| `dir` | `--plugin-dir plug` | hard no-verdict, both runs |
| `env` | `CLAUDE_CODE_PLUGIN_DIRS=copy`, as the toolkit shim sets it | written, both runs |
| `plain` | no plugin | written, both runs |

**Result:** the failure follows `--plugin-dir` naming the directory written
into. Loading a copy through `CLAUDE_CODE_PLUGIN_DIRS`, as the dogfood shim
does, leaves the checkout writable, and so does a plain session; this is the
comparison P3 asked for. The skill's cause and its dogfood claim stand.
Not tested: `CLAUDE_CODE_PLUGIN_DIRS` naming the checkout itself.

Still not run: P4, P5.

## P4 and P5 — Edit fails like Write; a Bash heredoc writes

2026-10-28, CC 2.1.312 (the installed binary, called directly), headless, my
human partner's go-ahead.

Fixture under `/tmp/claude/p7`: `plug/`, a bare `.claude-plugin/plugin.json`.
Every run started in `plug/` with
`claude -p --permission-mode auto --plugin-dir /tmp/claude/p7/plug` and asked
for one call into `plug/notes/`, no retry, then the tool result verbatim. Two
runs per arm, all eight in parallel:

| Arm | Call | Result |
| --- | --- | --- |
| `write` (control) | `Write` a new file | hard no-verdict, both runs |
| `edit` | `Edit` an existing file | hard no-verdict, both runs; file unchanged |
| `nbedit` | `NotebookEdit` a cell | not run: the tool was on my human partner's deny list |
| `heredoc` | Bash `cat > notes/h.md <<'X'` | written, both runs |

The user settings enable the sandbox with `autoAllowBashIfSandboxed`, which
could let the heredoc skip the classifier altogether. Two more heredoc runs
passed `--settings '{"sandbox":{"enabled":false}}'`: written, both runs. That
the override did turn the sandbox off was not checked independently.

**Result:** the hard failure covers `Edit` as well as `Write`. A Bash heredoc
writes into the `--plugin-dir` directory in the same session, so P5 passes
and the plan's invariant no longer keeps the heredoc out of the skill.

2026-10-29, same version and fixture, after my human partner lifted the
deny-list entry: two `NotebookEdit` runs, each after a `Read` of the notebook
(without it the tool refuses before the classifier, `File has not been read
yet`). Hard no-verdict, both runs; the cell is unchanged. The failure covers
all three file-write tools.
