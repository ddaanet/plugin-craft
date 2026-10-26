#!/usr/bin/env bats
# hooks/hooks.json registers only scripts that exist, are executable, and
# ship in the plugin.
# shellcheck disable=SC2016 # the ${CLAUDE_PLUGIN_ROOT} placeholder is literal

setup() {
    root="$BATS_TEST_DIRNAME/.."
}

@test "every registered hook command resolves to an executable file" {
    count=0
    while IFS= read -r -d '' cmd; do
        path="${cmd//\"/}"
        [[ "$path" == '${CLAUDE_PLUGIN_ROOT}/'* ]]
        file="$root/${path#'${CLAUDE_PLUGIN_ROOT}/'}"
        [ -f "$file" ]
        [ -x "$file" ]
        count=$((count + 1))
    done < <(jq -j '.hooks[][].hooks[].command + "\u0000"' "$root/hooks/hooks.json")
    [ "$count" -ge 1 ]
}

@test "claude-version is registered for PostToolUse on Bash" {
    run jq -r '.hooks.PostToolUse[] | select(.matcher == "Bash") | .hooks[].command' \
        "$root/hooks/hooks.json"
    [ "$status" -eq 0 ]
    [[ "$output" == *'/hooks/claude-version.sh'* ]]
}

@test "hooks directory ships" {
    grep -qx hooks "$root/dist.include"
}
