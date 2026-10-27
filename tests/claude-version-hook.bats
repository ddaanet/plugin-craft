#!/usr/bin/env bats
# The claude-version hook and its two helpers: hooks/running-version.sh
# (last non-null transcript version), hooks/is-claude-version-call.sh
# (command matcher) and hooks/claude-version.sh (PostToolUse annotation).
# shellcheck disable=SC2016 # fixtures hold literal $ and quotes

setup() {
    root="$BATS_TEST_DIRNAME/.."
    extractor="$root/hooks/running-version.sh"
    matcher="$root/hooks/is-claude-version-call.sh"
    hook="$root/hooks/claude-version.sh"
    work="$BATS_TEST_TMPDIR/dir with space"
    mkdir -p "$work/bin"
    transcript="$work/session one.jsonl"
}

# ---- hooks/running-version.sh -------------------------------------------

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

# ---- hooks/is-claude-version-call.sh ------------------------------------

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

@test "matcher accepts claude -v after ||" {
    matches 'false || claude -v'
}

# Residual bound: wrappers (`env X=1 claude -v`, `command claude -v`) and a
# path-qualified binary (`~/.local/bin/claude --version`) are not matched.
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

@test "matcher refuses claude --version mid-string inside echo" {
    no_match 'echo "run claude --version now"'
}

@test "matcher refuses unquoted echo claude --version" {
    no_match 'echo claude --version'
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

@test "matcher refuses claude --version after a comment word" {
    no_match 'cat versions.log # example; claude --version'
}

@test "matcher reads a # inside a word as literal" {
    matches 'echo a#b; claude -v'
}

@test "matcher ends a comment at the newline" {
    matches $'# note\nclaude -v'
}

@test "matcher joins a backslash-newline continuation" {
    matches $'claude \\\n--version'
}

@test "matcher keeps a backslash literal before an ordinary char in double quotes" {
    no_match 'claude "\-v"'
}

@test "matcher lets a backslash escape the double quote inside double quotes" {
    no_match 'echo "a\" ; claude -v"'
}

@test "matcher gives a backslash no escape power inside single quotes" {
    matches "echo 'a\\'; claude -v"
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
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.hookSpecificOutput.hookEventName' <<< "$output")" = "PostToolUse" ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
    [[ "$ctx" == *"2.1.281"* ]]
}

@test "hook on mismatch also fires for a subagent payload" {
    tline user 2.1.281 > "$transcript"
    p="$(payload 'claude -v' '2.1.300 (Claude Code)' "$transcript" \
        | jq '. + {agent_id:"agent-abc"}')"
    run_hook "$p"
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.281"* ]]
}

@test "hook is silent with exit 0 when installed equals running" {
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.281 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 for a command that is not claude --version" {
    tline user 2.1.281 > "$transcript"
    # The stdout is version-shaped at line start and differs from the running
    # version, and the command mentions claude, so only the matcher can keep
    # the hook silent.
    run_hook "$(payload 'grep -h "claude --version" notes.md' \
        '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent when claude --version follows a comment word on the line" {
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'cat versions.log # example; claude --version' \
        '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent when a double-quoted backslash keeps -v from being a flag" {
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude "\-v"' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook reports a mismatch for claude and --version split by a line continuation" {
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload $'claude \\\n--version' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
    [[ "$ctx" == *"2.1.281"* ]]
}

@test "hook takes the installed version from tool_response.stdout, not a re-run" {
    stub_claude 2.1.281
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
}

@test "hook stays silent when stdout matches the running version despite a differing stub" {
    stub_claude 2.1.300
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.281 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook reports a mismatch when stdout has other lines before the version" {
    tline user 2.1.281 > "$transcript"
    run_hook "$(payload 'echo start; claude --version' \
        $'start\n2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
    [[ "$ctx" == *"2.1.281"* ]]
}

@test "hook is silent with exit 0 on empty stdin" {
    run_hook ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 on malformed JSON stdin" {
    run_hook '{"tool_input": not json'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 when transcript_path names a nonexistent file" {
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)' \
        "$work/no such transcript.jsonl")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 when transcript_path is missing" {
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)')"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook is silent with exit 0 when the transcript has no version" {
    tline mode > "$transcript"
    run_hook "$(payload 'claude --version' '2.1.300 (Claude Code)' "$transcript")"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
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

# Cost must not grow quadratically with command length: the matcher runs on
# every Bash call, and heredocs of base64 text are routine. Both tests pass
# the stdout and `*claude*` prefilters, so the matcher itself is timed.
@test "hook finishes a 50 KB non-matching heredoc command within 5 seconds" {
    tline user 2.1.281 > "$transcript"
    big_command 'echo claude --version'
    run timeout 5 bash "$hook" < "$work/payload.json"
    [ "$status" -ne 124 ]
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "hook finishes a 50 KB heredoc command ending in claude --version within 5 seconds" {
    tline user 2.1.281 > "$transcript"
    big_command 'claude --version'
    run timeout 5 bash "$hook" < "$work/payload.json"
    [ "$status" -ne 124 ]
    [ "$status" -eq 0 ]
    ctx="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$output")"
    [[ "$ctx" == *"2.1.300"* ]]
}
