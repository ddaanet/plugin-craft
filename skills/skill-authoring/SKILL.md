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

## Conditionals a script can decide stay out of agent text

Text a plugin puts in front of an agent to act on — a skill body, a probe
directive, a hook's `additionalContext`, an instructing error message — carries
no conditional that a script could have evaluated. The script decides which acts
apply and emits only those, probed values filled in. A conditional stays only
where the script cannot know the answer, typically a later outcome a stateless
hook never sees ("if the retry fails the same way, …"). The test: could the
script have read the condition from stdin, the filesystem or a probe? Then it
evaluates it. Wording of what remains is `craft:directive-writing`'s.

**Why:** each conditional hands the agent a judgement, and it either narrates
the check or guesses. It invites applying the whole paragraph, so a refusal
about one case also reads as the instruction for the others. And it spends the
directive's length budget on branches that do not apply, which gets the live act
shortened to fit.

**Example, a hook** (illustrative; details changed from the incident). A
`PostToolUse` verdict told the agent: if the build died, clean the files it left
half-written; if the call only read a log file, re-run the command that wrote
it; for a settings file, use the settings skill. All three conditions were
decidable from `tool_input` — the command text and the path. The hook should
branch on them and emit the single matching instruction. Two reviewers passed
the three-branch version; the maintainer caught it.

**Example, a skill body.** "If the tree is dirty, commit first" asks the agent
to check what `git status --porcelain` already reports. Have the bundled script
print the instruction only when the tree is dirty, and the body say to run it
and do what it prints.

## Bundled scripts

A skill body reaches a script bundled in its plugin by bare name from the
plugin's `bin/`, uniquely named: `CLAUDE_PLUGIN_ROOT` is unset in the agent's
Bash tool, and every enabled plugin's `bin/` is on PATH. Details, with the
dated probes behind them, are in `references/bundled-scripts.md`:

- **Holding a script a skill must run, a cross-plugin call, or a path to a
  sibling skill** → the PATH findings and the canonical `bin/` pattern.
- **Holding a script that needs the project root** → its "Locating the project
  root" section: no sanctioned way, so a hook resolves it and hands it over.
