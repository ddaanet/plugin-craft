# Review — the four plugin-craft skills

Reviewed against `plans/plugin-craft-seed/inline-plan.md` (per-skill sections S1–S4
and *Constraints*), the eight memory sources under `memory/ddaanet/`, the companion
brief `brief-additionalcontext-survives-deny.md`, and the vendored
`plugin-dev/README.md`.

Files reviewed:

- `skills/hook-authoring/SKILL.md` (7,234 B — under the plan's 8 KB target)
- `skills/hook-authoring/references/output-channels.md` (8,819 B)
- `skills/hook-authoring/references/input-and-harness.md` (10,549 B)
- `skills/skill-authoring/SKILL.md` (9,668 B)
- `skills/verifying-plugin-changes/SKILL.md` (8,841 B)
- `skills/toolkit-release/SKILL.md` (3,426 B)

`bash scripts/check-skill-text.sh` is green: no wikilink, no `memory/` path, no bare
source-fact filename anywhere under `skills/`. The two critical findings below are
dangling identifiers of a class that script does **not** cover.

Coverage against the plan is complete: every S1–S4 section, every mandated date
stamp (2026-06-10, 2026-06-12, 2026-07-12, 2026-07-17, 2026-07-22 / 2.1.217,
2026-07-24, 2026-07-26, 2026-07-31, 2026-08-27, CC 2.1.250, CC 2.1.258) and all
twelve link resolutions from the constraint table are present and applied as
specified. No situational state (memory-store byte counts, index-cap arithmetic)
survived. Findings below are defects within that, not omissions of it.

---

## Critical

### C1 · `output-channels.md:88` — `FR5a/FR5c` is an unresolvable internal id

```
`unsandbox-git-status` (retired 2026-08-26, confirmed live with
`true && git status --porcelain` running unchecked) and `cwd-safety` (FR5a/FR5c
restore rewrite, fixed 2026-08-28).
```

`FR5a`/`FR5c` are requirement ids in another repository's spec. This is the exact
class the plan's *Withhold, don't forbid* constraint and the review's criterion 3
name; the enforcement script cannot see it because it is not a wikilink, a
`memory/` path or a fact filename.

**Fix:** drop the ids, keep the evidence — `` and `cwd-safety` (its `cd`-restore
rewrite, fixed 2026-08-28) ``.

### C2 · `verifying-plugin-changes/SKILL.md:48` — `Plan 04 Step 6` is an unresolvable internal id

```
Signature — discovered closing **Plan 04 Step 6** (2026-05-24): a marketplace
session was about to "verify" the **memory-merger** two-turn flow, ...
```

`Plan 04 Step 6` names a plan document in another repository. The date carries the
grounding on its own.

**Fix:** `Signature — observed 2026-05-24: a marketplace session was about to
"verify" a two-turn agent flow, but still had ...`. Dropping `memory-merger` at the
same time is optional (it is a public gitlore agent name) but costs nothing.

---

## Major

### M1 · `verifying-plugin-changes/SKILL.md:70` vs `:141-144` — the two sections contradict each other on skill bodies

Section *Skill bodies are snapshotted at session start* says:

> **Fix for a skill body: `/reload-plugins`** — no restart needed.

Section *`claude -c` is a full restart* says:

> So the remedy for **any** frozen-at-start staleness — hook event registration,
> **skill bodies**, agent definitions, a version-pinned `CLAUDE_PLUGIN_ROOT`,
> anything derived from it — is **exit and relaunch with `claude -c`**, not a cold
> session and not `/plugin` + `/reload-plugins`, neither of which re-fires
> `SessionStart`.

A reader who lands in the second section is told `/reload-plugins` does not fix skill
bodies; a reader in the first is told it does, with a dated observation. This is
inherited verbatim from the source fact, but the source could rely on a reader
holding both halves — a shipped skill cannot.

**Fix:** scope the `claude -c` list to what `/reload-plugins` does not cover, e.g.
"…for any frozen-at-start staleness `/reload-plugins` does not clear — hook event
registration, agent definitions, a version-pinned `CLAUDE_PLUGIN_ROOT`, anything
derived from it — the remedy is…", and add "(skill bodies are the exception: see
above)".

### M2 · `skill-authoring/SKILL.md:28-29` — `See plugin-craft:toolkit-release.` points at an unrelated skill

```
Applies to all skills in a plugin, not just the headline one. See
`plugin-craft:toolkit-release`.
```

The source's pointer here was `[[claude-plugin-dev]]`, and it was reaching for that
fact's *release-infrastructure* content, not for anything about descriptions.
`toolkit-release` is scoped to five release failure modes and says nothing about
description shape, so a reader who follows this finds nothing. This link is also not
in the plan's resolution table — it was resolved by mechanical slug→skill
substitution rather than by the table.

**Fix:** delete the sentence. Nothing in `toolkit-release` supports the claim it is
attached to.

### M3 · `hook-authoring/SKILL.md:105-107` — the per-event line contradicts §2's three-way split

```
Per event: `UserPromptSubmit` → `additionalContext`. `PreToolUse` →
`additionalContext` or `permissionDecisionReason` (on deny); stderr + exit 2 also
surfaces.
```

§2 is the section the companion brief exists to add, and its whole teaching is "a
deny splits three ways by audience, **not two**" — emit all three fields. The `or`
in §3 tells the reader to pick one, which is the shape §2 argues against. Inherited
from the source's §6, written before the §2 finding existed.

**Fix:** `` `PreToolUse` → `additionalContext` **and** `permissionDecisionReason` on
a deny (§2), plus `systemMessage` for the human; stderr + exit 2 also surfaces. ``

### M4 · `skill-authoring/SKILL.md:3` and `verifying-plugin-changes/SKILL.md:3` compete on "a skill is not firing"

`skill-authoring`'s description says:

> Use when writing or revising a skill, a plugin command or its frontmatter, or when
> **a skill exists but is not firing**.

`verifying-plugin-changes` covers *Skill bodies are snapshotted at session start* —
i.e. the most common concrete reason a just-edited skill does not fire. Both
descriptions claim the same moment, and neither disambiguates. The likelier reading
of "not firing" (edited and no effect) belongs to `verifying-plugin-changes`, which
is the one that will lose the match because its own trigger clause is more abstract
(see M6).

**Fix:** narrow `skill-authoring` to the description-matching case and hand the other
off explicitly — "…or when a skill's description is not matching the moments it
should. For a skill whose edited body is not the one loading, see
`plugin-craft:verifying-plugin-changes`."

### M5 · `skill-authoring/SKILL.md:3` — "Complements `plugin-dev:skill-development`." states no delta, and the two collide head-on

`plugin-dev:skill-development`'s own description triggers on "create a skill", "add a
skill to plugin", "write a new skill", **"improve skill description"**, "organize
skill content". `skill-authoring`'s §1 is entirely about improving skill
descriptions, and its "Use when" clause is "writing or revising a skill". The bare
"Complements X" gives the model nothing to route on. `hook-authoring` gets this right
("Complements `plugin-dev:hook-development`, **which covers configuration and the
event basics; this covers the payload fields and channel behaviour it omits**") —
apply the same shape here.

**Fix:** "Complements `plugin-dev:skill-development`, which covers structure and
progressive disclosure; this covers description shape and cost, what `allowed-tools`
actually does, and how a bundled script is reached."

### M6 · `verifying-plugin-changes/SKILL.md:3` — the description will under-fire on the symptom it exists for

The trigger is a symptom with no keyword, so the description's "Use when" clause has
to supply the vocabulary itself. It currently offers one abstract phrasing:

> Use when a plugin change appears to have no effect and nothing errors, …

The words a session actually contains at that moment are concrete and none of them
appear: *the hook did not fire*, *the skill still injects the old body*, *the command
is not found*, *`/plugin update` did nothing*, *`/gitlore:gitlore:x`*. Judged against
the symptom, the description fires on a paraphrase of itself rather than on the
observation. It is also the description most likely to be beaten to the match by M4
and by `plugin-dev:hook-development`.

**Fix:** replace the abstract clause with the symptom set, keeping the length:

> Use when an edited hook does not fire, a skill injects its pre-edit body, a command
> is missing or double-prefixed, or `/plugin update` changes nothing — and before
> trusting any verification of an edit to plugin code.

The "and nothing errors" signal is worth keeping somewhere; folding it into the
opening purpose clause costs less than a fourth "use when" item.

### M7 · `skill-authoring/SKILL.md:149-152` and `output-channels.md:86-90` present `cwd-safety` as both the model and the cautionary tale

`skill-authoring` offers it as the pattern to copy:

> **`PreToolUse(Bash)` + `updatedInput`**, which *does* work on the Bash tool
> (cwd-safety uses it to wrap commands in a subshell) … The root is resolved fresh at
> call time, which is what makes this the safe one.

`output-channels.md` names the same plugin as one of the two that shipped the
`allow` + `updatedInput` permission bypass. Both statements are true — the safe
transport is `updatedInput` *alone* — but a reader meeting them in either order gets
no signal that the distinction is what separates them, and the recommendation carries
no warning against adding `permissionDecision: "allow"` to the rewrite it proposes.

**Fix:** in `skill-authoring`, append the constraint and the pointer: "Emit
`updatedInput` on its own — pairing it with `permissionDecision: "allow"` pre-approves
the tail the hook never inspected; see `plugin-craft:hook-authoring`." Optionally drop
the bare `cwd-safety` attribution, which a consumer cannot open either way.

### M8 · `output-channels.md:5-8` — the `systemMessage` bullet scopes the field to one plugin's events, and is now contradicted by `SKILL.md` §2

```
- **`systemMessage`** (top-level field) — the user-visible channel. Works for the
  events `gitlore` uses (`SessionStart`, `PostToolUse`); its `SessionStart`
  launcher-guard warning rides it.
```

Two problems. A consumer cannot tell from this whether `systemMessage` works on any
other event — the claim is framed as an evidence scope but reads as a capability
limit. And `SKILL.md`'s §2, verified later against CC 2.1.258, documents
`systemMessage` rendering on **`PreToolUse`** (`PreToolUse:<Tool> says: <text>`),
which this bullet's list excludes.

**Fix:** "the user-visible channel, and the field for anything the human should see.
Verified on `SessionStart`, `PostToolUse` and `PreToolUse` (the last as
`PreToolUse:<Tool> says: <text>` — see `SKILL.md` §2)." Drop the launcher-guard
clause, which is attribution to a repo the reader does not have.

### M9 · `hook-authoring/SKILL.md:63` — an authoring instruction leaked into the shipped body

```
Version-stamp this claim rather than trust the date, and re-run the probe: the
failure mode is silent — …
```

"Version-stamp this claim" is a directive from the plan to the *author*; the claim is
already stamped (`CC 2.1.258`, line 42). Addressed to the reader it is a no-op
instruction, and it displaces the one act the reader should take, which is re-running
the probe.

**Fix:** "The stamp is a version rather than a date on purpose, and the probe is worth
re-running before relying on this: the failure mode is silent — …"

---

## Minor

### m1 · `hook-authoring/SKILL.md:28` — `(§2)` is ambiguous across the file split

`SKILL.md` numbers its sections 1–4 and `references/output-channels.md` numbers its
own 1–4. Line 28's `(§2)` resolves correctly *inside* `SKILL.md` (its §2 is the deny
section), but the sentence is about channel delivery, which is what the reference
file's §1–2 covers, so a reader is likely to open the wrong file. Same class at
line 30: "Two limits apply … (also `references/output-channels.md`)" — "also" is not
a pointer verb and no section is named.

**Fix:** line 28 → `(§2 below)`; line 30 → `(see references/output-channels.md §4)`.
Consider dropping the numbering from the reference file's headings so `§n` is
unambiguously a `SKILL.md` reference.

### m2 · `output-channels.md:15-17` — cross-reference names a section but no file

> See this skill's "A deny splits three ways by audience" for what each of the three
> channels carries on a deny.

**Fix:** "See `SKILL.md` §2, *A deny splits three ways by audience*, …".

### m3 · `verifying-plugin-changes/SKILL.md:148` — bare `See plugin-craft:hook-authoring.`

A trailing pointer at the end of the `claude -c` section, with no statement of what
the reader would go there for. Inherited as-is from the source's trailing
`See [[hook-output-channels]]`.

**Fix:** either delete it or give it a reason — "For what a hook's stdout can do once
it is the code you meant to run, see `plugin-craft:hook-authoring`."

### m4 · `verifying-plugin-changes/SKILL.md:70-73` — redundant restatement

The paragraph opens `**Fix for a skill body: /reload-plugins**` and closes `Invoke it
with /reload-plugins.` The closing sentence adds nothing.

**Fix:** delete the last sentence.

### m5 · `toolkit-release/SKILL.md:11-12` — the subject of "is absent" is wrong

> This skill covers only what goes wrong, and is absent from that README.

Reads as the skill being absent from the README.

**Fix:** "This skill covers only what goes wrong — the part that README does not
carry."

### m6 · `toolkit-release/SKILL.md:52-53` — the only line that restates the README

> Migration notes are guidance to apply by hand — nothing enforces them, which is why
> the `just --list` check stands regardless.

`plugin-dev/README.md:141-144` already says migration notes are printed after the
pull and applied by hand. The clause earns its place as the *justification* for the
`just --list` check, so this is a judgement call rather than a clear cut; if the scope
rule is applied strictly, compress to "…which is why the `just --list` check stands
regardless of the migration notes." Everything else in the file is genuinely absent
from the README — checked section by section. All five failure modes the plan's S4
lists are present and none is compressed below usability.

### m7 · `skill-authoring/SKILL.md:132-133` — forward reference to "the transport"

> `CLAUDE_CODE_SESSION_ID` is the only stable anchor Bash gets, which is why the
> transport has to be keyed on it.

"The transport" is introduced sixteen lines later ("A file at a session-id-keyed
path"). As written it reads as referring back to something already named.

**Fix:** "…which is why a file-based transport has to be keyed on it (below)."

### m8 · `skill-authoring/SKILL.md:127,131` — `plugins-reference.md` / `env-vars.md` cited as bare filenames

These are Claude Code documentation pages, so a consumer can find them, but the bare
filenames read like repo-local files.

**Fix:** name them as docs pages once — "the plugins reference (`plugins-reference.md`
in the Claude Code docs)".

### m9 · `input-and-harness.md:9-11` — authoring rationale shipped to consumers

> It ships in a marketplace plugin, so the gap cannot be closed at its source.

This explains why *this file* was written rather than telling the reader anything
about hook input, and the reasoning applies equally to plugin-craft itself.

**Fix:** delete the sentence; the preceding clause already states the division of
labour.

### m10 · `hook-authoring/SKILL.md:110` — "Consequence observed in `gitlore`" frames a general rule as an anecdote

The rule (route user-facing notices through `systemMessage`, not stderr-on-exit-0 and
not via the agent) is general; the source's framing was a project decision carrying
`D14`/`NFR1`/`D7`, which were correctly stripped, leaving an attribution that now
weakens the rule.

**Fix:** drop the lead-in — "Route user-facing notices through `systemMessage`, …".

### m11 · Residual private-repo attributions

Each is evidence rather than an instruction, and none blocks a reader, but they are
the remaining names a consumer cannot open: `prohibitions`'s design notes
(`output-channels.md:96-97`), `unsandbox-git-status` and `cwd-safety`
(`output-channels.md:86-90`), `home` at 0.4.3 (`verifying-plugin-changes/SKILL.md:31`),
`gitlore`'s eval fixture (`input-and-harness.md:109-111`). `handoff`'s hooks
(`hook-authoring/SKILL.md:82`) and the `worktree_root.py` reference were already
generalized as the plan required. Recommendation: leave them — stripping dated,
named evidence would turn it into assertion, which the plan explicitly protects
against — but if any are trimmed, take `home` at 0.4.3 first, since the version
triple carries the point without the plugin name.

### m12 · `output-channels.md:38` — surviving first person, in quotation

> So "exit 0 on every path so we never block a Write" is over-broad reasoning that …

The `we` is inside a quoted piece of reasoning being criticised, not the skill's own
voice. Recommendation: keep as-is. Noted only so a later sweep does not "fix" it.

---

## Clean categories, stated explicitly

**Imperative form (criterion 4) is clean.** A `you`/`your`/`yourself` sweep across all
six files returns eleven hits and **zero** instruction-subject violations. Every hit
is one of the exempt classes: `skill-authoring`'s own examples of the rule
(lines 66-69, 71, 78, 80), a possessive naming the reader's referent
(`input-and-harness.md:113` "runs your repo-mutating hooks";
`output-channels.md:118` inside a quoted tool-result string;
`input-and-harness.md:117` inside a JSON example), and a relative clause naming a
referent, not an instruction subject (`verifying-plugin-changes/SKILL.md:3` and `:8`,
"the code you just edited"). The four source-side violations the plan implied —
`stale-plugin-code`'s "right after **you** move it", "**you can** test a hook-logic
change", "the checkout **you are** editing", and `hook-output-channels`' "when **you
want** file contents" — were all rewritten correctly. No further sweep is warranted;
per `skill-authoring`'s own §3 a blanket sweep here would be the false-positive trap.

**Project-specific first-person voice is clean.** No "my human partner", no
first-person authorial voice anywhere under `skills/`; the single `we`
(m12) is a quotation.

**Wikilinks, `memory/` paths and source-fact filenames are clean** — mechanically, via
`scripts/check-skill-text.sh`, which exits 0.

**Cross-references resolve**, with the two exceptions above (M2 points at a real skill
that does not carry the claim; m2/m3 are under-specified rather than broken). All
three `plugin-craft:*` references name skills that exist; both `references/*.md`
paths exist and are correct relative to the skill base directory;
`plugin-dev/README.md` exists in this repo and ships to every consumer.

**`hook-authoring` carries no §7 wording content** — one borderline phrase, kept
deliberately. `SKILL.md:57` says "one curt lowercase line goes on `systemMessage`".
The adjective is §7's vocabulary, but the sentence comes verbatim from
`brief-additionalcontext-survives-deny.md`'s Decisions section and is mandated by the
plan's S1 item 2. It states the *shape* of the third channel's payload, not a wording
rule: none of §7's actual content is present — no "lowercase, em-dash separator,
factual, no instructions or actionable phrases", no example lines, no
`_wipe-emit.sh`, no ANSI-reset guidance, and nothing from the *no actionable phrases*
deny rule. **Recommendation: keep it.** Flagged only so the question is settled on
the record rather than re-litigated.

**Description ordering (criterion 1, purpose→use-when→exclusions) is clean in all
four.** None leads with a trigger list. Exclusions: `hook-authoring` "Not for hook
wording style", `verifying-plugin-changes` "Not a guide to writing plugins",
`toolkit-release` "The happy path is in `plugin-dev/README.md`",
`skill-authoring` none — optional per the rule, but see M4/M5, where an exclusion is
the fix. One nit on `hook-authoring`'s: "Not for hook wording style" excludes a topic
no plugin-craft skill covers and points nowhere, so a consumer with that question is
turned away with no destination. Either drop it or phrase it as a plain non-goal
("Not a style guide for hook message wording").

**`toolkit-release` scope (criterion 5) is otherwise clean.** Section by section
against `plugin-dev/README.md`: the sandbox failure, the classifier/`/add-dir`
refusal, `tree_is_clean`'s exclusion set, the `just --list` post-pull check and the
`docs/changelog.md` source-checkout rule are all absent from the README. Only m6
touches README material. One low-priority leak: `gitlore-memory-message`
(`toolkit-release/SKILL.md:36`) is a filename a non-gitlore consumer will not have,
inside a parenthetical listing what lives under `.claude`; harmless as an example,
droppable at no cost.
