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
    # Cheapest checks first: this runs on every Bash call, and the matcher is
    # linear-per-character bash. A call that printed no Claude version, or
    # whose command never mentions claude, never reaches it.
    stdout="$(jq -r '.tool_response.stdout // empty' <<< "$payload" 2> /dev/null)" || return 0
    installed="$(installed_version "$stdout")" || return 0

    command="$(jq -r '.tool_input.command // empty' <<< "$payload" 2> /dev/null)" || return 0
    case "$command" in *claude*) ;; *) return 0 ;; esac
    bash "$dir/is-claude-version-call.sh" "$command" || return 0

    transcript="$(jq -r '.transcript_path // empty' <<< "$payload" 2> /dev/null)" || return 0
    [ -n "$transcript" ] || return 0
    running="$(bash "$dir/running-version.sh" "$transcript")" || return 0

    [ "$installed" != "$running" ] || return 0
    emit "$installed" "$running"
}

# First line of the tool's stdout shaped like `2.1.300 (Claude Code)`; the
# command may print other lines around it. One regex over the whole string,
# not a line loop, since stdout can be large.
installed_version() {
    local re=$'(^|\n)([0-9]+(\.[0-9]+)+[^[:space:]]*)[[:space:]]+\(Claude Code\)'
    [[ "$1" =~ $re ]] || return 1
    printf '%s\n' "${BASH_REMATCH[2]}"
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
