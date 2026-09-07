# Classification — plugin-craft-seed

## Requirements-clarity gate

- **Requirements source:** `brief-plugin-craft-seed.md` + `brief-additionalcontext-survives-deny.md` (both in this directory)
- **Completeness:** concrete mechanism per requirement: Y — the seed brief names the four skills, their source files, the §7 split point, the description shape, the wikilink resolution list and the date-preservation rule; the companion brief names the exact §2 amendment, the three channels and their audiences, and the CC build it was verified on. Measurable criteria: Y — byte sizes, the 4096-byte recall cap, named files on disk.
- **Routing:** Proceed to triage. One item is explicitly left open by the brief (skill 4) and is carried as a contingent decision, not a requirements gap.

## Triage recall

`edify:recall` invoked with `plans/plugin-craft-seed — decisions that constrain how skill content is authored, packaged and triggered in a Claude Code plugin`. No plan dir existed, so selection ran from the index.

Selected and read: `directive-states-acts` (distributed text never cites memory files; withhold-don't-forbid; "remove narration" as the cut), `cc-command-namespacing` (a skill and a command colliding on the same `<plugin>:<name>`), `skill-description-purpose-first` (description shape, per-session injection cost, `allowed-tools` grants), `imperative-form-scope` (classify each `you` hit before rewriting). Already in context from session recall: `hook-output-channels` (truncated), `design-doc-writing`, `design-doc-no-situational-state`, `design-doc-rewire-dead-components`, `reference-doc-scope`.

Constraint surfaced that the briefs do not state: `directive-states-acts` supplies the *rule* behind the seed brief's "never cites a memory file" constraint, and adds the withhold-don't-forbid test, which applies to skill bodies that would otherwise name an internal filename in order to prohibit writing it.

## Multi-item decomposition

Trigger: implicit bundling — two brief files, four skill deliverables. Enumeration:

| # | Item | Trigger | Behavioral code? |
|---|------|---------|------------------|
| 1 | hook-authoring skill (`hook-output-channels` §1–6 + `hook-input-schema` + `posttooluse-print-mode`, amended by the companion brief) | seed brief table; companion brief folds in | No — markdown |
| 2 | skill-authoring skill (`skill-description-purpose-first` + `imperative-form-scope` + `skill-bundled-scripts`) | seed brief table | No — markdown |
| 3 | verifying-plugin-changes skill (`stale-plugin-code`) | seed brief table | No — markdown |
| 4 | toolkit release-and-vendoring skill (`claude-plugin-dev`) | seed brief table, **open** in its §Open | No — markdown |
| 5 | `precommit` gate that enforces the no-memory-citation constraint | seed brief §Constraints (the constraint has no enforcement) + repo task frame | **Yes** — shell logic |

Item 5 is the only behavioral one; it elevates itself to Moderate. Items 1–4 batch.

## Classification

- **Classification:** Moderate
- **Implementation certainty:** High — sources are on disk and read; skill authoring is a settled format; no architectural fork remains except item 4's existence.
- **Requirement stability:** High for items 1–3 and 5; the item-4 fork is named and carried, not assumed away.
- **Behavioral code check:** Yes, for item 5 only (a grep-based precommit check). Items 1–4: No.
- **Work type:** Production — the deliverable is a plugin users enable.
- **Artifact destination:** `agentic-prose` (`skills/`), with one `production`-adjacent item (`justfile` recipe + `scripts/`).
- **Evidence:** the two briefs enumerate mechanism per skill; `ls` confirms no `skills/` and no `plans/` exist; `wc -c` confirms the eight source sizes match the brief (56,640 B total); heading and wikilink extraction confirms `hook-output-channels` splits at a real `## 7 · Wording` heading (line 229) and that the brief's outside-set wikilink list is accurate, with two additional *within*-set links (`hook-input-schema` → `hook-output-channels`; `stale-plugin-code` → `hook-output-channels`, `skill-bundled-scripts`) that become cross-references.

## Author-corrector coupling

Author change: none — this design creates plugin skills, not edify pipeline artifacts. Coupled corrector: none. Update needed: no.
