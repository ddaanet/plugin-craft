# Report: write-hook-authoring

Wrote three new files under `skills/hook-authoring/`. `memory/` was not touched. No commit made, no branch created.

## Final description

```
description: "What a Claude Code hook receives on stdin and what its stdout JSON can actually do — the control surface, the three output channels and their audiences, and how a `PreToolUse` decision meets the permission pipeline. Use when writing or debugging a hook script, choosing between `systemMessage`, `additionalContext` and stderr, or working out why a block, a rewrite or injected text did not land. Complements `plugin-dev:hook-development`, which covers configuration and the event basics; this covers the payload fields and channel behaviour it omits. Not for hook wording style."
```

Kept the plan's draft essentially verbatim (purpose → use-when → complements → exclusion order already tight; no length problem — file is 7238 B total).

## Sectioning

**`skills/hook-authoring/SKILL.md`** (7238 B), four sections as specified:
1. `## 1 · The control surface: no hook injects a tool call` — `hook-output-channels` §1 verbatim, including the 2026-07-22 binary grep counts and the `InstructionsLoaded` side-effects note. Forward references `(§2)`/`(§5)` in the "How to apply" paragraph now point at `references/output-channels.md` instead.
2. `## 2 · A deny splits three ways by audience` — new content from `brief-additionalcontext-survives-deny.md`, covering the three channels, why the recovery doesn't belong on the deny reason, the CC 2.1.258 version stamp, and the two probe constraints (unsandboxed nested `claude`; transcript JSONL not `stream-json`).
3. `## 3 · Which channel to reach for` — `hook-output-channels` §6 verbatim, including the 2179-transcript measurement and the redundant-verification finding.
4. `## 4 · Routing` — two bullets pointing at the two reference files by what a reader arrives holding.

**`skills/hook-authoring/references/output-channels.md`** (8819 B), plain `# Title` heading, four sections renumbered 1–4 from source §2–§5 (channel mechanics; `PreToolUse` decisions and the permission pipeline; `updatedToolOutput`; emitting file bodies), verbatim except the two edits the plan specifies.

**`skills/hook-authoring/references/input-and-harness.md`** (10549 B), plain `# Title` heading, two top-level sections: `## The stdin payload` (`hook-input-schema` entire) and `## `--print` and the Agent SDK as a scripted harness` (`posttooluse-print-mode` entire).

## Wikilinks resolved

All six from the Constraints table that touch these three files:

| link | resolution applied |
| --- | --- |
| `[[sandbox-effects]]` (hook-output-channels 138) | inlined: "One matching `excludedCommands` segment unsandboxes the whole call, statically, and does not auto-approve it." |
| `[[hook-output-channels]]` (hook-input-schema 78) | cross-reference: "see `output-channels.md` for the channels themselves" |
| `[[claude-project-dir]]` (hook-input-schema 104) | inlined: prefer `CLAUDE_PROJECT_DIR`, else the on-disk `.git` linkage from `.cwd`; payload `cwd` drifts with `cd`/`/add-dir`. Dropped the `handoff` script name. |
| `[[test-the-invocation-path]]` (posttooluse-print-mode 19) | pointer deleted; sentence already states the act |
| `[[cc-subagent-approval]]` (posttooluse-print-mode 37) | pointer deleted, no replacement text added (the two-turn pattern is stated inline above it already) |

`skill-bundled-scripts`/`hook-output-channels` cross-references from `stale-plugin-code` are S3's concern, not this dispatch's.

## Additional edits beyond the wikilink table

- §2's `additionalContext` sentence (output-channels.md §1) strengthened from "even when the tool call then fails" to "delivered on a deny as well as when an allowed call then fails," cross-referencing SKILL.md's "A deny splits three ways by audience" instead of restating it — as the plan's S1 edit list requires.
- Fixed one instruction-subject second person: `hook-output-channels` line 39 "when you want file contents..." → "to get file contents into the model's context deterministically...".
- Applied the hard prohibition against naming an unreachable file in another repository (not itself in the Constraints table, but stated directly in the dispatch) to four spots the source text carried:
  - `hook-output-channels` §3: dropped the `prohibitions` repo's `docs/design.md` path, kept the repo name and the finding — "the `prohibitions` plugin's design notes record an unprompted off-project note drop passing without asking."
  - `hook-output-channels` §6: dropped `handoff`'s `prompt-pre-hook.sh`/`skill-pre-hook.sh` filenames, kept "two of the `handoff` plugin's hooks."
  - `hook-output-channels` §6: dropped `gitlore`'s `memory-commit-batch.sh` filename, kept "`gitlore`'s memory-commit hook."
  - `posttooluse-print-mode`: dropped `gitlore`'s `tests/evals/lib/sdk-runner.py` path, kept "a `query()`-based eval runner does not use it."
  - Also dropped the bare internal decision IDs `(D14)` and `against NFR1/D7` at the end of §6 (SKILL.md §3) — unreachable references to another repo's design doc, meaningless without a path; the sentence stands without them ("Consequence observed in `gitlore`: route user-facing notices through `systemMessage`...").
  Repo/plugin names themselves (`gitlore`, `handoff`, `prohibitions`, `unsandbox-git-status`, `cwd-safety`) were kept — the prohibition is on naming a *file* a reader can't open, not on citing which project a finding came from.

## Plan items not followed as literally as written, and why

- The plan's S1 item 2 spec for the new "deny splits three ways" section did not call for the brief's worked example (`deny-ask-user-question.sh` in the `prohibitions` plugin) or its "Rejected approaches" section, and the worked example names an unreachable file in another repo — omitted both, consistent with "withhold, don't forbid."
- The `(D14)`/`NFR1/D7` removal above is my own call, not itemized in the plan or the Constraints table; flagging it in case the plan's author wants those restored under a different resolution.

## Verification

Scoped to `skills/hook-authoring` per the coordinator's follow-up, since a sibling agent is writing other skills under `skills/` in parallel and a bare `check-skill-text.sh` run would pick up its half-written files.

```
$ cd "/Users/david/code/plugin-craft" && bash scripts/check-skill-text.sh skills/hook-authoring && echo CHECK-CLEAN
CHECK-CLEAN

$ cd "/Users/david/code/plugin-craft" && wc -c skills/hook-authoring/SKILL.md skills/hook-authoring/references/*.md
 7238 skills/hook-authoring/SKILL.md
10549 skills/hook-authoring/references/input-and-harness.md
 8819 skills/hook-authoring/references/output-channels.md
26606 total

$ cd "/Users/david/code/plugin-craft" && grep -rnoE '(verified|re-verified|Measured|measured)[^.,;)]{0,55}' skills/hook-authoring/ | sort
skills/hook-authoring/SKILL.md:88:Measured 2026-07-26 over ~2179 transcripts
skills/hook-authoring/references/input-and-harness.md:108:verified first
skills/hook-authoring/references/input-and-harness.md:121:verified 2026-07-17
skills/hook-authoring/references/input-and-harness.md:125:Measured 2026-07-17 (trivial two-turn probe
skills/hook-authoring/references/input-and-harness.md:40:Measured over a local transcript corpus 2026-08-27: 131 of ~410
skills/hook-authoring/references/input-and-harness.md:6:re-verified on **2
skills/hook-authoring/references/output-channels.md:11:verified 2026-07-17 via nested
skills/hook-authoring/references/output-channels.md:3:verified 2026-06-10
skills/hook-authoring/references/output-channels.md:53:verified CC 2
```

This grep is case-sensitive and misses capitalized `Verified` (e.g. "Verified 2026-07-22 against the shipped binary," "Verified against **CC 2.1.258**" in SKILL.md, and "Verified against the Claude Code bundle" in input-and-harness.md). Ran a supplementary check across every date/version the plan names as load-bearing (2026-06-10, -15, -17, -22, -24, -26, -27, -31, 08-03, 08-27, CC 2.1.168/212/217/219/220/232/233/246–247/258) and confirmed each is present verbatim in the written files; details in the session, not repeated here for length.
