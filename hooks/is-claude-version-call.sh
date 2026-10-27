#!/usr/bin/env bash
# Exit 0 iff a simple command inside the given shell command string is
# `claude` with --version or -v among its arguments, else exit 1.
# Usage: is-claude-version-call.sh <command-string>
#
# One portable awk program (POSIX awk only: mawk, gawk and BSD awk) walks the
# string once. It splits simple commands on unquoted `&&`, `||`, `;`, `|`,
# `&`, parentheses and newlines, and tokenises each honouring quotes, so
# `echo "claude --version"` and `git commit -m "claude -v"` do not match.
#
# Quoting as modelled: inside '...' everything is literal. Outside single
# quotes, backslash-newline is a line continuation and is removed. Unquoted, a
# backslash makes the next character literal. Inside "...", a backslash
# escapes only $, `, ", \ and newline; before any other character it is
# literal. An unquoted # at the start of a word starts a comment that runs to
# the next newline (the newline still ends the simple command); a # inside a
# word is literal. A carriage return, form feed or vertical tab ends the
# current simple command like a newline does.
#
# Residual bounds: wrappers (`env X=1 claude -v`, `command claude -v`) and a
# path-qualified binary (`~/.local/bin/claude --version`) are not matched, nor
# is a command led by a reserved word (`time claude -v`, `{ claude -v; }`,
# `if claude -v`). Expansions, heredoc bodies (read as ordinary words, so an
# apostrophe in one opens a quote) and `$(...)` or backticks inside quotes are
# not interpreted. An unquoted backtick substitution (`v=`claude -v``) is not
# matched: the backtick reads as a word character. A command over the kernel's
# per-string limit (about 128 KB on Linux) fails in claude-version.sh, which
# passes it as an argument (E2BIG, "Argument list too long", rc 126), and reads
# as no match. The program is not NUL-safe, which the environment cannot carry.

main() {
    local rc=0
    CMD="${1-}" LC_ALL=C awk "$(awk_program)" || rc=$?
    [ "$rc" -eq 0 ]
}

awk_program() {
    cat << 'AWK'
BEGIN {
    s = ENVIRON["CMD"]
    n = length(s)
    q = ""; word = ""; have = 0; wn = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q == "'") {
            if (c == "'") q = ""; else word = word c
            continue
        }
        if (c == "\\") {
            d = substr(s, i + 1, 1)
            if (d == "\n") { i++; continue }
            if (q == "\"" && d != "$" && d != "`" && d != "\"" && d != "\\") {
                word = word c
            } else {
                word = word d; i++
            }
            have = 1
            continue
        }
        if (q == "\"") {
            if (c == "\"") q = ""; else word = word c
            continue
        }
        if (c == "'" || c == "\"") { q = c; have = 1; continue }
        if (c == "#" && !have) {
            while (i < n && substr(s, i + 1, 1) != "\n") i++
            continue
        }
        if (c == " " || c == "\t") {
            if (have) words[++wn] = word
            word = ""; have = 0
        } else if (c == "\n" || c == "\r" || c == "\f" || c == "\v" || c == "&" ||
                   c == "|" || c == ";" || c == "(" || c == ")") {
            if (have) words[++wn] = word
            word = ""; have = 0
            if (version_call()) exit 0
            wn = 0
        } else {
            word = word c; have = 1
        }
    }
    if (have) words[++wn] = word
    exit (version_call() ? 0 : 1)
}

# The words[1..wn] of one simple command.
function version_call(   k, j) {
    k = 1
    while (k <= wn && words[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) k++
    if (k > wn || words[k] != "claude") return 0
    for (j = k + 1; j <= wn; j++)
        if (words[j] == "--version" || words[j] == "-v") return 1
    return 0
}
AWK
}

main "$@"
