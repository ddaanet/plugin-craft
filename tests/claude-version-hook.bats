#!/usr/bin/env bats
# The claude-version hook and its two helpers: scripts/running-version.sh
# (last non-null transcript version), scripts/is-claude-version-call.sh
# (command matcher) and hooks/claude-version.sh (PostToolUse annotation).
# shellcheck disable=SC2016 # fixtures hold literal $ and quotes

setup() {
    root="$BATS_TEST_DIRNAME/.."
    extractor="$root/scripts/running-version.sh"
    matcher="$root/scripts/is-claude-version-call.sh"
    hook="$root/hooks/claude-version.sh"
    work="$BATS_TEST_TMPDIR/dir with space"
    mkdir -p "$work/bin"
    transcript="$work/session one.jsonl"
}

# ---- scripts/running-version.sh -------------------------------------------

# tline <type> [version]: one transcript line; no version arg means null
tline() {
    if [ -n "${2:-}" ]; then
        printf '{"type":"%s","version":"%s"}\n' "$1" "$2"
    else
        printf '{"type":"%s","version":null}\n' "$1"
    fi
}

extract() {
    run bash "$extractor" "$transcript"
}

@test "extractor skips trailing null-version lines after a versioned one" {
    {
        tline user 2.1.281
        tline assistant 2.1.281
        tline atis-latch
        tline last-prompt
    } > "$transcript"
    extract
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.281" ]
}

@test "extractor treats a line with no version key like a null one" {
    {
        tline user 2.1.281
        printf '{"type":"mode"}\n'
    } > "$transcript"
    extract
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.281" ]
}

@test "extractor exits 1 with empty output when no line has a version" {
    {
        tline mode
        tline agent-name
    } > "$transcript"
    extract
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "extractor prints the last version when versions are mixed" {
    {
        tline user 2.1.281
        tline assistant 2.1.283
        tline atis-latch
    } > "$transcript"
    extract
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.283" ]
}

@test "extractor reads a transcript whose path contains spaces" {
    tline user 2.1.290 > "$transcript"
    [[ "$transcript" == *" "* ]]
    extract
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.290" ]
}

@test "extractor exits 1 with empty output on an empty file" {
    : > "$transcript"
    extract
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

# ---- scripts/is-claude-version-call.sh ------------------------------------

# Exit 0 iff a simple command is `claude` with --version or -v.
matches() {
    run bash "$matcher" "$1"
    [ "$status" -eq 0 ]
}

no_match() {
    run bash "$matcher" "$1"
    [ "$status" -eq 1 ]
}

@test "matcher accepts bare claude --version" {
    matches 'claude --version'
}

@test "matcher accepts bare claude -v" {
    matches 'claude -v'
}

@test "matcher accepts claude --version after &&" {
    matches 'cd /tmp && claude --version'
}

@test "matcher accepts claude --version before a pipe" {
    matches 'claude --version | head -1'
}

@test "matcher accepts claude -v on a later line" {
    matches $'echo start\nclaude -v'
}

@test "matcher accepts claude --version after a semicolon" {
    matches 'true; claude --version'
}

@test "matcher accepts claude --version after a leading env assignment" {
    matches 'FOO=1 claude --version'
}

@test "matcher accepts claude -p --version (--version among its arguments)" {
    # Plan: the program word is claude and --version/-v is among its
    # arguments, so extra flags do not hide the call.
    matches 'claude -p --version'
}

@test "matcher refuses claude --version quoted inside echo" {
    no_match 'echo "claude --version"'
}

@test "matcher refuses claude -v inside a git commit message" {
    no_match 'git commit -m "claude -v"'
}

@test "matcher refuses claude --version as a grep pattern" {
    no_match 'grep "claude --version" notes.md'
}

@test "matcher refuses -v on other programs" {
    no_match 'grep -v foo file.txt'
}

@test "matcher refuses claude without a version flag" {
    no_match 'claude -p hello'
}

@test "matcher refuses an empty command" {
    no_match ''
}

# ---- hooks/claude-version.sh ----------------------------------------------

# stub_claude <version>: a `claude` first on PATH printing that version
stub_claude() {
    printf '#!/bin/sh\necho "%s (Claude Code)"\n' "$1" > "$work/bin/claude"
    chmod +x "$work/bin/claude"
}

# payload <command> <stdout> [transcript_path]: PostToolUse JSON on stdout
payload() {
    jq -n --arg c "$1" --arg o "$2" --arg t "${3-}" '
        {hook_event_name:"PostToolUse", tool_name:"Bash",
         tool_input:{command:$c}, tool_response:{stdout:$o}}
        + (if $t == "" then {} else {transcript_path:$t} end)'
}

run_hook() {
    PATH="$work/bin:$PATH" run bash -c 'bash "$1" <<< "$2"' _ "$hook" "$1"
}

@test "hook on mismatch names both versions in additionalContext" {
    stub_claude 2.1.300
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.hookSpecificOutput.hookEventName' <<< "$output")" = "PostToolUse" ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
    [[ "$ctx" == *"2.1.281"* ]]
}

@test "hook on mismatch also fires for a subagent payload" {
    stub_claude 2.1.300
    tline user 2.1.281 > "$transcript"
    p="$(payload 'claude -v' '2.1.300 (Claude Code)' "$transcript" \
        | jq '. + {agent_id:"agent-abc"}')"
    run_hook "$p"
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.281"* ]]
}

@test "hook is silent with exit 0 when installed equals running" {
    stub_claude 2.1.281
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.281 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 for a command that is not claude --version" {
    # Mismatching versions on disk, so only the matcher can keep it silent.
    stub_claude 2.1.300
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'echo "claude --version"' 'claude --version' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 when transcript_path is missing" {
    stub_claude 2.1.300
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)')"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 when the transcript has no version" {
    stub_claude 2.1.300
    tline mode > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
