# Which plugin version a repo or session runs

Part of `verifying-plugin-changes`: the cache is keyed by version, and this is
how to tell which version a given repo, session or transcript actually ran.

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
