# plugin-craft — dev recipes

# Default: list recipes
_default:
    @just --list

# Checks that run before every commit. Stub — fill in as the plugin grows.
precommit:
    true

# The gate `release` depends on. Add slow or paid checks here.
prerelease: precommit
    true
