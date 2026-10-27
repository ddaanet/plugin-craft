#!/usr/bin/env bats
# bin/plugin-craft-creation-status: the later checks: recipes, envrc, ignore, dist.include, dogfood copy, memory url, origin.
# Each case builds a scratch repo from a complete one with a single fact broken,
# so the asserted `next` line can only come from that fact. Fixtures and
# assertions live in creation-status-helpers.bash.
# shellcheck disable=SC2016 # fixtures hold literal $ and backticks

bats_require_minimum_version 1.5.0

load creation-status-helpers

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
    assert_next envrc agent "direnv allow"
}

@test "a PATH_add between .gitlore/bin and plugin-dev/bin: envrc ok" {
    mk_complete
    printf 'source_up_if_exists\nPATH_add .gitlore/bin\nPATH_add scripts\nPATH_add plugin-dev/bin\n# PATH_add scripts\n' \
        > "$ROOT/.envrc"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status ok envrc
    assert_next none -
}

# envrc_ok_with <.envrc content>: a correctly ordered file in some spelling
envrc_ok_with() {
    mk_complete
    printf '%b' "$1" > "$ROOT/.envrc"
    commit_all
    probe
    [ "$status" -eq 0 ]
    assert_status ok envrc
    assert_next none -
}

@test "envrc with double-quoted PATH_add operands: envrc ok" {
    envrc_ok_with 'PATH_add ".gitlore/bin"\nPATH_add "plugin-dev/bin"\n'
}

@test "envrc with single-quoted PATH_add operands: envrc ok" {
    envrc_ok_with "PATH_add '.gitlore/bin'\nPATH_add 'plugin-dev/bin'\n"
}

@test "envrc with trailing comments on PATH_add lines: envrc ok" {
    envrc_ok_with 'PATH_add .gitlore/bin # memory\nPATH_add plugin-dev/bin # toolkit\n'
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
    assert_next memory-url agent "https://github.com/o/mem"
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

@test "memory url neither https, ssh nor placeholder: next is memory-url, decision" {
    mk_complete
    sed -i.bak 's|url = .*|url = http://example.com/o/mem.git|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    commit_all
    probe
    [ "$status" -eq 1 ]
    assert_next memory-url decision
}

@test "local-path memory url: next is memory-url, decision" {
    mk_complete
    sed -i.bak 's|url = .*|url = ../mem|' "$ROOT/.gitmodules"
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

@test "memory url fixed in the working tree but not committed: memory-url missing" {
    mk_complete
    sed -i.bak 's|url = .*|url = git@github.com:o/mem.git|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    commit_all
    sed -i.bak 's|url = .*|url = https://github.com/o/mem.git|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    probe
    [ "$status" -eq 1 ]
    assert_status missing memory-url
    assert_next memory-url agent "https://github.com/o/mem"
}

@test "ssh memory url with a digit-only owner: the owner survives" {
    mk_complete
    sed -i.bak 's|url = .*|url = git@github.com:123/mem.git|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    commit_all
    probe
    assert_next memory-url agent "https://github.com/123/mem.git"
}

@test "ssh:// memory url with a port: the port is dropped" {
    mk_complete
    sed -i.bak 's|url = .*|url = ssh://git@example.com:2222/o/mem.git|' "$ROOT/.gitmodules"
    rm "$ROOT/.gitmodules.bak"
    commit_all
    probe
    assert_next memory-url agent "https://example.com/o/mem.git"
}
