## Brief: seed the plugin-craft plugin from ddaanet harness facts

2026-09-02

Process this after mounting the ddaanet memory tier (`/gitlore:add-tier`). Every
source file named below is then at `memory/ddaanet/<name>.md` in this repo.

### What this repo is

A Claude Code plugin holding what ddaanet memory has learned about *building on
the Claude Code harness* — hooks, skills, and the plugin loader. Four skills. It
gets a marketplace row in `ddaanet/claude-plugins`.

It is the sibling of `craft`, which takes the writing and testing guidance from
the same curation pass. The two never compete for a trigger: `craft` fires when
you are writing a document, a plan or a test; this one fires when you are
building or debugging a plugin.

### Why this content leaves memory

**Recall delivers the first 4096 bytes of a memory file and stops.** Of the eight
source facts, seven are over that: `hook-output-channels` is 17,646 bytes (23%
reachable), `stale-plugin-code` 9,064 (45%), `claude-plugin-dev` 7,549 (54%),
`hook-input-schema` 6,564 (62%), `skill-bundled-scripts` 5,640 (73%),
`posttooluse-print-mode` 5,106 (80%).

**`stale-plugin-code` is the hard case and the reason this repo is worth
cutting.** Its trigger is a symptom with *no token*: "the plugin code actually
running is not the code you just edited. Nothing errors — the change simply
appears not to work." Nothing a tool result prints will ever match an index line,
so memory cannot reach it by design. Its own first paragraph already writes the
checkpoint it needs: *"Before trusting any verification of plugin code, confirm
the loaded source matches the repo."* That belongs in a skill, at the moment of
verification.

### The four skills and their sources

| skill | source facts | bodies |
| ----- | ------------ | -----: |
| hook authoring | `hook-output-channels` §1–6, `hook-input-schema`, `posttooluse-print-mode` | ~26.2KB |
| skill authoring | `skill-description-purpose-first`, `imperative-form-scope` (fold in), `skill-bundled-scripts` | 10.7KB |
| verifying plugin code you just edited | `stale-plugin-code` | 9.1KB |
| toolkit release and vendoring | `claude-plugin-dev` | 7.5KB |

Eight facts, ~56.6KB of body, holding 3,659 bytes of always-loaded index.

### Decisions

- **`hook-output-channels` splits at §7.** Sections 1–6 are hook mechanism —
  the control surface, channel mechanics, the `PreToolUse` permission pipeline,
  `updatedToolOutput`, emitting file bodies, choosing a channel. §7 is prose
  craft (wording a user-facing line versus an agent-facing deny), 3,143 bytes,
  and it goes to `craft`'s directive-writing skill instead. The file marks the
  boundary itself: §7 scopes its own rule to "DENY channels, not DIRECTIVE
  channels."
- **Hook authoring is a complement, not a replacement.** `hook-input-schema`
  states the relationship in its own body: it covers what
  `plugin-dev:hook-development` omits — the optional base fields, `SessionStart`
  `source` values, the extended event union. That skill ships in a marketplace
  plugin, so the gap cannot be closed at its source. Write the description to
  activate *alongside* it, not instead of it.
- **Each skill's description names the moment, not the topic.** "Authoring or
  debugging a Claude Code hook", "verifying plugin code you just edited" — not
  "hooks" and "plugins". `stale-plugin-code` is unreachable today precisely
  because there is no topic word to match; naming the topic again would
  reproduce the failure in a new format.
- **Four skills, one plugin.** Every enabled skill's `description` is injected at
  session start and counted under `/context`'s *Skills*, so context cost is
  per-skill and packaging is neutral on it. The plugin boundary is an enablement
  decision, and these four share one.

### What deliberately stays in memory

Do not widen the scope to these. Each is under or near the 4096-byte cap and
each has a token a tool result surfaces, which is the index working as designed:
`cc-agent-discovery`, `cc-command-namespacing`, `subagent-skips-at-import-expansion`,
`cc-subagent-approval`, `classifier-denied-self-config`.

Two are a judgment call rather than a decision: `agent-hooks-need-exact-trust-key`
(3,372 b) and `named-dispatch-drops-frontmatter-hooks` (2,298 b) share the moment
"writing an agent definition". Both fit under the cap, so memory still reaches
them today. If a fifth skill for agent authoring earns its description, they are
its content; otherwise leave them.

### Constraints

- **Distributed skill text never cites a memory file.** Consumers do not have
  this store, so a `[[wikilink]]` dangles for every one of them. Inline the
  criteria at write time. Links pointing *outside* the set, which must be
  resolved rather than rewritten: `[[sandbox-effects]]` (in
  `hook-output-channels`, `claude-plugin-dev`), `[[classifier-denied-self-config]]`
  (in `claude-plugin-dev`), `[[claude-project-dir]]` (in `hook-input-schema`),
  `[[cc-subagent-approval]]` and `[[test-the-invocation-path]]` (in
  `posttooluse-print-mode` — the latter is moving to `craft`),
  `[[sessionstart-resume-cwd]]` (in `skill-bundled-scripts`),
  `[[cc-agent-discovery]]`, `[[cc-command-namespacing]]` and
  `[[cc-worktree-memory-freeze]]` (in `stale-plugin-code`). Links *within* the
  set become ordinary cross-references between skills or sections.
- **Descriptions are purpose first, then "Use when", then exclusions** — never a
  bare trigger list, since the description is TUI-visible as well as injected.
  Length is a per-session cost in every repo where the plugin is enabled.
- **Dates that ground a claim stay.** Much of this content is verified against a
  specific Claude Code build ("verified 2026-07-22 against the shipped binary
  2.1.217", "verified CC 2.1.246", "re-verified on 2.1.219"). Stripping those
  turns evidence into assertion, and these are exactly the claims that rot.
  Carry them into the skill text.
- **Vendor the release toolkit, don't write one.** Run `claude-plugin-dev`'s
  `install.sh` from this repo's root; it resolves the newest `dist-vX.Y.Z` tag
  and does the `git subtree add` itself. Never pin a bare `vX.Y.Z` source tag or
  `main`, and never hand-edit `plugin-dev/`. Define `precommit` and `prerelease`
  recipes or `just` refuses every recipe.
- **Do not delete or edit the source memory facts.** Retiring them from the
  ddaanet tier is a separate gitlore-side pass; the tier is shared with nine
  repos and this one has no authority over it.
- Never `--no-verify`. Do not create or switch branches — work on what is
  checked out.

### Rejected approaches

- **Naming it `craft:plugin-dev`.** `plugin-dev/` is the vendored toolkit
  directory and `plugin-dev:` is an existing skill namespace
  (`plugin-dev:skill-development`, `plugin-dev:hook-development`). A third
  meaning for the same word makes every reference ambiguous.
- **Shipping this content from the `claude-plugin-dev` repo.** That repo is
  subtree-vendored infrastructure, not a marketplace plugin: skills are
  discovered from `skills/` at a plugin root, not from a consumer's
  `plugin-dev/`, so a skill placed there would never load.
- **Folding it into `craft`.** Different moment and different audience. Someone
  writing a design doc is not building a hook, and the two sets would compete
  for attention in one description list.
- **Leaving it in memory and splitting the bodies under 4KB.** Viable for a
  symptom-keyed fact and it is the right answer for `sandbox-effects`. It is the
  wrong answer here because these triggers are task-shaped: no split makes an
  index line fire on "I am writing a hook".

### Open

Whether the release-and-vendoring skill belongs here at all, or whether that
procedure is better documented in `claude-plugin-dev`'s own `toolkit/README.md`,
which already ships with the vendored files. Decide before writing it; the other
three skills do not depend on the answer.

### Additional context

- This directory is not a git repository yet — `git init`, then `/gitlore:install`
  and `/gitlore:add-tier` for ddaanet, in that order (the tier mounts inside the
  memory submodule). With no `origin` on the parent, gitlore seeds a local-only
  memory store on a `./.git/gitlore-placeholder` url. That is a finished install,
  not a stalled one.
- The ddaanet index is 25,505 bytes against a ~24,985-byte loader cutoff, so it
  truncates today. Converting these 8 lines frees 3,659 bytes. Real, but
  secondary — reachability of the bodies is the motive.
- Sibling routing from the same pass: writing, plan, test, directive and
  tooling-change facts go to `ddaanet/craft`; bats, shellcheck and justfile facts
  go to `ddaanet/shell-scripting`. Briefs are already dropped in both.
