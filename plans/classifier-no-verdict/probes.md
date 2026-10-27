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
