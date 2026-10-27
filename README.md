# plugin-craft

Building on the Claude Code harness: setting up a plugin repository, authoring
and debugging hooks, writing skills, and verifying that the plugin code
actually running is the code you just edited.

Five skills and one small hook (below), each firing on a moment you are already
in rather than on a topic word you have to think to type. They were cut from a
shared memory tier because recall delivers only the first 4KB of a fact and
stops — most of each body was unreachable by the mechanism meant to reach it. A
skill body is reachable in full at invocation, which is the whole reason this
content is a plugin.

## Install

    /plugin marketplace add ddaanet/claude-plugins
    /plugin install plugin-craft@ddaanet

## The skills

**`hook-authoring`** — what a hook receives on stdin and what its stdout JSON
can actually do: the control surface, the three output channels and who reads
each, the `PreToolUse` permission pipeline. It teaches a deny as splitting three
ways by audience — the verdict on `permissionDecisionReason`, the recovery on
`additionalContext`, one line on `systemMessage` — because `additionalContext`
is delivered on a deny, not only when an allowed call then fails, and a blocked
call never runs. Three reference files sit behind it, routed to by what you
arrive holding; one covers containing a plugin's own agents, whose frontmatter
hooks Claude Code drops.

**`skill-authoring`** — what makes a skill findable and self-sufficient:
description shape and its per-session cost, what `allowed-tools` grants, which
second-person forms the imperative rule targets, and how a bundled script is
reached when the plugin environment variables are absent. It also covers
keeping out of agent-facing text, a skill body or a hook's `additionalContext`,
any conditional a script could have decided. The bundled-script material sits
in a reference file behind the hub.

**`verifying-plugin-changes`** — confirming the plugin code actually running is
the code you just edited: which reload path refreshes a skill body, a hook, a
manifest. It fires on a symptom with no keyword — an edit that appears not to
work while nothing errors — which is exactly the trigger a memory index line
could never match.

**`toolkit-release`** — what goes wrong when releasing a plugin with the
vendored `claude-plugin-dev` toolkit: why `just release` must run unsandboxed,
what the permission classifier does and does not refuse, what
`error: uncommitted changes` actually excludes, the push-route rewrite no
preflight catches, and the post-pull check that catches a silently broken
justfile. The happy path stays in the toolkit's own `plugin-dev/README.md`,
which every consumer already has.

**`plugin-creation`** — taking a new or freshly extracted repository to a
working plugin in the decided order: gitlore memory, then
`/plugin-dev:create-plugin`, then the vendored `claude-plugin-dev` toolkit and
its dogfood launcher. A read-only script, `plugin-craft-creation-status`,
reports the first missing step and who acts on it; the skill body keeps the
judgement and routes away from a hand-rolled `--plugin-dir` launch to the
dogfood route.

## The hook

Alongside the skills the plugin ships one `PostToolUse` hook on `Bash`. When an
agent runs `claude --version` and the installed version differs from the one the
session is running, the hook tells the agent both and asks it to stamp
observations with the running one. It is silent otherwise, never blocks, and
needs `jq` on the `PATH`; without it, it does nothing.

## Development

    just precommit

The commit gate, required before every commit.

`plugin-dev/` is generated content, vendored by `git subtree` at a `dist-` tag.
Changes go to [claude-plugin-dev](https://github.com/ddaanet/claude-plugin-dev)
and arrive here through `just update-plugin-dev`.

The design is in the
[design document](https://github.com/ddaanet/plugin-craft/blob/main/docs/design.md).

## License

MIT
