# A file write fails with "classifier gave no verdict" under `--plugin-dir`

Part of `verifying-plugin-changes`: an edit to a plugin loaded from the tree
being edited.

Scope: the hard-failure text only — `auto mode classifier gave no verdict`,
then `This is a hard failure` and `Don't retry it`. The transient and
one-retry texts say to retry once; do that instead. A denial, where the
classifier judged the action and blocked it saying why, is a different
failure, and no route around it is sanctioned.

Cause: `--plugin-dir` marks the loaded directory's content sensitive on
purpose, so `Write`, `Edit` and `NotebookEdit` there all get the hard failure,
and retrying repeats the answer. Fix: relaunch with the plugin loaded through
the toolkit's dogfood launcher, which loads a synced copy rather than the
checkout, or without `--plugin-dir`: ask the user to relaunch that way, since
only the user can. Meanwhile, as the error says, continue with work that does
not need the write; if the write is essential, stop and tell the user. Do not
look for another way to write the file.

## Every path under an inline plugin root is sensitive

Verified by reading the CC 2.1.283 bundle. An inline plugin root is a
`--plugin-dir` or `--plugin-dir-no-mcp` argument or a `CLAUDE_CODE_PLUGIN_DIRS`
entry, and every path under one is a sensitive file for `Write`, `Edit` and
`NotebookEdit`. The Edit/Write permission function runs its path safety check
(`checkPathSafetyForAutoEdit`) before the acceptEdits auto-allow and before
settings allow rules, and that check returns `ask` for an inline root. So:

- Under acceptEdits each edit still prompts, with `which is a sensitive file`
  and often no reason shown.
- An `Edit(/plugin/**)` allow rule in any settings scope is never consulted.
  Only session rules rooted at `/.claude/**` or `~/.claude/**` are checked
  earlier.
- Subagents hit it too: the inline-root list is session-wide.
- The directory's name plays no part and no list contains `plugin`: what flags
  the path is that it is loaded. Renaming the directory does nothing.
- Paths with a `.claude` segment, such as a `<dir>/.claude/skills` symlink
  spelling, are flagged separately, loaded or not.

When edits to a plugin tree prompt despite allow rules, check the launch for
`--plugin-dir` first (a `.bin/claude` shim, a `just claude` recipe) before
touching permissions. The fix is the one above: load a synced copy and edit the
source tree, or relaunch without the flag.

## Auto mode: `classifier gave no verdict (it skipped this action)`

`(it skipped this action)` names the reason inside the message, not a symptom
of its own: it is the `server_call_skipped` reason, which the hard-failure text
carries, and the same reason has a one-retry variant when the classifier
expected the call not to need a review (read in the CC 2.1.310 bundle). Act on
the rest of the message as the scope paragraph says: with `This is a hard
failure`, follow it, and the fix is the synced copy above; with a one-retry
text, retry once. A `Write` under a `--plugin-dir` directory got the
hard-failure text with this reason on its first attempt (CC 2.1.311, one run).
That the inline-root path check is what the server reports as this reason is
inferred, not verified.

## `CLAUDE_CODE_PLUGIN_DIRS`

The variable loads a plugin through the environment instead of a flag, and
carries the same edit sensitivity. Verified by reading the CC 2.1.283 bundle.

- **Format.** It is split on `path.delimiter` (`:` on Unix), each entry
  trimmed, and an entry is kept only if it is an absolute local path. A
  relative, `~`-prefixed or network entry is dropped with `CLAUDE_CODE_PLUGIN_DIRS:
  skipped …: a plugin folder here is an absolute local path or starts with ~`;
  the wording reads inverted, the filter keeps absolute paths. It can also come
  from a settings `env` block.
- **Inheritance.** Claude Code re-sets the variable in its own environment to
  the normalized list, so hooks and child processes (a nested `claude`) see it,
  unlike a `--plugin-dir` flag. A launcher shim that exports it can therefore
  be checked from a `SessionStart` hook, and a relaunch spawned from inside the
  process keeps it.
- **Symlinks do not escape.** The roots and the edited path both go through
  `fs.realpathSync.native`, walking up to the nearest existing ancestor,
  before the is-under test. A symlinked root flags the tree it points to, so
  editing without the prompts needs a real copy.
