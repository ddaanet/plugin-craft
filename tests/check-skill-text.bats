#!/usr/bin/env bats
# scripts/check-skill-text.sh: the wikilink check ignores code spans and
# fenced blocks; the memory-path and fact-filename checks do not.
# shellcheck disable=SC2016 # fixtures hold literal backticks and $

setup() {
    script="$BATS_TEST_DIRNAME/../scripts/check-skill-text.sh"
    root="$BATS_TEST_TMPDIR/skills"
    mkdir -p "$root/demo"
    f="$root/demo/SKILL.md"
}

# write_skill <line>...: the file's lines, one argument each
write_skill() {
    printf '%s\n' "$@" > "$f"
}

check() {
    run bash "$script" "$root"
}

@test "a wikilink in prose is refused with file:line:text" {
    write_skill 'intro' 'see [[some-fact]] for why'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:2:see [[some-fact]] for why"* ]]
    [[ "$output" == *"must not cite the memory store"* ]]
}

@test "bash double brackets in an inline code span pass" {
    write_skill 'use `[[ -n "$x" ]]` to test'
    check
    [ "$status" -eq 0 ]
}

@test "bash double brackets in a double-backtick span pass" {
    write_skill 'use ``a ` [[ -n "$x" ]] b`` to test'
    check
    [ "$status" -eq 0 ]
}

@test "a wikilink beside a code span on the same line is still refused" {
    write_skill 'run `ls` then see [[some-fact]]'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:1:"* ]]
}

@test "an unmatched backtick does not hide a wikilink" {
    write_skill 'a stray ` tick and [[some-fact]]'
    check
    [ "$status" -eq 1 ]
}

@test "a wikilink inside a backtick fence passes" {
    write_skill 'text' '```bash' 'if [[ -n "$x" ]]; then :; fi' '```' 'more'
    check
    [ "$status" -eq 0 ]
}

@test "a wikilink inside a tilde fence passes" {
    write_skill 'text' '~~~' 'if [[ -n "$x" ]]; then :; fi' '~~~' 'more'
    check
    [ "$status" -eq 0 ]
}

@test "a tilde fence is not closed by a backtick fence line" {
    write_skill '~~~' '```' '[[ -n "$x" ]]' '~~~'
    check
    [ "$status" -eq 0 ]
}

@test "a longer fence is not closed by a shorter one" {
    write_skill '````' '```' '[[ -n "$x" ]]' '````'
    check
    [ "$status" -eq 0 ]
}

@test "a wikilink after a fence closes is refused with its own line number" {
    write_skill 'text' '```' '[[ -n "$x" ]]' '```' 'then [[some-fact]]'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:5:then [[some-fact]]"* ]]
    [[ "$output" != *"$f:3:"* ]]
}

@test "a memory path in backticks is still refused" {
    write_skill 'see `memory/foo.md` for why'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:1:see \`memory/foo.md\` for why"* ]]
}

@test "a memory path inside a fence is still refused" {
    write_skill '```' 'cat memory/foo.md' '```'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:2:cat memory/foo.md"* ]]
}

@test "a bare fact filename in backticks is still refused" {
    write_skill 'see `green-is-not-evidence.md`'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:1:"* ]]
}

@test "a file name with a space is handled" {
    spaced="$root/demo/with space.md"
    printf '%s\n' 'prose' 'see [[some-fact]]' > "$spaced"
    printf '%s\n' 'use `[[ -n "$x" ]]`' > "$root/demo/SKILL.md"
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$spaced:2:see [[some-fact]]"* ]]
    [[ "$output" != *"SKILL.md"* ]]
}

@test "clean text exits 0 with no output" {
    write_skill 'plain prose' 'and `code`'
    check
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "a missing directory exits 2" {
    run bash "$script" "$BATS_TEST_TMPDIR/nonexistent"
    [ "$status" -eq 2 ]
}
