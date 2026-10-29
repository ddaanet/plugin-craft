#!/usr/bin/env bats
# bin/plugin-craft-creation-status: the complete repo, the output shape, odd paths, python and read-only.
# Each case builds a scratch repo from a complete one with a single fact broken,
# so the asserted `next` line can only come from that fact. Fixtures and
# assertions live in creation-status-helpers.bash.
# shellcheck disable=SC2016 # fixtures hold literal $ and backticks

bats_require_minimum_version 1.5.0

load creation-status-helpers

@test "complete repo: next none, exit 0" {
    mk_complete
    probe
    [ "$status" -eq 0 ]
    [ "$(next_field 2)" = none ]
    [ "$(next_field 3)" = - ]
    [ "$(next_field 4)" = "route complete; first release: see plugin-dev/README.md, Conventions" ]
    assert_status ok worktree
    assert_status ok python
    if printf '%s\n' "$output" | awk -F'\t' '$1=="missing"||$1=="blocked"{f=1} END{exit !f}'; then
        echo "unexpected missing/blocked line"
        return 1
    fi
}

@test "complete repo: stdout holds only the 13 status lines and a last next line" {
    mk_complete
    probe
    [ "$status" -eq 0 ]
    assert_shape
}

@test "path with a space and a quote: complete gives next none" {
    ROOT="$BATS_TEST_TMPDIR/it's a dir"
    mk_complete
    probe
    [ "$status" -eq 0 ]
    assert_next none -
}

@test "path with a space and a quote: the toolkit cd runs verbatim" {
    ROOT="$BATS_TEST_TMPDIR/it's a dir"
    mk_through_manifest
    probe
    [ "$status" -eq 1 ]
    assert_next toolkit shell
    action="$(next_field 4)"
    [[ "$action" == "cd "* ]]
    [ "$( (eval "${action%% && *} && pwd") )" = "$ROOT" ]
}

@test "shipped python file: python warn, exit unchanged" {
    mk_complete
    mkdir -p "$ROOT/bin"
    printf 'print(1)\n' > "$ROOT/bin/tool.py"
    printf '.claude-plugin\nskills\nbin\nREADME.md\n' > "$ROOT/dist.include"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status warn python
    [[ "$output" == *"tool.py"* ]]
    assert_next none -
}

@test "python shebang in a shipped extensionless file: python warn" {
    mk_complete
    mkdir -p "$ROOT/bin"
    printf '#!/usr/bin/env python3\nprint(1)\n' > "$ROOT/bin/tool"
    chmod +x "$ROOT/bin/tool"
    printf '.claude-plugin\nskills\nbin\nREADME.md\n' > "$ROOT/dist.include"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status warn python
    [[ "$output" == *"bin/tool"* ]]
}

@test "no dist.include: python in scripts/ still warns" {
    mk_complete
    rm "$ROOT/dist.include"
    mkdir -p "$ROOT/scripts"
    printf 'print(1)\n' > "$ROOT/scripts/tool.py"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status warn python
    [[ "$output" == *"scripts/tool.py"* ]]
}

@test "dist.include path with a space holding python: python warn" {
    mk_complete
    mkdir -p "$ROOT/my tools"
    printf 'print(1)\n' > "$ROOT/my tools/run.py"
    printf '.claude-plugin\nskills\nmy tools\nREADME.md\n' > "$ROOT/dist.include"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status warn python
    [[ "$output" == *"my tools/run.py"* ]]
}

@test "dist.include literal foo..bar holding python: python warn" {
    mk_complete
    mkdir -p "$ROOT/foo..bar"
    printf 'print(1)\n' > "$ROOT/foo..bar/run.py"
    printf '.claude-plugin\nskills\nfoo..bar\nREADME.md\n' > "$ROOT/dist.include"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status warn python
    [[ "$output" == *"foo..bar/run.py"* ]]
}

@test "dist.include with a glob line: python skip carrying dist.sh's refusal" {
    mk_complete
    printf '.claude-plugin\nskills\n*.md\n' > "$ROOT/dist.include"
    commit_all
    probe
    assert_status skip python
    printf '%s\n' "$output" | awk -F'\t' '$1=="skip" && $2=="python" && $3 ~ /dist:/ {f=1} END {exit !f}'
}

@test "dist.include without plugin-dev/dist.sh: python skip" {
    mk_complete
    rm "$ROOT/plugin-dev/dist.sh"
    commit_all
    probe
    assert_status skip python
    printf '%s\n' "$output" | awk -F'\t' '$1=="skip" && $2=="python" && $3 ~ /not vendored/ {f=1} END {exit !f}'
}

@test "python outside the shipped paths: python ok" {
    mk_complete
    mkdir -p "$ROOT/docs"
    printf 'print(1)\n' > "$ROOT/docs/tool.py"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status ok python
}

@test "read-only: status, index and file listing identical before and after" {
    mk_repo
    add_gitlore
    add_manifest
    git -C "$ROOT" add .gitmodules memory # leaves staged and untracked state
    # A tracked file whose stat no longer matches the index: plain `git status`
    # rewrites the index to refresh it, which the Post clause forbids.
    touch -t 202001010000 "$ROOT/README.md"
    snapshot() {
        # Index first, and nothing below may refresh it.
        cksum < "$ROOT/.git/index"
        git --no-optional-locks -C "$ROOT" status --porcelain
        (cd "$ROOT" && find . -path ./.git -prune -o -print | LC_ALL=C sort)
        (cd "$ROOT" && find . -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort)
        git --no-optional-locks -C "$ROOT" ls-files -s
    }
    before="$(snapshot)"
    probe
    # The probe ran: a missing script would leave the snapshots trivially equal.
    [ -n "$(next_field 2)" ]
    after="$(snapshot)"
    [ "$before" = "$after" ]
}

@test "not a directory: exit 2, stdout empty" {
    echo x > "$BATS_TEST_TMPDIR/a file"
    run --separate-stderr "$PROBE" "$BATS_TEST_TMPDIR/a file"
    [ "$status" -eq 2 ]
    [ -z "$output" ]
    [ -n "$stderr" ]
}
