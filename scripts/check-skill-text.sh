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

pattern='\[\[[^]]+\]\]'                                  # wikilink
pattern="$pattern|(^|[^A-Za-z0-9_/.-])memory/"           # memory-store path
pattern="$pattern|(^|[^A-Za-z0-9_/-])($slugs)\.md"       # bare fact filename

status=0
while IFS= read -r -d '' f; do
    if hits=$(grep -nE "$pattern" -- "$f"); then
        printf '%s\n' "$hits" | awk -v F="$f" '{print F ":" $0}'
        status=1
    fi
done < <(find "$root" -type f -name '*.md' -print0)

[ "$status" -eq 0 ] || printf '\nskill text must not cite the memory store; inline the criteria instead\n' >&2
exit "$status"
