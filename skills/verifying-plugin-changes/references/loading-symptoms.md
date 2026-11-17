# Loading symptoms: what does not load, and why

Part of `verifying-plugin-changes`: each row is a symptom or error string, the
section it points to holds the cause. Stale cache and frozen registration
are in the hub.

| Symptom | Section |
| --- | --- |
| `Agent type not found` | [Agent type not found](#agent-type-not-found) |
| `/<plugin>:<dir>:<cmd>`, a doubled prefix | [Command names](#command-names-and-collisions) |
| a skill and a command collide on one `<plugin>:<name>` | [Command names](#command-names-and-collisions) |
| a project hook is silent, no error, and the repo has the hook | [Hook silent from a subdirectory](#a-project-hook-is-silent-from-a-subdirectory-launch) |
| a `.claude/rules/*.md` with `paths:` does not load | [Rules files](#a-clauderulesmd-with-paths-does-not-load) |
| a subagent reports a `CLAUDE.md` `@` import missing | [Subagent and imports](#a-subagent-reports-an-import-missing) |
| something is not visible even in a fresh subagent | [Restart before structural diagnosis](#restart-before-a-structural-diagnosis) |

## Agent type not found

A plugin's `agents/<name>.md` is not discovered from the working directory
alone. The plugin has to be reachable by a marketplace install
(`/plugin install <plugin>@<marketplace>` or `enabledPlugins`) or by `--plugin-dir`.
Either way the dispatch name is `<plugin>:<agent>`, never the bare agent name.
Confirmed 2026-05-22 in a `--plugin-dir` session: `subagent_type:
"memory-merger"` returned `Agent type not found`, `"gitlore:memory-merger"`
dispatched, and the error's list of available agent types showed the prefixed
name beside the built-ins. A session with neither install nor flag fails both
forms, because the plugin never loaded.

Definitions are cached at session start. An edit to `agents/<name>.md` or a
command file does not reach new dispatches in the same session (observed
2026-05-22: a dispatch after editing the agent file ran the old contract text),
so an end-to-end check of a contract change needs a restart of `claude`.

## Command names and collisions

A command is invoked as `/<plugin>:<path-relative-to-commands>`:
`commands/install.md` is `/gitlore:install`, `commands/gitlore/install.md` is
`/gitlore:gitlore:install`, the subdirectory becoming an extra segment. Keep
command files flat directly under `commands/` unless a sub-namespace is wanted.
The double prefix as a stale-cache signal is in the hub.

A skill and a command that resolve to the same `<plugin>:<name>` token clash.
gitlore had a `skills/install/SKILL.md` and a command of the same name
(2026-05-23); flattening the command to `/gitlore:install` forced removing the
redundant skill.

## A project hook is silent from a subdirectory launch

Claude Code reads project settings, hooks included, from the directory
`claude` is launched in; it does not walk up to the git root. A session started
in `<repo>/sub/dir` runs none of the hooks in `<repo>/.claude/settings.json`,
not even an inline `echo` hook, and nothing reports the absence. Probed on CC
2.1.284 with unsandboxed `claude -p` runs from a scratch repo's root and from a
nested subdirectory: from the root every hook fired, with `CLAUDE_PROJECT_DIR`,
`$PWD` and the payload `cwd` all naming the root.

Every guard wired as a project hook is then absent: a version guard, a copy
guard, a `SessionStart` warning. A launcher that loads a plugin by absolute
path (`--plugin-dir`, `CLAUDE_CODE_PLUGIN_DIRS`) still loads it from there, so
the plugin appears to work while its safety hooks are off. When a project hook
does nothing, check the launch directory before debugging the hook, and
document "launch from the repo root" for a design that relies on project hooks.
A message printed by a launch shim before `exec claude` is no remedy, since the
TUI hides it.

## A `.claude/rules/*.md` with `paths:` does not load

A rules file with `paths:` frontmatter (a YAML block list of globs relative to
the repository root) arrives as a system-reminder carrying its contents, once,
at the first access to a matching file. Observed on CC 2.1.316:

- A `Read` of a matching file loads it, in the main session and in a
  general-purpose subagent; a `Read` of a non-matching file loads nothing. A
  dispatch brief need not name the rules file if the subagent's edit starts
  with a read of a matching file.
- An `Edit` of a matching file loads it too. `Write` was not probed.
- A Bash `cat` or `sed` of a matching file can load it, but detection is uneven
  across compound commands; rely on a `Read` when testing.
- `**` matches zero directories: `scripts/**/*.sh` matches
  `scripts/write-guard.sh`.

A session does not see a rules directory created after it launched. In the
session that created `.claude/rules/`, a `Read` of a matching file loaded
nothing, while a subagent of that session, spawned before the file existed,
loaded it on its first matching access. The same main session did load a rules
file on a matching `Edit` after a `/compact`; whether the compaction made the
difference is unprobed. Test a new rules file from a fresh `claude -p` or a
subagent: in the session that wrote it, silence reads as a broken glob.
`claude plugin validate --strict` does not read `.claude/rules/` in a plugin
repository, so a rules file adds no validator finding.

## A subagent reports an import missing

On CC 2.1.326 an Agent-tool subagent receives `CLAUDE.md` `@path/to/file`
imports expanded, as a top-level session does, so its report of a missing
import is evidence the import does not resolve. An earlier version did not
expand them: on 2026-08-11, after `@docs/shared.md` was added as the last line
of a project `CLAUDE.md`, a subagent reported the file's contents missing while
`claude -p` from the same directory showed the import resolved. Confirm a
missing import with `claude -p '...'` from the target directory before
changing the import line.

## Restart before a structural diagnosis

A fresh subagent is not a fresh session: it inherits session-level state fixed
at start. Before diagnosing a structural cause for "X does not resolve, even in
a fresh subagent", ask what X depends on that is read once at process or
session start: a `PATH` baked at shell init (a `.envrc` edit), an agent
registry snapshotted at launch, cached configuration. If something like that
fits, restart the session first.

The case behind this: a bare command failing to resolve in a freshly spawned
subagent was diagnosed as proof that a `PATH_add` cannot work for agent Bash
calls, and a workaround shipped (hardcoded venv paths, a widened hook regex)
before the simpler explanation was checked: the session's Bash environment was
fixed before the `.envrc` edit, for every call including subagent spawns, and
one restart fixed both the `PATH` and a new agent's visibility. When restart
versus structural cause is ambiguous, say so and ask instead of shipping a
workaround for a misdiagnosed cause.
