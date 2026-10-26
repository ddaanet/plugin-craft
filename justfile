import 'plugin-dev/release.just'

# plugin-craft — dev recipes

# Default: list recipes
_default:
    @just --list

# Checks that run before every commit.
precommit: check-refs
    jq . .claude-plugin/plugin.json > /dev/null
    bash -n scripts/*.sh hooks/*.sh
    shellcheck scripts/*.sh hooks/*.sh
    jq . hooks/hooks.json > /dev/null
    bash scripts/check-skill-text.sh
    plugin-dev/run-bats.sh tests/*.bats

# The gate `release` depends on. Add slow or paid checks here.
prerelease: precommit
