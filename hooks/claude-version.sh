#!/usr/bin/env bash
# PostToolUse hook for Bash: when `claude --version` reports a version other
# than the one this session is running, tell the agent which is which.
#
# Never blocks and never exits non-zero. Silent unless the two versions
# differ, so every failure (no jq, no transcript, unparsable stdout) is also
# silent.
#
# Residual bounds: only a bare `claude` program word is matched (see
# is-claude-version-call.sh), and without `jq` on PATH the hook says nothing.

main() {
    local dir command stdout transcript installed running payload
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || return 0
    command -v jq > /dev/null 2>&1 || return 0

    payload="$(cat)"
    command="$(jq -r '.tool_input.command // empty' <<< "$payload" 2> /dev/null)" || return 0
    [ -n "$command" ] || return 0
    bash "$dir/is-claude-version-call.sh" "$command" || return 0

    stdout="$(jq -r '.tool_response.stdout // empty' <<< "$payload" 2> /dev/null)" || return 0
    installed="$(installed_version "$stdout")" || return 0

    transcript="$(jq -r '.transcript_path // empty' <<< "$payload" 2> /dev/null)" || return 0
    [ -n "$transcript" ] || return 0
    running="$(bash "$dir/running-version.sh" "$transcript")" || return 0

    [ "$installed" != "$running" ] || return 0
    emit "$installed" "$running"
}

# First line of the tool's stdout shaped like `2.1.300 (Claude Code)`; the
# command may print other lines around it.
installed_version() {
    local line re='^([0-9]+(\.[0-9]+)+[^[:space:]]*)[[:space:]]+\(Claude Code\)'
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ $re ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
            return 0
        fi
    done <<< "$1"
    return 1
}

emit() {
    jq -n --arg installed "$1" --arg running "$2" '
        {hookSpecificOutput: {
            hookEventName: "PostToolUse",
            additionalContext:
                ("claude --version reports \($installed), the installed binary. This session is running \($running). Stamp observations about this session with \($running).")
        }}'
}

main || true
exit 0
