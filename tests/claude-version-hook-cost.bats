#!/usr/bin/env bats
# Cost of hooks/claude-version.sh on very long Bash commands, and the
# `within` helper that bounds it. Kept apart from claude-version-hook.bats,
# which holds the matcher and annotation behaviour.
# shellcheck disable=SC2016 # fixtures hold literal $ and quotes

setup() {
    root="$BATS_TEST_DIRNAME/.."
    hook="$root/hooks/claude-version.sh"
    work="$BATS_TEST_TMPDIR/dir with space"
    mkdir -p "$work"
    transcript="$work/session one.jsonl"
}

# Cost must not grow quadratically with command length: the matcher runs on
# every Bash call, and heredocs of base64 text are routine. Both tests pass
# the stdout and `*claude*` prefilters, so the matcher itself is timed.
@test "hook finishes a 50 KB non-matching heredoc command within 5 seconds" {
    tline user 2.1.281 > "$transcript"
    big_command 'echo claude --version'
    run within 5 "$work/payload.json" bash "$hook"
    [ "$status" -ne 124 ]
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook finishes a 50 KB heredoc command ending in claude --version within 5 seconds" {
    tline user 2.1.281 > "$transcript"
    big_command 'claude --version'
    run within 5 "$work/payload.json" bash "$hook"
    [ "$status" -ne 124 ]
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
}

# A child that outlives the limit would hold run's output pipe for ~30 s if
# the watchdog killed only the leader; the group kill must reap it.
@test "within reports 124 and reaps a child that outlives the limit" {
    SECONDS=0
    run within 1 /dev/null bash -c 'sleep 30; :'
    [ "$status" -eq 124 ]
    [ "$SECONDS" -lt 10 ]
}

# ---- helpers ------------------------------------------------------------

# tline <type> <version>: one transcript line
tline() {
    printf '{"type":"%s","version":"%s"}\n' "$1" "$2"
}

# big_command <last line>: a heredoc of base64 text of at least 50 KB, then
# the given last line, in $work/command.txt
big_command() {
    {
        printf "cat > out.b64 <<'EOF'\n"
        seq 1 12000 | base64
        printf 'EOF\n%s' "$1"
    } > "$work/command.txt"
    [ "$(wc -c < "$work/command.txt")" -ge 50000 ]
    jq -n --rawfile c "$work/command.txt" --arg t "$transcript" '
        {hook_event_name:"PostToolUse", tool_name:"Bash",
         tool_input:{command:$c}, tool_response:{stdout:"2.1.300 (Claude Code)"},
         transcript_path:$t}' > "$work/payload.json"
}

# within <secs> <stdin-file> <cmd...>: run cmd with stdin from the file in its
# own process group; TERM the whole group after <secs>. Status 124 when the
# watchdog fired, the command's own status otherwise. No timeout(1): macOS
# ships none. Stdin is a file because a background job otherwise gets
# /dev/null.
within() {
    (
        set -m
        local secs="$1" input="$2" fired cmd_pid wd_pid status
        shift 2
        fired="$(mktemp "${TMPDIR:-/tmp}/within.XXXXXX")"
        rm -f "$fired"
        "$@" < "$input" &
        cmd_pid=$!
        (
            sleep "$secs"
            : > "$fired"
            kill -TERM -- "-$cmd_pid" 2> /dev/null
        ) > /dev/null 2>&1 &
        wd_pid=$!
        set +m # groups exist; silence job-status notices on stderr
        wait "$cmd_pid"
        status=$?
        kill -TERM -- "-$wd_pid" 2> /dev/null
        wait "$wd_pid" 2> /dev/null
        if [ -e "$fired" ]; then
            rm -f "$fired"
            exit 124
        fi
        exit "$status"
    )
}
