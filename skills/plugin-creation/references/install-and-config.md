# Install failures and settings.json config

Part of `plugin-creation`: what aborts `/plugin install` for someone without the
owner's access, and where plugin configuration goes so `settings.json` accepts
it.

| Symptom | Section |
| --- | --- |
| `not a valid repository name` | [A relative submodule url](#a-relative-or-local-only-submodule-url) |
| `Failed to clone repository`, `Permission denied (publickey)` | [Three layers](#three-layers-abort-an-install-without-the-owners-access) |
| `Failed to recurse into submodule path 'memory'` | [Three layers](#three-layers-abort-an-install-without-the-owners-access) |
| `Unrecognized field: X`, `"code": "unrecognized_keys"` | [Plugin config in settings.json](#plugin-config-in-settingsjson) |

## A relative or local-only submodule url

`/plugin install <name>@<scope>` clones the plugin's GitHub repository with
`git clone --recurse-submodules`, so every submodule committed there is cloned
into each installer's `~/.claude/plugins/cache/...`. A relative or local-only
submodule url breaks that: gitlore committed `.gitmodules` with
`url = ./.git/gitlore-placeholder` (its local-only sentinel) plus a gitlink,
git resolved the url against the remote
(`git@github.com:<owner>/gitlore.git/.git/gitlore-placeholder`), and install
aborted with `not a valid repository name` (2026-05-23). The inner-loop
dogfood could not catch it, because `--plugin-dir` does not recurse-clone.

A distributable plugin repository with a self-hosted submodule needs:

- an absolute `.gitmodules` url with a real scheme (`https://`, `git@...`,
  `ssh://`); prefer https so anonymous installers can read a public repository
  without SSH keys;
- the recorded gitlink sha pushed and fetchable on that remote;
- a public submodule remote, since a private one lets install work only for
  those with access.

The local-only placeholder still applies to user installs in a target
repository; only the plugin repository's own submodule needs a real remote. A
regression guard is a test asserting the submodule url is an absolute scheme.

## Three layers abort an install without the owner's access

Verified against CC 2.1.296, with `claude plugin install` in a scratch
`CLAUDE_CONFIG_DIR`:

1. A marketplace entry with `"source": "github"` clones the plugin repository
   over SSH, and the install step has no https fallback (`marketplace add`
   does: `SSH clone failed, retrying with HTTPS`). A `{"source": "url", "url":
   "https://...git"}` entry clones over https. A `git-subdir` entry with an
   `owner/repo` shorthand `url` clones over SSH too; the full https url does
   not.
2. An SSH submodule url gives `Permission denied (publickey)`, then `Failed to
   clone repository`.
3. The recurse is `--recursive`, so a private repository nested inside a public
   submodule (a gitlore memory tier mounted as a submodule) aborts it as well,
   with `Failed to recurse into submodule path 'memory'`.

`submodule.<name>.update = none` in the plugin repository's `.gitmodules`
clears layers 2 and 3: git prints `Skipping submodule` and the install
succeeds with that directory empty.

To simulate a keyless installer, put a stub `ssh` that exits 255 first on
`PATH`. A scratch `HOME` is not enough: `ssh` reads keys from the passwd home.

## Plugin config in settings.json

The Edit and Write tools run a strict validation pass on `.claude/settings.json`
after a write. It rejects an unknown top-level key with `Unrecognized field: X`
and a Zod error payload (`"code": "unrecognized_keys"`), although the published
JSON Schema at `json.schemastore.org/claude-code-settings.json` declares
`additionalProperties: true` at the root, and the schema dump in the error
message itself shows `additionalProperties: {}`. The runtime Zod schema is
canonical and the published schema lags it (Anthropic issues #3481, #5886,
#28742). The validator is strict at the top level and lax inside nested
objects, so a custom top-level key is out and the fix is to nest.

Plugin configuration goes in
`pluginConfigs["<plugin>@<marketplace>"].options.<key>`, the schema-recognized
slot. Values are `string | number | boolean | string[]`, and Edit and Write pass
validation through it. Known top-level keys (`hooks`, `permissions`,
`enabledPlugins`, `pluginConfigs`) work as expected; the field list is at
<https://code.claude.com/docs/en/settings>, best-effort, since even documented
fields have been rejected when the internal schema lagged (issue #28742).

`@` is not allowed in an unquoted jq identifier, so use the bracket form:

```
jq '.pluginConfigs["gitmoji@ddaanet"].options.enabled = true' settings.json
```

An object literal follows the same rule:
`{pluginConfigs: {"gitmoji@ddaanet": {options: {enabled: true}}}}`.
