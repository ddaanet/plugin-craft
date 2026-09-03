## Brief: additionalContext survives a PreToolUse deny — fold into the hook-authoring skill

2026-09-02

Companion to `brief-plugin-craft-seed.md`. That brief routes
`hook-output-channels` §1–6 into the hook-authoring skill. This one carries a
finding verified *after* it was written, so the section the skill inherits is
incomplete as it stands in the tier.

### The finding

`hookSpecificOutput.additionalContext` is delivered on a `PreToolUse` **deny**,
not only when a tool call is allowed and then fails.

The distinction matters because the tier's §2 only ever claimed the weaker
thing — "delivered even when the tool call then fails" — and a call the hook
blocks never runs, so it is not a call that failed. Anyone building a deny
around the field had to guess.

Verified against **CC 2.1.258**, with a scratch `--settings` hook under a nested
`claude --print`. What the three channels do on a deny:

- **`permissionDecisionReason`** becomes the `tool_result` content, with
  `is_error: true`. This is what renders beside the intercepted call.
- **`additionalContext`** lands as a separate transcript entry of
  `"type": "attachment"`, whose `attachment.type` is `hook_additional_context`,
  carrying `hookName`, `hookEvent`, and the **`toolUseID` of the denied call**.
  It is not echoed to the user.
- **`systemMessage`** surfaces as a `type: "system"`, `subtype:
  "informational"` event rendered `PreToolUse:<Tool> says: <text>`.

The receiving agent reported both the deny reason and the injected context, so
delivery is real rather than merely present in the transcript.

### Decisions

- **A deny splits three ways by audience, not two.** Verdict on
  `permissionDecisionReason`; recovery — the form the action should take
  instead — on `additionalContext`; one curt lowercase line on `systemMessage`.
  The skill should teach this as the default shape for a guard hook.
- **The recovery does not belong on the deny reason.** Putting it there means
  the instructional prose renders beside every block: noise for the human, and
  no better targeted for the agent, which reads both channels either way.
- **Version-stamp the claim in the skill body.** The failure mode is silent — a
  future CC that stopped delivering `additionalContext` on a deny would leave
  the guard working and only the teaching gone, which looks like nothing.
  State the probe so a reader can re-run it rather than trusting the date.

### Constraints

- The probe needs an unsandboxed nested `claude`; a sandboxed `claude -p`
  silently drops SessionStart hooks and is not a trustworthy harness for this.
- Reproducing it means reading the session transcript JSONL, not the
  `--output-format stream-json` stream: the attachment does not appear as its
  own event in the stream, only in the on-disk transcript.

### Rejected approaches

- **`exit 2` + stderr for the deny.** It blocks, but carries no `ask`
  capability and no `systemMessage`, so a human-facing line distinct from the
  agent-facing reason is unavailable. Uniform stdout JSON + exit 0 keeps every
  script the same shape regardless of decision.
- **Assuming the tier's existing sentence covered it.** It did not, and the gap
  was invisible: a hook written on the assumption would have worked, with its
  teaching silently dropped.

### Additional context

The worked example is `deny-ask-user-question.sh` in the `prohibitions` plugin,
rebuilt on this split: the deny reason reduced to `AskUserQuestion is refused
unconditionally.`, the inline-questions recovery moved to `additionalContext`,
and `systemMessage` rewritten to the curt lowercase house style. Its test
asserts the split in both directions — recovery present in `additionalContext`,
absent from the deny reason — and was red-checked by dropping the field from
the emitted JSON. That repo's `docs/design.md` carries the rationale under
*A deny splits three ways by audience*.

The same content is in the tier at `memory/ddaanet/hook-output-channels.md` §2
and in its index line ("honoured at PreToolUse and on a deny too"). When the
skill lands here, that is a section retiring from the tier with the rest of
§1–6, not a second copy to keep in sync.

An agent-facing deny still takes the §7 wording rule, which stays in the tier
under the seed brief's split: no actionable phrases, since the agent treats
"if you really need X, run Y" as authorisation.
