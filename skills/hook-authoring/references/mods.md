# Mods: a plugin's JS/TS hooks module

A mod is a plugin whose `hooks/hooks.json` carries `"modules": ["./x.ts"]`
beside the ordinary `hooks`, each module an ES module (`.js` or `.ts`, no build
step) exporting `register(on, options)`. It needs CC 2.1.287 or later and is
off under `--safe-mode` and `disableAllHooks`.

Docs: `https://code.claude.com/docs/en/plugins/mods/{overview,api,reference,events,test}.md`.
The full API is `mods/types/claude-code.d.ts` in `anthropics/claude-code`
(about 500 KB, so read it in 100k-character offsets), or the copy CC writes for
the installed build into the mod's `.claude-plugin/types/`.

## 1 · The `$` API facts that change designs

Read from the d.ts on 2026-10-08, CC 2.1.294 installed.

- **`$.command.run({command, args})`** "runs a slash command as if the person
  typed `/command args`", built-ins included (`clear`, `compact <focus>`,
  `rename <title>`). It "rejects an unknown name, and inside a hook the turn is
  waiting on" (§2). `command` takes the name without a slash and `args` a string.
- **`$.session.compact({instructions})`** "rejects while a turn runs".
- **`$.prompt.submit({text, asUser})`** runs when the session is idle;
  `asUser: true` drops the "sent by mod X" preamble.
- **`$.model.fork({prompt})`** is one request over the current conversation,
  same model and system prompt, mostly cache reads, resolving to the reply text.
- **`session.start` never fires after `/clear`**; `session.end` does, with
  `reason: 'clear'`. Settings hooks are `classic.<Event>`, the stdin JSON being
  `e`.
- **`$.fs`** is `read, write, list, exists, stat, ancestors`: no rename, no
  delete, and `write` is not atomic. An atomic state file needs
  `$.process.run`.
- **`$.process.run(argv)`** has no shell, a 30 s default timeout, and resolves
  `{exitCode, stdout, stderr}`.
- **A hooks module may pass `$` only to top-level function declarations.** An
  inner `const f = ($) => …` fails the load check with "hooks module did not
  load".

## 2 · Driving `/clear`, `/compact` or `/rename` plus a continuation

Verified live on CC 2.1.295 under `claude -p`. A mod that runs a built-in and
then submits a prompt cannot do it from the hook the turn is waiting on.

- **`command.run` rejects from `classic.Stop`**, with `called from a
  classic.Stop hook … run it from a later event (turn.complete)`.
  `$.clock.after` does not escape the check: a timer inherits the `classic.Stop`
  call context, so `after(0)` and `after(300)` reject alike. Under `-p` a timer
  also dies with the session, about 2 s after `Stop`, with `no session is bound`.
- **Drive inline in `on('turn.complete')`.** Awaiting `command.run` and
  `prompt.submit` there does not deadlock and keeps `-p` alive until the
  continuation turn ends (13 s for a clear, 23 s for a compact). The payload has
  no `cwd`: record `e.cwd` in `classic.Stop`, which also keeps Esc (no `Stop`)
  from arming anything.
- **A mod-run `/clear` or `/compact` fires `SessionStart`** (`source: clear` or
  `compact`) about 0.3 s after the command, with a new session id on clear, so
  classic loaders still inject their frame. `prompt.submit({asUser: true})` then
  lands as a plain user prompt in the fresh conversation.
- `compact <focus>` resolves only when compaction ends (about 7 s). `rename`
  writes a last-wins `custom-title` entry (`output-channels.md` §1).

## 3 · Testing and `/restart`

`claude plugin test` runs `*.test.ts` files importing `claude-code/testing`.
Every mods API call the mod makes needs a stub (`on('process.run', …)`
returning `{value}`), so the kit alone is not an integration test.
`claude plugin validate --strict` does the static checks.

`/restart` is a built-in (confirmed by my human partner on 2.1.294), though
absent from the docs' command table at 2.1.290.
