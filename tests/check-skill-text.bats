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

@test "a code span crossing a line break does not mask prose on its closing line" {
    write_skill 'Use `foo' 'bar` then [[some-fact]] and `baz`.'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:2:bar\` then [[some-fact]] and \`baz\`."* ]]
}

@test "a hard-wrapped span pair does not mask a wikilink between spans" {
    write_skill \
        'instruction** — `You should create...`, `You need to configure...`, `You can' \
        'use...`. Reflexive intensifiers, per [[some-fact]], (`do not verify it yourself`), possessives'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:2:use...\`. Reflexive intensifiers, per [[some-fact]]"* ]]
}

@test "double brackets inside a span that crosses a line break pass" {
    write_skill 'test with `if [[ -n "$x" ]];' 'then :; fi` here'
    check
    [ "$status" -eq 0 ]
}

@test "a blank line ends a paragraph, so a stray backtick does not pair across it" {
    write_skill 'a stray ` tick' '' 'see [[some-fact]] then ` another'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:3:"* ]]
}

@test "a wikilink after a paragraph that follows a fence keeps its line number" {
    write_skill 'one' '```' '[[ x ]]' '```' 'two `a' 'b` three' '' 'see [[some-fact]]'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:8:see [[some-fact]]"* ]]
}

@test "an escaped backtick opens no span" {
    write_skill 'literal \` and `[[ x ]]`'
    check
    [ "$status" -eq 0 ]
}

@test "an escaped backslash before a backtick leaves the backtick a span delimiter" {
    write_skill '\\`a` [[some-fact]] `b`'
    check
    [ "$status" -eq 1 ]
}

@test "a triple backtick followed by an info string with a backtick opens no fence" {
    write_skill '```js` is not a fence opener' 'see [[some-fact]]'
    check
    [ "$status" -eq 1 ]
    [[ "$output" == *"$f:2:see [[some-fact]]"* ]]
}

@test "an unreadable file is reported and exits 2" {
    if [ "$(id -u)" -eq 0 ]; then
        skip "root reads mode-000 files"
    fi
    write_skill 'plain prose'
    chmod 000 "$f"
    check
    chmod 644 "$f"
    [ "$status" -eq 2 ]
    [[ "$output" == *"could not scan: $f"* ]]
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

@test "clean text exits 0 with a sign-off naming the checks and file count" {
    write_skill 'plain prose' 'and `code`'
    check
    [ "$status" -eq 0 ]
    [ "$output" = "check-skill-text: no wikilinks outside code, memory/ paths or source-fact filenames in 1 files" ]
}

@test "a missing directory exits 2" {
    run bash "$script" "$BATS_TEST_TMPDIR/nonexistent"
    [ "$status" -eq 2 ]
}
