#!/usr/bin/env bats
# bin/plugin-craft-creation-status: the route from an empty directory to a working toolkit.
# Each case builds a scratch repo from a complete one with a single fact broken,
# so the asserted `next` line can only come from that fact. Fixtures and
# assertions live in creation-status-helpers.bash.
# shellcheck disable=SC2016 # fixtures hold literal $ and backticks

bats_require_minimum_version 1.5.0

load creation-status-helpers

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

@test "linked worktree without gitlore: worktree blocked, next worktree" {
    mk_repo
    git -C "$ROOT" worktree add -q -b wt-branch "$BATS_TEST_TMPDIR/wt tree"
    probe "$BATS_TEST_TMPDIR/wt tree"
    [ "$status" -eq 1 ]
    assert_status blocked worktree
    assert_next worktree decision
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
    # The action names the staged paths, not only the verb.
    [[ "$(next_field 4)" == *".gitmodules"* ]]
    [[ "$(next_field 4)" == *".envrc"* ]]
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

@test "toolkit commands all under Stop: not wired, next is toolkit" {
    mk_complete
    jq '.hooks = {Stop: ([.hooks[][]] )}' "$ROOT/.claude/settings.json" \
        > "$ROOT/.claude/settings.new"
    mv "$ROOT/.claude/settings.new" "$ROOT/.claude/settings.json"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing toolkit
    assert_next toolkit shell "bash plugin-dev/install.sh"
}

@test "version-guard under SessionStart and session-start under PreToolUse: not wired" {
    mk_complete
    jq '.hooks as $h
        | .hooks = {PreToolUse: [$h.PreToolUse[1], $h.SessionStart[0]],
                    SessionStart: [$h.PreToolUse[0]]}' "$ROOT/.claude/settings.json" \
        > "$ROOT/.claude/settings.new"
    mv "$ROOT/.claude/settings.new" "$ROOT/.claude/settings.json"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing toolkit
}

@test "only version-guard moved to SessionStart: not wired" {
    mk_complete
    jq '.hooks.SessionStart += [.hooks.PreToolUse[0]] | del(.hooks.PreToolUse[0])' \
        "$ROOT/.claude/settings.json" > "$ROOT/.claude/settings.new"
    mv "$ROOT/.claude/settings.new" "$ROOT/.claude/settings.json"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing toolkit
}

@test "a hook entry whose type is not command: not wired" {
    mk_complete
    jq '.hooks.SessionStart[0].hooks[0].type = "prompt"' "$ROOT/.claude/settings.json" \
        > "$ROOT/.claude/settings.new"
    mv "$ROOT/.claude/settings.new" "$ROOT/.claude/settings.json"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing toolkit
}

@test "toolkit commands under a rescoped matcher: still wired" {
    mk_complete
    jq '.hooks.PreToolUse[0].matcher = "Bash" | del(.hooks.SessionStart[0].matcher)' \
        "$ROOT/.claude/settings.json" > "$ROOT/.claude/settings.new"
    mv "$ROOT/.claude/settings.new" "$ROOT/.claude/settings.json"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status ok toolkit
}

@test "justfile import commented out: toolkit is not ok" {
    mk_complete
    sed -i.bak "s|^import 'plugin-dev/release.just'|# &|" "$ROOT/justfile"
    rm "$ROOT/justfile.bak"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_status missing toolkit
    [[ "$output" == *"justfile lacks the plugin-dev import"* ]]
}
