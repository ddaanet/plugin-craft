---
name: skill-authoring
description: "How to write a skill that is found, triggered and able to reach its own scripts: description shape and its per-session cost, what `allowed-tools` actually does, which second-person forms the imperative rule targets, and how a bundled script is invoked when the plugin env vars are absent. Use when writing or revising a skill, a plugin command or its frontmatter, or when a skill's description is not matching the moments it should. Complements `plugin-dev:skill-development`, which covers structure and progressive disclosure. For a skill whose edited body is not the one loading, see `plugin-craft:verifying-plugin-changes`."
---

# Skill authoring

## Descriptions

A skill's `description:` frontmatter is shown verbatim in the Claude Code
TUI skill list, so it must **open with a concise statement of what the
skill does/is**, then follow with the trigger phrases / "Use when…"
clause, then optional exclusions. Never lead with a bare trigger list —
that reads as noise in the TUI and the user can't tell what the skill is
for at a glance.

**Why:** the description is the at-a-glance summary the user reads when
choosing a skill; a trigger-first description fails that job. Confirmed
against marketplace skills (revdiff: "Review diffs… Activates on…";
skill-creator: "Create new skills… Use when…"; mcp-builder: "Guide for
creating… Use when…").

**How to apply:** structure every skill description as `[one clause:
what it does] + [triggers / when-to-use] + [optional: what NOT to use it
for]`. Also drop overspecific or stale implementation detail from the
tail (e.g. "writes a short markdown task file… otherwise leaves nothing
in place") — mechanics aren't a useful TUI summary. Applies to all
skills in a plugin, not just the headline one.

**A description is injected, not merely displayed, and a plugin command pays
the same.** Every enabled skill's and command's `description:` loads into
context at session start, so its length is a per-session cost in every repo
where the plugin is enabled. `/context` reports the whole set under *Skills*,
and a plugin command with no `skills/` directory of its own appears there
beside them — `gitlore:install`, one short clause, under 20 tokens;
`gitlore:add-tier`, ~70.

That matters past style. Moving an always-loaded line — a memory index entry,
say — into a command rather than a skill does not make it free: the lever is
description length, not the command-versus-skill choice, and a description
carrying the routing surface the index line carried is a lateral move.

Model guidance does not belong in a skill body either. Which model runs the
work is an agent-frontmatter concern, so a skill that says "run this on Sonnet"
is stating something it cannot enforce — put it on the agent definition
instead.

## `allowed-tools` grants, it does not restrict

A command's or skill's `allowed-tools` pre-approves the listed tools for the
turn that invokes it. Every other tool stays callable and falls back to the
session's normal permission rules, so leaving one out costs a permission
prompt, never a block — `plugin-dev`'s own `command-development` skill calls
it "which tools command can use", which reads as a whitelist and is wrong.
The entries are permission patterns rather than tool names:
`Skill(<plugin>:<name>)` pre-approves one skill and a bare `Skill` any of
them, `Agent(<AgentName>)` a subagent dispatch. `Agent` is the dispatch tool;
the `Task*` tools are the unrelated background-task feature. Verified against
the CC 2.1.250 docs.

## Imperative form: what the rule targets

`plugin-dev:skill-development` requires imperative/infinitive form in skill
bodies. Its prohibited examples are all second person as the **subject of an
instruction** — `You should create...`, `You need to configure...`, `You can
use...`. Reflexive intensifiers (`do not verify it yourself`), possessives
naming a referent (`your post-compaction self`), and passive objects
(`submitted for you`) are not what the rule targets.

**Why:** a bare `grep -w you` over a skill body reports all of these
identically, which inflates a small real fix into a large cosmetic sweep and
invites rewrites that lose meaning. In two skill bodies, 11 grep hits
contained exactly 1 true violation.

**How to apply:** classify each hit before rewriting — instruction-subject
(rewrite verb-first), load-bearing intensifier (replace the word rather than
delete it: `run it yourself` → `run it directly` keeps the agent-vs-machinery
contrast), removable intensifier (delete), or a referent with no good
third-person label (keep). One skill body deliberately keeps `your
post-compaction self`: it asserts the identity continuity that motivates
writing the file at all, which `the post-compaction agent` drops. Do not
"fix" it on a later grep sweep.

## Bundled scripts

How a SKILL.md body reliably invokes a script bundled in its own plugin —
**verified by test 2026-06-12** (CC 2.1.175) and re-verified by the same live
`env`/`PATH` probe on **CC 2.1.219, 2026-07-24**, contradicting two
claude-code-guide passes that claimed it isn't possible:

- `CLAUDE_PLUGIN_ROOT` is **UNSET** in the agent's Bash tool environment (it is
  set only for hook processes). So `${CLAUDE_PLUGIN_ROOT}/scripts/foo.sh` from a
  skill body does NOT resolve. (`env` dump confirmed; `CLAUDE_PROJECT_DIR` is
  absent from agent Bash too.)
- Claude Code **auto-adds every installed plugin's `<root>/bin` to PATH** — no
  `bin` key in `plugin.json` needed (the cache plugin bins are all on PATH).
  This holds from the cache path, so it works for end-users, not just a dev
  checkout.
- **Cross-plugin bare-name invocation works** (verified 2026-07-12): PATH gets
  one `bin/` entry per *enabled* plugin — all plugins, not just the invoking
  one, and entries are added even when the `bin/` dir doesn't exist (the PATH
  builder is `enabled.filter(non-builtin && path).map(join(path,"bin"))`, with
  no existence check). Disabled plugins' bins are absent. So plugin A's skill
  can call plugin B's `bin/` executable by bare name iff B is enabled;
  `command -v` is the availability probe (costs a tool call, so weigh it
  before probing repeatedly).
- A `bin/` executable **resolves by bare name** from a fresh agent Bash call
  (tested: a throwaway `bin/` script ran by name → printed output).
- The Skill tool also announces `Base directory for this skill: <abs-path>` at
  invocation; Anthropic's document-skills (xlsx/pptx/docx) lean on this with
  bare relative `python scripts/foo.py`. Less reliable across invocation paths
  than the `bin/`-on-PATH route. Re-confirmed 2026-07-22 on a **slash-command**
  invocation of a plugin skill, which is the path most likely to differ; the
  announce string is still in the 2.1.219 bundle.
- Consequence for **cross-skill references**, distinct from the bundled-script
  case: sibling skills in one plugin are reachable from that base directory by
  relative path (`../other-skill/SKILL.md`). A skill that points at another
  skill's template should name that path. Pointing at "the template in the X
  skill" with no path leaves *invoking X* as the only route the agent can see —
  and a skill with an activation hook does destructive work on invocation.

### Locating the project root from a bin/ script

There is **no sanctioned way** for a `bin/` script invoked from the agent's Bash
to learn the project root. The plugins reference (`plugins-reference.md` in the Claude Code docs) scopes
the three path vars
with a closed positive list — `CLAUDE_PLUGIN_ROOT`, `CLAUDE_PLUGIN_DATA` and
`CLAUDE_PROJECT_DIR` are "exported as environment variables to hook processes
and to MCP and LSP server subprocesses" — and the Bash tool is not in it, nor in
the table of the five plugin components where `${...}` placeholders resolve.
The env-vars docs page does not list either var at all. `$PWD` is not a substitute: the
session cwd drifts. `CLAUDE_CODE_SESSION_ID` is the only stable anchor Bash
gets, which is why a file-based transport has to be keyed on it (below).

Ruled out, each for its own reason:

- **`settings.json`'s `env` block** does reach Bash, but the values are static
  literals, and a *plugin's own* `settings.json` supports only the `agent` and
  `subagentStatusLine` keys — so a plugin cannot ship one. In the consuming
  repo's tracked `.claude/settings.json` a literal root is wrong in every
  worktree sharing that file.
- **A hook exporting env into later tool calls** — no such mechanism. The only
  outward channels are `additionalContext`, `systemMessage`, and `updatedInput`
  scoped to the one call it fires on.
- **A `claude` CLI query** — nothing reports the running session's own root;
  `claude agents --cwd` filters, it does not report.

So the root must be resolved **in a hook** and handed over. Two transports:

- **`PreToolUse(Bash)` + `updatedInput`**, which *does* work on the Bash tool
  (cwd-safety uses it to wrap commands in a subshell): match the command string,
  then rewrite it to prefix `VAR=<root>`. The root is resolved fresh at call
  time, which is what makes this the safe one. Emit `updatedInput` on its own —
  pairing it with `permissionDecision: "allow"` pre-approves the tail the hook
  never inspected; see `plugin-craft:hook-authoring`.
- **A file at a session-id-keyed path** both sides can address blind. Correct,
  but the trap is *when* it is sampled: a `SessionStart(resume)` fires with the
  **resuming process's** cwd, before the harness moves the session into the
  resumed conversation's project dir — so a pointer written once at session
  start can name a repo the session was never in, silently, until something
  refuses.

**Canonical pattern:** put the script itself, uniquely named, in the plugin's
`bin/`, and have the skill body invoke it by bare name — PATH is shared across
every enabled plugin, so the name has to be unique. Keeping logic in
`scripts/` buys testability of individual components; it is not co-location
with the skill and not something the `bin/`-on-PATH mechanism needs. So a
simple script with one entry point gets no shim, and the split — a thin
`bin/` shim (`exec bash "$(dirname "$0")/../scripts/real.sh" "$@"`) over
`scripts/` — is the escalation for logic that has grown components worth
testing on their own. The shim costs a second file and a `dirname "$0"` hop
that resolves wrongly when the shim *file* is reached through a symlink from
another directory (measured 2026-09-24; a symlinked `bin/` directory is fine,
since `..` is resolved after the link). No hook required for "skill body must
run a bundled script." Use a hook only when no agent action is needed on the
result.
