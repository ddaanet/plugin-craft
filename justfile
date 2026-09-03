import 'plugin-dev/release.just'

# plugin-craft — dev recipes

# Default: list recipes
_default:
    @just --list

# Checks that run before every commit.
precommit:
    jq . .claude-plugin/plugin.json > /dev/null
    bash -n scripts/*.sh
    bash scripts/check-skill-text.sh

# The gate `release` depends on. Add slow or paid checks here.
prerelease: precommit
