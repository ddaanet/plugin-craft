# T2 review — commit 494a8d6

Reviewed against `plan.md` (claims table, T2 contract, D1-D7), `brief.md`,
and the source fact `memory/ddaanet/classifier-no-verdict-plugin-dir.md`.
I loaded `craft:directive-writing` and `plugin-craft:skill-authoring`.

## Contract checks that pass

- Scope is the hard family only. Transient and one-retry texts are sent back
  to a single retry. A refusal with a reason gets no route (SKILL.md:162-165).
- The cause and the synced-copy remedy are stated, per D5 and the T2 text.
- The `python3`-under-`$TMPDIR` route is framed as reviewed, not a bypass,
  matching claim 10.
- The dispatcher sentence is present (SKILL.md:171-172).
- No heredoc is named (D4), and the text has no memory or plan citations.
- The description is 572 characters, under the 1,536 cap (D7). Both quoted
  fragments are verbatim substrings of the real tool result in the brief:
  `auto mode classifier gave no verdict` and `hard failure`.
- No existing line of SKILL.md was altered.

## Findings

### Medium

**M1 — the scope's own exclusion reads as covering the error it scopes in.**
`skills/verifying-plugin-changes/SKILL.md:164-165` says "A refusal that names
a reason is a denial, and no route around it is sanctioned." Every no-verdict
text carries a parenthetical reason: the real one says "(it skipped this
action)", and claim 2 says "the parenthetical names the reason". An agent
holding the hard-failure text can therefore read its own error as "names a
reason" and conclude the route is forbidden. The brief meant a judged denial
with a stated cause, the `classifier-denied-self-config` case.

Fix: "A denial, where the classifier judged the action and blocked it saying
why, is a different failure, and no route around it is sanctioned."

**M2 — the cause sentence asserts the inferred link as fact, and as universal.**
`SKILL.md:167-168` says "`--plugin-dir` marks the loaded directory's content
sensitive, so a `Write` there gets no verdict". D5 settled stating the
sensitivity (`checkPathSafetyForAutoEdit` returns `ask`). Claim 3, however,
says the link from that to the server's no-verdict "is inferred, not traced".
"so … gets no verdict" also reads as every Write. That contradicts the brief's
counter-evidence (two Writes under `.claude/` succeeded in the same checkout),
which P3 has not resolved.

Fix: keep the D5 clause and weaken the consequence: "`--plugin-dir` marks the
loaded directory's content sensitive, the likely source of a no-verdict on a
`Write` there; retrying gets the same answer."

### Low

**L1 — "synced copy" is undefined and its remedy is untested.**
`SKILL.md:168-169`. The term appears nowhere else in the skill, so the reader
cannot act on it. The skill's own name for that loading path is the
toolkit's dogfood launcher (SKILL.md:24-25). "Avoids it" is also untested,
since P3 compares a shim session with a plain one, not a synced copy. The
contract mandates the clause, so only the wording changes.

Fix: "Loading the plugin through the toolkit's dogfood launcher, which loads a
synced copy rather than the checkout, should avoid it."

**L2 — the route drops how the script reaches `$TMPDIR`.**
`SKILL.md:169-170`. The source fact said the Write tool reaches `$TMPDIR`
fine, and the brief observed it. Without that, an agent whose Write just
failed may distrust Write and create the script with a heredoc, the form D4
keeps out of the route.

Fix: "write the content from a `python3` script saved under `$TMPDIR` with
`Write` (outside the checkout, so it is not affected) and run it via Bash."

**L3 — the description has a doubled "or".**
`SKILL.md:3` reads "…or `/plugin update` changes nothing, or a file write
fails…".

Fix: drop the first "or": "…a command is missing or double-prefixed,
`/plugin update` changes nothing, or a file write fails with…".

**L4 — the closing pointer now hangs off the new section.**
`SKILL.md:174-175`, "For what a hook's stdout can do once it is the code you
meant to run…", was the document's closer for the reload sections. It now
follows the classifier section, where "once it is the code you meant to run"
does not follow.

Fix: move the two-line pointer up so it ends the `claude -c` section (after
line 158), leaving the classifier section last.

**L5 — the changelog attributes the plan's option to the brief.**
`docs/changelog.md:7` says "The brief offered a skill section or a
`PermissionDenied` hook". The brief offered "a hook, or a skill whose
description names the error string" and guessed `PostToolUseFailure`. The
plan (claims 4-5) identified `PermissionDenied` as the only observing event.

Fix: "The brief offered a hook or a skill description; the plan found
`PermissionDenied` to be the only hook event that observes it, and the
section won because…".

## Not flagged

- FR-5 (`docs/design.md:19`) is accurate and in style. The description does
  not repeat FR-5's `--plugin-dir` qualifier, but the section heading scopes
  it, and a broader trigger only costs a read.
- The plan's claim 12 and O3 still say the plugin has no hook, which
  FR-1/D-11 now contradict. That is stale plan text outside T2's diff and
  does not affect the shipped prose.

END OF REVIEW
