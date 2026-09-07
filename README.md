# plugin-craft

Building on the Claude Code harness: authoring and debugging hooks, writing
skills, and verifying that the plugin code actually running is the code you
just edited.

Four skills, each firing on a moment you are already in rather than on a topic
word you have to think to type. They were cut from a shared memory tier because
recall delivers only the first 4KB of a fact and stops — most of each body was
unreachable by the mechanism meant to reach it. A skill body is reachable in
full at invocation, which is the whole reason this content is a plugin.

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
call never runs. Two reference files sit behind it, routed to by what you arrive
holding.

**`skill-authoring`** — what makes a skill findable and self-sufficient:
description shape and its per-session cost, what `allowed-tools` grants, which
second-person forms the imperative rule targets, and how a bundled script is
reached when the plugin environment variables are absent.

**`verifying-plugin-changes`** — confirming the plugin code actually running is
the code you just edited: which reload path refreshes a skill body, a hook, a
manifest. It fires on a symptom with no keyword — an edit that appears not to
work while nothing errors — which is exactly the trigger a memory index line
could never match.

**`toolkit-release`** — what goes wrong when releasing a plugin with the
vendored `claude-plugin-dev` toolkit: the sandbox and classifier failures that
leave a release half-landed, what `error: uncommitted changes` actually
excludes, and the post-pull check that catches a silently broken justfile. The
happy path stays in the toolkit's own `plugin-dev/README.md`, which every
consumer already has.

## Development

    just precommit

Validates the plugin manifest, syntax-checks `scripts/`, and runs
`scripts/check-skill-text.sh` — which fails on any shipped skill text that cites
the memory store the skills were cut from, since a wikilink or a `memory/` path
resolves to nothing on a consumer's machine and the failure is silent for them
and invisible to the author.

`plugin-dev/` is generated content, vendored by `git subtree` at a `dist-` tag.
Changes go to [claude-plugin-dev](https://github.com/ddaanet/claude-plugin-dev)
and arrive here through `just update-plugin-dev`.

See `docs/design.md` for the design and `docs/changelog.md` for how it got there.

## License

MIT
