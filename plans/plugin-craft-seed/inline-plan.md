# Inline plan — plugin-craft-seed

Status: `inline-planned`. Source briefs: `brief-plugin-craft-seed.md`, `brief-additionalcontext-survives-deny.md`. Classification in `classification.md`.

## Scope

**Affected files**

| path | state | change |
| ---- | ----- | ------ |
| `skills/hook-authoring/SKILL.md` | new | decision surface + routing |
| `skills/hook-authoring/references/output-channels.md` | new | `hook-output-channels` §2–5, amended |
| `skills/hook-authoring/references/input-and-harness.md` | new | `hook-input-schema` + `posttooluse-print-mode` |
| `skills/skill-authoring/SKILL.md` | new | `skill-description-purpose-first` + `imperative-form-scope` + `skill-bundled-scripts` |
| `skills/verifying-plugin-changes/SKILL.md` | new | `stale-plugin-code` |
| `skills/toolkit-release/SKILL.md` | new | `claude-plugin-dev` failure modes — see §S4 |
| `scripts/check-skill-text.sh` | new | enforces the no-memory-citation constraint |
| `justfile` | exists, `precommit` is `true` | replace the stub body |
| `memory/ddaanet/*.md` | exist | **not touched** — read-only sources |

**Verified against the filesystem before planning:** no `skills/`, no `plans/`, no `scripts/` existed; the eight sources total 56,640 B, matching the brief; `hook-output-channels` splits at a real heading, `## 7 · Wording` at line 229, so §1–6 is lines 1–228.

## Per-file changes

### S1 · `skills/hook-authoring/`

Split three ways because the merged source is ~25 KB — past the point where a single `SKILL.md` reads as a routing document. `SKILL.md` holds only what a reader needs before knowing which question they have; the two reference files hold the mechanism.

**`SKILL.md`** (target ≤ 8 KB), sections in this order:

1. **The control surface** — `hook-output-channels` §1 entire, including the 2026-07-22 binary grep (`injectToolCall`, `requestTool`, `forceRead`, `injectTool`, `forceToolUse`, `requestedTools`, `injectedToolCalls` all absent; `additionalContext` 180, `updatedInput` 249, `permissionDecision` 34, `PostToolBatch` 46, `InstructionsLoaded` 27, `systemMessage` 54) and the `InstructionsLoaded` side-effects-only note.
2. **A deny splits three ways by audience** — from `brief-additionalcontext-survives-deny.md`. This is the section the brief exists to add, and it is new content rather than an extract. Teach it as the default shape for a guard hook: verdict on `permissionDecisionReason` (becomes the `tool_result`, `is_error: true`), recovery — the form the action should take instead — on `additionalContext` (a separate transcript entry, `"type": "attachment"`, `attachment.type` `hook_additional_context`, carrying `hookName`, `hookEvent` and the `toolUseID` of the denied call; not echoed to the user), one curt lowercase line on `systemMessage` (renders as `PreToolUse:<Tool> says: <text>`). State that the recovery does not go on the deny reason, and why: it would render beside every block, noise for the human and no better targeted for the agent. Version-stamp: verified against **CC 2.1.258** with a scratch `--settings` hook under a nested `claude --print`, and state the probe so a reader can re-run it — the failure mode is silent, since a CC that stopped delivering `additionalContext` on a deny leaves the guard working and only the teaching gone. Include the two probe constraints: it needs an **unsandboxed** nested `claude` (a sandboxed `claude -p` silently drops `SessionStart` hooks), and the attachment appears only in the on-disk transcript JSONL, never as its own event in `--output-format stream-json`.
3. **Which channel to reach for** — `hook-output-channels` §6, including why a blind agent re-verifies.
4. **Routing** — three or four lines pointing at the two reference files by what a reader arrives holding, in the style the source file's own head uses.

Also fold in `hook-output-channels` §1's own forward references so they point at the reference files rather than at "§2"/"§5".

**`references/output-channels.md`** — `hook-output-channels` §2 (channel mechanics), §3 (`PreToolUse` decisions and the permission pipeline), §4 (`updatedToolOutput`), §5 (emitting file bodies the agent must edit), verbatim in substance. Two edits:

- §2's `additionalContext` sentence currently claims only the weaker thing — delivered "even when the tool call then fails". Replace with the stronger verified claim: delivered on a `PreToolUse` **deny** too, which is not a call that failed because a blocked call never runs. Cross-reference `SKILL.md`'s three-way-split section rather than restating it.
- §3's closing `See [[sandbox-effects]]` (line 138) → delete the pointer, inline the clause it was reaching for: one matching `excludedCommands` segment unsandboxes the whole call, statically, and does not auto-approve it.

**`references/input-and-harness.md`** — what arrives at the script and which harness fires it. `hook-input-schema` entire, then `posttooluse-print-mode` entire, under two top-level headings. Link resolutions in §Constraints below.

**`description:`** draft (revise for length at write time, keep the purpose→use-when→exclusions order):

> What a Claude Code hook receives on stdin and what its stdout JSON can actually do — the control surface, the three output channels and their audiences, and how a `PreToolUse` decision meets the permission pipeline. Use when writing or debugging a hook script, choosing between `systemMessage`, `additionalContext` and stderr, or working out why a block, a rewrite or injected text did not land. Complements `plugin-dev:hook-development`, which covers configuration and the event basics; this covers the payload fields and channel behaviour it omits. Not for hook wording style.

### S2 · `skills/skill-authoring/SKILL.md`

Single file (~10.7 KB of source). Sections:

1. **Descriptions** — `skill-description-purpose-first` entire: purpose → "Use when" → exclusions, never a bare trigger list; the marketplace confirmations (revdiff, skill-creator, mcp-builder); descriptions are injected as well as displayed, so length is a per-session cost in every repo where the plugin is enabled, and a plugin command pays the same and appears under `/context`'s *Skills*; model guidance belongs on an agent definition, not in a skill body.
2. **`allowed-tools` grants, it does not restrict** — including that omitting one costs a permission prompt and never a block, that entries are permission patterns (`Skill(<plugin>:<name>)`, bare `Skill`, `Agent(<AgentName>)`), that `Agent` is the dispatch tool while the `Task*` tools are the unrelated background-task feature, and the correction that `plugin-dev:command-development` calls it "which tools command can use", which reads as a whitelist and is wrong. Carry **verified against the CC 2.1.250 docs**.
3. **Imperative form: what the rule targets** — `imperative-form-scope` entire. Instruction-subject second person is the target; reflexive intensifiers, possessives naming a referent and passive objects are not. Carry the measurement (11 grep hits, 1 true violation across two skill bodies) and the four-way classification. Generalize the `handoff` example — keep it as a named illustration only if it survives the withhold test; a reader cannot open that repo.
4. **Bundled scripts** — `skill-bundled-scripts` entire, including `## Locating the project root from a bin/ script`: `CLAUDE_PLUGIN_ROOT`/`CLAUDE_PROJECT_DIR` are unset in agent Bash (hooks and MCP/LSP only); every *enabled* plugin's `bin/` is on PATH, so a bare-name shim invokes bundled scripts cross-plugin; a `bin/` script has no sanctioned way to learn the project root, and the canonical pattern is a uniquely-named thin shim in `bin/` with logic in `scripts/`. Carry the dates: verified 2026-07-12, verified by test 2026-06-12.

**`description:`** draft:

> How to write a skill that is found, triggered and able to reach its own scripts: description shape, what `allowed-tools` actually does, which second-person forms the imperative rule targets, and how a bundled script is invoked when the plugin env vars are absent. Use when writing or revising a skill, a plugin command or its frontmatter, or when a skill exists but is not firing. Complements `plugin-dev:skill-development`.

### S3 · `skills/verifying-plugin-changes/SKILL.md`

Single file. Open with the checkpoint the source's own first paragraph writes — *before trusting any verification of plugin code, confirm the loaded source matches the repo* — because this skill's whole reason for existing is that its trigger is a symptom with no token: the change simply appears not to work and nothing errors.

Then `stale-plugin-code`'s four sections, headings preserved: marketplace cache keyed by version so `/plugin update` no-ops; skill bodies snapshotted at session start (`/reload-plugins`), with the bare-name `bin/` shim exception; hook event registration frozen while script bodies are not, plus the `PostToolUse`-fires-after-the-call timing caveat; `claude -c` is a full restart that keeps the conversation. Carry the dates (verified 2026-06-10 on CC 2.1.x, verified 2026-07-31) and the release-timing observation — a release reaches a project at its *next* session start, so a nested `claude -p` can run a newer version than its parent.

**`description:`** draft:

> Confirm that the plugin code actually running is the code you just edited — which reload path refreshes a skill body, a hook registration, a command or a bundled script, and which silently does not. Use when a plugin change appears to have no effect and nothing errors, before trusting any verification of an edit to plugin code, and after a `/plugin update` or a release. Not a guide to writing plugins.

### S4 · `skills/toolkit-release/SKILL.md`

**Decided 2026-09-03: the skill is written, scoped to failure modes only.** The seed brief left open whether the procedure belongs in a skill here or in `claude-plugin-dev`'s `toolkit/README.md`, which already ships with the vendored files. The evidence below settles it: the README owns the procedure and ships beside every consumer, so the skill owns only what goes wrong.

**Evidence gathered at design time.** The vendored `plugin-dev/README.md` (7,018 B, present in this repo) already documents: what each toolkit file is for; the two-tag scheme and why a source tag is refused; the install block and its three steps; the `precommit`/`prerelease` requirement and why `prerelease` is mandatory; updating, the dist-ref refusal set, migration notes; the release commit convention; last-released-version and first-release rules; `origin/HEAD` auto-detection; the version-guard hook.

What `claude-plugin-dev.md` holds that the README does **not**, all of it failure-mode knowledge an agent needs mid-run:

- `just release` must run **unsandboxed** — under the sandbox it dies at the marketplace bump on `mv: inter-device move failed … Read-only file system`, leaving a *half-done* release rather than a failed one; `just resume-release`, likewise unsandboxed, is idempotent and completes it.
- Unsandboxed is necessary and not sufficient: the marketplace lives in a sibling repo and the push is refused by the auto-mode classifier as an external repo outside the trusted source control org until `/add-dir` has been run on it.
- `error: uncommitted changes` names real work, with exactly two exemptions (`.claude`, and the gitlore memory mount read from `.gitmodules`); `.claude-plugin` is **not** exempt, since pathspecs match at the separator. The same check runs against `MARKETPLACE_DIR`.
- Run `just --list` before considering a subtree pull done: a toolkit version needing a consumer-side change makes `just` refuse to compile *any* recipe, so the breakage is invisible until an unrelated recipe run. Land the consumer-side fix as its own commit, separate from the subtree merge commit.
- Read the toolkit's `docs/changelog.md` from the source checkout, never from `plugin-dev/` — the `dist-` tree ships no `docs/`.

**Scope, as decided:** the failure modes rather than the procedure. The README owns the happy path and ships beside it; the skill owns what goes wrong, which is exactly the moment-shaped trigger the brief asks descriptions to name. Duplicating install/update/versioning prose into the skill is what should be avoided — the skill points at `plugin-dev/README.md`, which every consumer has by construction, so that pointer is not a dangling citation.

**`description:`** draft:

> What goes wrong when releasing a plugin with the vendored `claude-plugin-dev` toolkit, and what to do about it: the sandbox and classifier failures that leave a release half-landed, what `error: uncommitted changes` actually excludes, and the post-pull check that catches a silently broken justfile. Use when running `just release` or `just update-plugin-dev`, when either half-lands or refuses a tree that looks clean. The happy path is in `plugin-dev/README.md`.

### S5 · `scripts/check-skill-text.sh` and `justfile`

The seed brief's hardest constraint — distributed skill text never cites a memory file — has no enforcement, and it is the one a later edit will silently break. Make it mechanical.

`scripts/check-skill-text.sh`: over `skills/` only, fail on

1. any `[[...]]` wikilink;
2. any reference to a `memory/` path;
3. any bare `<slug>.md` matching a source-fact filename.

NUL-delimited traversal (`find … -print0`) so a spaced path cannot split; exit non-zero with the offending `file:line` and nothing else. Then `justfile`'s `precommit` becomes `jq . .claude-plugin/plugin.json > /dev/null`, `bash -n scripts/*.sh`, `bash scripts/check-skill-text.sh`. `prerelease: precommit` keeps its `true` body dropped.

Red-check it: run against a skill file with a `[[link]]` temporarily inserted and confirm it fails, before trusting a green run.

## Constraints (apply to every skill file)

**No memory citation, no wikilink, anywhere under `skills/`.** Resolutions, all verified present at design time:

| link | source · line | resolution |
| ---- | ------------- | ---------- |
| `[[sandbox-effects]]` | hook-output-channels 138 | inline: one matching `excludedCommands` segment unsandboxes the whole call, statically, and does not auto-approve |
| `[[hook-output-channels]]` | hook-input-schema 78 | within-set → cross-reference `references/output-channels.md` |
| `[[claude-project-dir]]` | hook-input-schema 104 | inline: derive the root from `CLAUDE_PROJECT_DIR` in a hook, otherwise from the on-disk `.git` linkage starting at `.cwd`; payload `cwd` drifts with shell `cd` and `/add-dir`. Drop the `handoff`-repo script name — a consumer cannot open it |
| `[[test-the-invocation-path]]` | posttooluse-print-mode 19 | delete the pointer; the sentence already states the act (derive the eval's hook wiring from the plugin's real `hooks.json`) |
| `[[cc-subagent-approval]]` | posttooluse-print-mode 37 | delete the pointer; the two-turn pattern is already stated inline above it |
| `[[sessionstart-resume-cwd]]` | skill-bundled-scripts 83 | delete the pointer; the preceding sentence carries the whole mechanism |
| `[[cc-agent-discovery]]`, `[[cc-command-namespacing]]` | stale-plugin-code 61 | inline one clause each: an agent type is `<plugin>:<agent>` and definitions are cached per session; a command is `/<plugin>:<path-under-commands>`, so a double prefix signals a stale nested cache |
| `[[skill-bundled-scripts]]` | stale-plugin-code 93 | within-set → cross-reference `plugin-craft:skill-authoring` |
| `[[cc-worktree-memory-freeze]]` | stale-plugin-code 102 | delete the parenthetical outright — it cites an unrelated finding and the sentence stands without it |
| `[[hook-output-channels]]` | stale-plugin-code 155 | within-set → cross-reference `plugin-craft:hook-authoring` |
| `[[sandbox-effects]]`, `[[classifier-denied-self-config]]` | claude-plugin-dev 99, 103 | S4 only; inline the read-only-filesystem failure and the classifier deny + `/add-dir` remedy |

**Withhold, don't forbid.** Where a skill would name an internal filename only in order to prohibit writing it, omit the name instead — naming it hands a fresh agent the exact string that triggers the behaviour. Ask who else could supply the identifier; nobody → say nothing.

**Dates that ground a claim are carried verbatim** — 2026-06-10, 2026-07-12, 2026-07-17, 2026-07-22 (binary 2.1.217), 2026-07-26, 2026-07-31, 2026-08-27, CC 2.1.250, CC 2.1.258, and every `verified`/`measured` clause found in the extracted text. Stripping them turns evidence into assertion.

**No situational state.** Byte counts of the memory store, "the index is currently over the cutoff", and the recall-cap arithmetic are the brief's motivation, not skill content. They do not appear in any skill file.

**Imperative form**, applying `imperative-form-scope`'s own classification — rewrite instruction-subject second person, keep load-bearing intensifiers and referent possessives.

**Sources are read-only.** No file under `memory/ddaanet/` is edited or deleted; retiring these facts is a separate gitlore-side pass over a tier shared with nine repos.

**Repo rules.** No `--no-verify`. No branch or worktree creation. `plugin-dev/` is never hand-edited. `just precommit` runs before every commit.

## Boundaries

**IN**

- All four skills (S1–S4), their descriptions and reference files.
- The companion brief's finding, folded into S1 as new content with its CC 2.1.258 stamp and re-runnable probe.
- `hook-output-channels` §1–6 only.
- S5: the enforcement script and a real `precommit`.
- Committing the result; `just precommit` before each commit.

**OUT**

- `hook-output-channels` §7 (wording) — routed to `craft`.
- Editing, deleting or reindexing anything under `memory/`, including the eight sources and `MEMORY.md`.
- The five facts the brief names as deliberately staying in memory, and the two judgement-call agent-authoring facts. No fifth skill.
- Pushing `main` or memory's `live`; adding the `plugin-craft` row to `ddaanet/claude-plugins`' `marketplace.json`; any release. `just check-version` reporting the entry missing stays expected.
- Any write outside this repository.

## Dependencies

- S1's reference-file split must land before `SKILL.md`'s routing section can name the files.
- S5's script must exist before the first commit that adds a skill, or the constraint it enforces goes unchecked on exactly the commits that introduce the risk. Order: S5, then S1–S3.
- S4 is independent; nothing else depends on it, and it depends on nothing but S5's gate.
- No dependency on the memory store's state, on a push, or on the marketplace row.
