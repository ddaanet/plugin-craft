---
name: verifying-plugin-changes
description: "Confirm that the plugin code actually running is the code you just edited — which reload path refreshes a skill body, a hook registration, a command or a bundled script, and which silently does not, since nothing errors when it does not. Use when an edited hook does not fire, a skill injects its pre-edit body, a command is missing or double-prefixed, or `/plugin update` changes nothing — and before trusting any verification of an edit to plugin code. Not a guide to writing plugins."
---

# Verifying plugin changes

One symptom, three causes: the plugin code actually running is not the code you
just edited. Nothing errors — the change simply appears not to work. **Before
trusting any verification of plugin code, confirm the loaded source matches the
repo.**

## Marketplace cache is keyed by version — `/plugin update` no-ops

`~/.claude/plugins/cache/<owner>/<plugin>/<version>/` is a flat file extraction
from a past push, not a git checkout (no HEAD). The dir is keyed by `<version>`,
so pushing new commits under the *same* version string leaves the cache stale and
`/plugin update` re-fetches nothing (confirmed live 2026-05-25: pushed under
`0.1.0`, update kept the old extraction; bumping to `0.1.1` forced the re-fetch).
Even after a refresh, only a *new* session picks it up — agent definitions in
particular are cached at session start.

**Fix:** ship via a **version bump**, not just a push. To develop against current
`main`, load with `--plugin-dir` instead of the cache.

**Installs are pinned per scope, not globally.**
`~/.claude/plugins/installed_plugins.json` holds one entry per (plugin, scope):
a `project` entry per `projectPath`, plus at most one `user` entry, each with its
own `installPath` under `cache/<owner>/<plugin>/<version>/`. Repos routinely sit
at different versions (2026-07-31: `home` at 0.4.3, `gitmoji` at 0.3.0, user
scope at 0.4.4), so the newest directory in the cache is not what a given repo
loads — read the record, not the listing.

**A release reaches a project lazily, and after that project's session has
already frozen the old root.** With marketplace `autoUpdate` on, a project
entry moves to the new version at the *first session start in that project*
after the release, and the record write lands a few minutes into that session
— after `CLAUDE_PLUGIN_ROOT` was resolved. Observed 2026-08-26: gitlore 0.5.0
tagged 08-10, and each repo's `lastUpdated` stamped on its own next session
(08-10, 08-13, 08-25, 08-26 …); the 08-26 session started 06:06Z on the frozen
0.4.4 root, its record moved to 0.5.0 at 06:13Z, and a nested `claude -p` run
from that session at 08:36Z resolved the root afresh and ran 0.5.0. So a
long-lived session and any child process it spawns can run *different* plugin
versions, and a repo idle since a release runs the old one for exactly one more
session. To pin which version a transcript ran, grep it for
`plugins/cache/<owner>/<plugin>/<version>/`.

Signature — observed 2026-05-24: a marketplace session was about to "verify"
a two-turn agent flow, but still had
the pre-flatten `commands/gitlore/` layout and the broken agent frontmatter (no
`name:`, no `allowed-tools:`) — it would have tested old code the repo had already
fixed. Check with `find
~/.claude/plugins/cache/<owner>/<plugin>/<ver>/commands` and by eyeballing
`agents/*.md` frontmatter. An agent type is addressed `<plugin>:<agent>` and its
definition is cached per session; a command is addressed
`/<plugin>:<path-under-commands>`, so a double-prefixed invocation signals a
stale nested cache. Tell in gitlore: a flat `/gitlore:resolve` in the skill list
means `--plugin-dir`/fresh cache; double-prefixed `/gitlore:gitlore:resolve`
means a stale nested cache.

## Skill bodies are snapshotted at session start

Editing a plugin's own files mid-session does not make the change live in that
session. Observed 2026-07-20: after rewriting a skill's `SKILL.md` and
committing it, invoking that skill in the same session injected the
**pre-rewrite** body — even though the skill's reported base directory was the
working tree and the file on disk held the new text. Content is snapshotted at
session start, not read at invocation.

**Fix for a skill body: `/reload-plugins`** — no restart needed. Run 2026-07-20 it
reported `18 plugins · 8 skills · 11 agents · 34 hooks`, and the next invocation
loaded the new body (the skill listing's `description:` updated too).

**Scope — this is verified for skill bodies only.** Whether `/reload-plugins`
re-registers a plugin's hook *events* is **inferred, not directly observed**: the
count it prints says it re-read the hook files, not that event routing re-bound. A
newly-declared hook event (a fresh `Stop` entry, a widened `SessionStart` matcher)
should be assumed inactive until a new session — and the one directly-observed
case went the other way (see the next section, where the fix was a new session).
Verify before relying on it either way.

Why it matters: developing a plugin *in* the session that uses it, a new magic
file can be written with no hook registered to consume it — a silent no-op, not an
error. Until a reload, fall back to the previously-shipped path and say so; never
report a mid-session plugin edit as "now active" without one.

Exception: bundled *scripts* invoked by a bare-name `bin/` shim take effect
immediately — PATH is set at session start but points at the live directory
(see `plugin-craft:skill-authoring`).

## Hook event registration is frozen; script bodies are not

Claude Code re-reads hook configuration from `settings.local.json` **mid-session**:
a hook added during a live session fires on the very next matching tool call, no
`/clear` or restart. Verified 2026-06-10 (CC 2.1.x) — added a `PostToolUse
matcher:"Bash"` hook via an Edit, the next Bash call fired it with that call's
`tool_input`. Timing caveat: a `PostToolUse` hook fires *after* the triggering
tool returns, so a single Bash call cannot observe its own hook — check the side
effect on the next call. (Distinct from `autoMemoryDirectory`, which genuinely
resolves once at startup and no hook can change.)

A **plugin's own `hooks/hooks.json` does not reload**, even under `--plugin-dir .`
where the plugin loads straight from the checkout being edited. Observed
2026-07-15 (CC 2.1.210) moving a hook from `PostToolUse(Write|Edit)` to
`PostToolBatch`: after editing `hooks.json`, a live `Edit` to the watched file
fired the unchanged `PreToolUse` hook and left its stash, but the post hook
never ran as `PostToolBatch` — no frontmatter rewrite, stash unconsumed.

The split that makes this confusing:

- **Script bodies are read per invocation** — edit a hook script and the next
  firing runs the new code. The rewritten script was live.
- **Event registration is read at session start** — so the *code* was new while
  the *event routing to it* was old. The hook got a `PostToolUse`-shaped payload,
  found no `.tool_calls[]`, and silently no-op'd.

Signature: a hook that looks dead for no reason right after moving it to a
different event. It isn't dead; it's being called on the old event with the old
payload shape. **Don't debug the script — start a new session.**

Corollary for probing: a hook-*logic* change can be tested in the session that
makes it, never a hook-*event* change. Routing the test through
`settings.local.json` instead is blocked by the auto-mode classifier as
self-modification, so that needs my human partner's explicit go-ahead.

Not verified: whether the *old* registration still fires after the edit. A no-op
and a non-call look identical from outside.

## `claude -c` is a full restart, and keeps the conversation

Everything frozen at process start is re-read on a resume. Verified 2026-07-31 by
a two-run `--plugin-dir` probe whose `SessionStart` hook logged its root and the
payload's `source`, with `hooks.json` rewritten between the runs to name a
different script: `claude -c` fired `SessionStart` with `source=resume` and ran
the **new** command, under the **same** `session_id`. The session transcript
records no plugin root or version anywhere, so a resume has no stale root to
restore — `CLAUDE_PLUGIN_ROOT` is resolved afresh from `installed_plugins.json`,
and every hook that writes from it is re-pinned exactly as on a cold start.

So for any frozen-at-start staleness that `/reload-plugins` does not clear —
hook event registration, agent definitions, a version-pinned
`CLAUDE_PLUGIN_ROOT`, anything derived from it — the remedy is **exit and
relaunch with `claude -c`**, not a cold session and not `/plugin` +
`/reload-plugins`, neither of which re-fires `SessionStart`. Skill bodies are
the exception: `/reload-plugins` clears those, as above.
`-c` takes the most recent conversation for that cwd; `--resume <id>` when other
sessions have run there since.

For what a hook's stdout can do once it is the code you meant to run, see
`plugin-craft:hook-authoring`.
