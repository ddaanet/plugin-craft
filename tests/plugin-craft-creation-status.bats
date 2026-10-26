#!/usr/bin/env bats
# bin/plugin-craft-creation-status: reports where a repo stands on the route to
# a ddaanet-shaped plugin, one tab-separated line per check and a `next` line.
# Each case builds a scratch repo from a complete one with a single fact broken,
# so the asserted `next` line can only come from that fact. No network: the
# toolkit is a stub plugin-dev/, gitlore a .gitmodules entry plus a gitlink.
# shellcheck disable=SC2016 # fixtures hold literal $ and backticks
# shellcheck disable=SC2030,SC2031 # ROOT is reassigned per test on purpose

bats_require_minimum_version 1.5.0

setup() {
    PROBE="$BATS_TEST_DIRNAME/../bin/plugin-craft-creation-status"
    # A blank in every fixture path: whitespace safety is checked everywhere.
    ROOT="$BATS_TEST_TMPDIR/my repo"
    cd "$BATS_TEST_TMPDIR" || return 1
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
}

# ---- fixture builders: each writes files into $ROOT, none commits ----------

mk_repo() { # git repo at $ROOT holding one commit of a README
    mkdir -p "$ROOT"
    git -C "$ROOT" init -q
    echo readme > "$ROOT/README.md"
    git -C "$ROOT" add README.md
    git -C "$ROOT" commit -q -m init
}

commit_all() {
    git -C "$ROOT" add -A
    git -C "$ROOT" commit -q --allow-empty -m "fixture"
}

add_gitlore() {
    printf '[submodule "gitlore-memory"]\n\tpath = memory\n\turl = https://github.com/o/mem.git\n' \
        > "$ROOT/.gitmodules"
    git -C "$ROOT" update-index --add \
        --cacheinfo 160000,1111111111111111111111111111111111111111,memory
    mkdir -p "$ROOT/memory" "$ROOT/.gitlore/bin"
    printf '#!/bin/sh\n' > "$ROOT/.gitlore/bin/claude"
    chmod +x "$ROOT/.gitlore/bin/claude"
    printf 'PATH_add .gitlore/bin\n' > "$ROOT/.envrc"
}

add_manifest() {
    mkdir -p "$ROOT/.claude-plugin"
    printf '{"name":"demo","version":"0.1.0"}\n' > "$ROOT/.claude-plugin/plugin.json"
}

add_toolkit_files() { # vendored copy and the justfile import, hooks unwired
    mkdir -p "$ROOT/plugin-dev"
    echo 0.12.0 > "$ROOT/plugin-dev/VERSION"
    : > "$ROOT/plugin-dev/release.just"
}

add_toolkit_wiring() { # the three commands install.sh spells, verbatim
    mkdir -p "$ROOT/.claude"
    cat > "$ROOT/.claude/settings.json" <<'EOF'
{"hooks":{
 "PreToolUse":[
  {"matcher":"Write|Edit","hooks":[{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/plugin-dev/version-guard.sh\""}]},
  {"matcher":"Write|Edit|NotebookEdit","hooks":[{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/plugin-dev/dogfood.sh\" pre-tool"}]}],
 "SessionStart":[
  {"hooks":[{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/plugin-dev/dogfood.sh\" session-start"}]}]}}
EOF
}

add_justfile() { # a justfile that compiles, with the recipes the route wants
    cat > "$ROOT/justfile" <<'EOF'
import 'plugin-dev/release.just'

check-refs:
    true

precommit: check-refs
    true

prerelease: precommit
EOF
}

add_envrc() {
    printf 'source_up_if_exists\nPATH_add .gitlore/bin\nPATH_add plugin-dev/bin\n' \
        > "$ROOT/.envrc"
}

add_ignore() { printf '/dist/plugin/\n' > "$ROOT/.gitignore"; }

add_dist_include() { printf '.claude-plugin\nskills\nREADME.md\n' > "$ROOT/dist.include"; }

add_copy() { # the dogfood copy: ignored, never committed
    mkdir -p "$ROOT/dist/plugin/.claude-plugin"
    cp "$ROOT/.claude-plugin/plugin.json" "$ROOT/dist/plugin/.claude-plugin/plugin.json"
}

add_origin() { git -C "$ROOT" remote add origin https://github.com/o/demo.git; }

mk_through_manifest() { # repo, gitlore and manifest, committed
    mk_repo
    add_gitlore
    add_manifest
    commit_all
}

mk_complete() { # every check ok; a test then breaks exactly one fact
    mk_repo
    add_gitlore
    add_manifest
    add_toolkit_files
    add_toolkit_wiring
    add_justfile
    add_envrc
    add_ignore
    add_dist_include
    add_origin
    commit_all
    add_copy
}

# ---- probe invocation and assertions ---------------------------------------

probe() { run "$PROBE" "${1:-$ROOT}"; }

# next_field <n>: field n (1-based) of the first `next` line
next_field() {
    printf '%s\n' "$output" | awk -F'\t' -v n="$1" '$1=="next"{print $n; exit}'
}

# assert_next <id> <actor> [<substring of the action>]
assert_next() {
    [ "$(next_field 2)" = "$1" ] || {
        echo "next id: wanted '$1', got '$(next_field 2)'"
        echo "$output"
        return 1
    }
    [ "$(next_field 3)" = "$2" ] || {
        echo "next actor: wanted '$2', got '$(next_field 3)'"
        return 1
    }
    if [ -n "${3:-}" ]; then
        [[ "$(next_field 4)" == *"$3"* ]] || {
            echo "next action lacks '$3': $(next_field 4)"
            return 1
        }
    fi
}

# assert_status <status> <check-id>: some line carries both
assert_status() {
    printf '%s\n' "$output" | awk -F'\t' -v s="$1" -v i="$2" \
        '$1==s && $2==i {f=1} END {exit !f}' || {
        echo "no '$1' line for check '$2'"
        echo "$output"
        return 1
    }
}

# ---- cases -----------------------------------------------------------------

@test "empty dir: next is repo, agent git init" {
    mkdir -p "$ROOT"
    probe
    [ "$status" -eq 1 ]
    assert_next repo agent "git init"
}

@test "subdirectory of a repo: repo blocked, exit 1" {
    mk_repo
    mkdir -p "$ROOT/sub"
    probe "$ROOT/sub"
    [ "$status" -eq 1 ]
    assert_status blocked repo
    assert_next repo decision
}

@test "linked worktree without gitlore: worktree blocked" {
    mk_repo
    git -C "$ROOT" worktree add -q -b wt-branch "$BATS_TEST_TMPDIR/wt tree"
    probe "$BATS_TEST_TMPDIR/wt tree"
    [ "$status" -eq 1 ]
    assert_status blocked worktree
}

@test "fresh repo: next is gitlore" {
    mk_repo
    probe
    [ "$status" -eq 1 ]
    assert_next gitlore agent
}

@test "gitlore staged, not committed: next is gitlore, commit" {
    mk_repo
    add_gitlore
    git -C "$ROOT" add -A
    probe
    [ "$status" -eq 1 ]
    assert_next gitlore agent commit
}

@test "gitlore committed, no manifest: next is manifest" {
    mk_repo
    add_gitlore
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next manifest agent
}

@test "manifest not JSON: manifest missing" {
    mk_through_manifest
    echo 'not json {' > "$ROOT/.claude-plugin/plugin.json"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing manifest
    assert_next manifest agent
}

@test "extracted repo with manifest and no gitlore: manifest ok, next gitlore" {
    mk_repo
    add_manifest
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status ok manifest
    assert_next gitlore agent
}

@test "manifest committed, no plugin-dev: next is toolkit, shell install block" {
    mk_through_manifest
    probe
    [ "$status" -eq 1 ]
    assert_next toolkit shell "cd '$ROOT' && "
    [[ "$(next_field 4)" == *"install.sh"* ]]
    # A shell act is a runnable one-liner whose cd survives a paste.
    action="$(next_field 4)"
    [ "$( (eval "${action%% && *} && pwd") )" = "$ROOT" ]
}

@test "vendored, hooks unwired: next is toolkit, shell bash plugin-dev/install.sh" {
    mk_through_manifest
    add_toolkit_files
    add_justfile
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next toolkit shell "bash plugin-dev/install.sh"
    [[ "$(next_field 4)" == "cd '$ROOT' && "* ]]
}

@test "zero-byte settings.json: treated as absent" {
    mk_complete
    : > "$ROOT/.claude/settings.json"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing toolkit
    [[ "$output" == *"absent or a sandbox mask"* ]]
    assert_next toolkit shell
}

@test "justfile without prerelease: next is recipes" {
    mk_complete
    printf "import 'plugin-dev/release.just'\n\ncheck-refs:\n    true\n\nprecommit: check-refs\n    true\n" \
        > "$ROOT/justfile"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next recipes agent
}

@test "precommit without check-refs: next is recipes" {
    mk_complete
    printf "import 'plugin-dev/release.just'\n\nprecommit:\n    true\n\nprerelease: precommit\n" \
        > "$ROOT/justfile"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next recipes agent
}

@test "envrc with plugin-dev/bin before .gitlore/bin: next is envrc" {
    mk_complete
    printf 'PATH_add plugin-dev/bin\nPATH_add .gitlore/bin\n' > "$ROOT/.envrc"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next envrc agent
}

@test "a PATH_add between .gitlore/bin and plugin-dev/bin: envrc ok" {
    mk_complete
    printf 'source_up_if_exists\nPATH_add .gitlore/bin\n# PATH_add plugin-dev/bin\nPATH_add scripts\nPATH_add plugin-dev/bin\n' \
        > "$ROOT/.envrc"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status ok envrc
    assert_next none -
}

@test "dist/plugin not ignored: next is ignore" {
    mk_complete
    : > "$ROOT/.gitignore"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next ignore agent
}

@test "no dist.include: next is dist-include" {
    mk_complete
    rm "$ROOT/dist.include"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next dist-include agent
}

@test "no copy: next is dogfood, shell just dogfood" {
    mk_complete
    rm -rf "$ROOT/dist"
    probe
    [ "$status" -eq 1 ]
    assert_next dogfood shell "just dogfood"
    [[ "$(next_field 4)" == "cd '$ROOT' && "* ]]
}

@test "ssh memory url: next is memory-url, agent" {
    mk_complete
    sed -i.bak 's|url = .*|url = git@github.com:o/mem.git|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next memory-url agent "o/mem"
}

@test "placeholder memory url: next is memory-url, decision" {
    mk_complete
    sed -i.bak 's|url = .*|url = ./.git/gitlore-placeholder|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next memory-url decision
}

@test "no origin: next is origin" {
    mk_complete
    git -C "$ROOT" remote remove origin
    probe
    [ "$status" -eq 1 ]
    assert_next origin decision
}

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
    snapshot() {
        git -C "$ROOT" status --porcelain
        (cd "$ROOT" && find . -path ./.git -prune -o -print | LC_ALL=C sort)
        (cd "$ROOT" && find . -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort)
        cksum < "$ROOT/.git/index"
        git -C "$ROOT" ls-files -s
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
