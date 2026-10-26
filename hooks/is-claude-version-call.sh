#!/usr/bin/env bash
# Exit 0 iff a simple command inside the given shell command string is
# `claude` with --version or -v among its arguments, else exit 1.
# Usage: is-claude-version-call.sh <command-string>
#
# The string is split into simple commands on unquoted `&&`, `||`, `;`, `|`,
# `&`, parentheses and newlines, and each is tokenised honouring quotes, so
# `echo "claude --version"` and `git commit -m "claude -v"` do not match.
#
# Residual bounds: wrappers (`env X=1 claude -v`, `command claude -v`) and a
# path-qualified binary (`~/.local/bin/claude --version`) are not matched, and
# expansions, heredocs and `$(...)` inside quotes are not interpreted.

main() {
    local cmd="${1-}" ch quote="" word="" have_word=0 i
    local -a words=()
    for ((i = 0; i < ${#cmd}; i++)); do
        ch="${cmd:i:1}"
        if [ "$quote" = "'" ]; then
            if [ "$ch" = "'" ]; then quote=""; else word+="$ch"; fi
            continue
        fi
        if [ "$ch" = "\\" ]; then
            word+="${cmd:i+1:1}"
            have_word=1
            i=$((i + 1))
            continue
        fi
        if [ -n "$quote" ]; then
            if [ "$ch" = "$quote" ]; then quote=""; else word+="$ch"; fi
            continue
        fi
        case "$ch" in
            "'" | '"') quote="$ch"; have_word=1 ;;
            [[:space:]] | '&' | '|' | ';' | '(' | ')')
                if [ "$have_word" -eq 1 ]; then words+=("$word"); fi
                word=""
                have_word=0
                if [ "$ch" != " " ] && [ "$ch" != $'\t' ]; then
                    if is_version_call "${words[@]+"${words[@]}"}"; then return 0; fi
                    words=()
                fi
                ;;
            *) word+="$ch"; have_word=1 ;;
        esac
    done
    if [ "$have_word" -eq 1 ]; then words+=("$word"); fi
    is_version_call "${words[@]+"${words[@]}"}"
}

# Args: the words of one simple command.
is_version_call() {
    local w
    # Skip leading VAR=value assignments.
    while [ "$#" -gt 0 ] && [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do shift; done
    [ "$#" -gt 0 ] && [ "$1" = "claude" ] || return 1
    shift
    for w in "$@"; do
        if [ "$w" = "--version" ] || [ "$w" = "-v" ]; then return 0; fi
    done
    return 1
}

main "$@"
