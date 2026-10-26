#!/usr/bin/env bash
# Print the version of the Claude Code process that wrote a transcript: the
# last non-null `version` field. Usage: running-version.sh <transcript.jsonl>
#
# Exit 1 with empty output when there is none, the file is unreadable, or `jq`
# is missing. Many line types (`mode`, `atis-latch`, `last-prompt`, ...)
# carry no version, so the last line is not enough; the window below is a
# bound, and a tail with no versioned line inside it reads as "none".

WINDOW=400

main() {
    local file="${1-}" version
    [ -n "$file" ] && [ -r "$file" ] || return 1
    command -v jq > /dev/null 2>&1 || return 1
    # -R plus fromjson? skips a line cut in half by the window or by a writer
    # still appending.
    version="$(tail -n "$WINDOW" -- "$file" \
        | jq -R -r 'fromjson? | .version? | select(type == "string" and . != "")' \
            2> /dev/null | tail -n 1)" || return 1
    [ -n "$version" ] || return 1
    printf '%s\n' "$version"
}

main "$@"
