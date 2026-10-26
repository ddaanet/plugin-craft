#!/usr/bin/env bash
# Refuse memory-store citations in distributed skill text.
#
# Skills ship to consumers who do not have this repository's memory store, so a
# wikilink or a memory path in skills/ dangles for every one of them. The
# criteria those links point at are inlined at write time instead.
#
# Covers skills/**/*.md. Paths are NUL-delimited throughout, so a name
# containing spaces or newlines is handled; a name containing a colon still
# prints, only ambiguously against the line number.
#
# Only the wikilink check skips code: `[[ ... ]]` is bash syntax, and skill
# prose must be able to name it inside a code span or a fenced block. A memory
# path or a fact filename dangles for a consumer wherever it sits, so those
# checks read every line as written.
#
# The code-skipping is a line scanner, not a Markdown parser. Residual bounds:
# - a code span that opens on one line and closes on a later one is not
#   recognised, so a wikilink inside it is refused;
# - an indented (four-space) code block is not recognised, only fences;
# - a fence may be indented by any amount, not only up to three spaces, so a
#   fence nested in a list item counts, and a fence-looking line in an
#   indented code block is taken for a fence;
# - an unclosed fence runs to the end of the file, as in CommonMark.
set -uo pipefail

root="${1:-skills}"
[ -d "$root" ] || { printf 'no such directory: %s\n' "$root" >&2; exit 2; }

# Source-fact slugs whose bare filename must never appear in shipped text.
slugs='hook-output-channels|hook-input-schema|posttooluse-print-mode'
slugs="$slugs|skill-description-purpose-first|imperative-form-scope"
slugs="$slugs|skill-bundled-scripts|stale-plugin-code|claude-plugin-dev"
slugs="$slugs|sandbox-effects|classifier-denied-self-config|claude-project-dir"
slugs="$slugs|cc-subagent-approval|test-the-invocation-path|cc-agent-discovery"
slugs="$slugs|sessionstart-resume-cwd|cc-command-namespacing|directive-states-acts"
slugs="$slugs|cc-worktree-memory-freeze|green-is-not-evidence"

# Checked on every line, code included. The wikilink pattern is in the awk
# program below, since it applies to the line with code removed.
pattern="(^|[^A-Za-z0-9_/.-])memory/"                    # memory-store path
pattern="$pattern|(^|[^A-Za-z0-9_/-])($slugs)\.md"       # bare fact filename

# Prints FILE:LINE:TEXT for each offending line, numbered as in the file, and
# exits 1 if it printed any. The pattern arrives through the environment
# because awk -v would process its backslash escapes.
# shellcheck disable=SC2016 # awk source, not shell: nothing should expand
awk_prog='
{
    hit = 0
    if (fence != "") {
        if (closes($0)) fence = ""
    } else if (!opens($0)) {
        if (mask($0) ~ /\[\[[^]]+\]\]/) hit = 1
    }
    if ($0 ~ ENVIRON["CST_PATTERN"]) hit = 1
    if (hit) { print FILENAME ":" NR ":" $0; found = 1 }
}
END { exit found ? 1 : 0 }

# Sets fch, frun and frest when the line starts (after blanks) with a run of
# three or more backticks or tildes; returns the fence character, else "".
function fence_of(line,   t, c, n) {
    t = line
    sub(/^[ \t]+/, "", t)
    c = substr(t, 1, 1)
    if (c != "`" && c != "~") return ""
    n = 0
    while (substr(t, n + 1, 1) == c) n++
    if (n < 3) return ""
    fch = c; frun = n; frest = substr(t, n + 1)
    return c
}

# An opening fence sets fence and flen. A backtick fence whose info string
# holds a backtick is an inline code span, not a fence.
function opens(line) {
    if (fence_of(line) == "") return 0
    if (fch == "`" && index(frest, "`") > 0) return 0
    fence = fch; flen = frun
    return 1
}

# A closing fence uses the opener character, is at least as long, and has
# nothing after it.
function closes(line) {
    return fence_of(line) == fence && frun >= flen && frest ~ /^[ \t\r]*$/
}

# The line with each code span replaced by one space. A span is a backtick run
# closed by the next run of exactly the same length; a run with no closer is
# literal text, and a backslash-escaped backtick is not a run.
function mask(s,   out, i, j, k, m, n, len, c, found) {
    out = ""; i = 1; len = length(s)
    while (i <= len) {
        c = substr(s, i, 1)
        if (c == "\\" && substr(s, i + 1, 1) == "`") { out = out c "`"; i += 2; continue }
        if (c != "`") { out = out c; i++; continue }
        j = i
        while (j <= len && substr(s, j, 1) == "`") j++
        n = j - i
        found = 0; k = j
        while (k <= len) {
            if (substr(s, k, 1) != "`") { k++; continue }
            m = k
            while (m <= len && substr(s, m, 1) == "`") m++
            if (m - k == n) { found = 1; break }
            k = m
        }
        if (found) { out = out " "; i = m }
        else { out = out substr(s, i, n); i = j }
    }
    return out
}
'

status=0 hits=0
while IFS= read -r -d '' f; do
    CST_PATTERN="$pattern" awk "$awk_prog" "$f"
    case $? in
        0) ;;
        1) hits=1; [ "$status" -ne 0 ] || status=1 ;;
        *) printf 'could not scan: %s\n' "$f" >&2; status=2 ;;
    esac
done < <(find "$root" -type f -name '*.md' -print0)

[ "$hits" -eq 0 ] || printf '\nskill text must not cite the memory store; inline the criteria instead\n' >&2
exit "$status"
