import 'plugin-dev/release.just'

# plugin-craft — dev recipes

# Default: list recipes
_default:
    @just --list

# Checks that run before every commit.
precommit: check-refs
    jq . .claude-plugin/plugin.json > /dev/null
    for f in scripts/*.sh hooks/*.sh lib/*.sh bin/plugin-craft-creation-status; do bash -n "$f" || exit 1; done
    shellcheck scripts/*.sh hooks/*.sh
    shellcheck -x bin/plugin-craft-creation-status lib/creation-status-readers.sh
    jq . hooks/hooks.json > /dev/null
    bash scripts/check-skill-text.sh
    plugin-dev/run-bats.sh tests/*.bats

# The gate `release` depends on. Add slow or paid checks here.
prerelease: precommit
