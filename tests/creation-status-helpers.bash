# shellcheck shell=bash
# Shared by the creation-status bats files: sourced with `load`, so it is not a
# .bats file. The fixture builders, the probe invocation and its assertions.
# shellcheck disable=SC2016 # fixtures hold literal $ and backticks
# shellcheck disable=SC2030,SC2031 # ROOT is reassigned per test on purpose

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

# assert_shape: every stdout line is a tab-separated status line or the one
# `next` line, which comes last; a stray line (a leaked command output) fails.
assert_shape() {
    local n=13
    printf '%s\n' "$output" | awk -F'\t' -v n="$n" '
        $1=="next" { nexts++; if (NF != 4) bad = bad "next line field count: " $0 "\n"; nextat = NR; next }
        $1 ~ /^(ok|missing|blocked|warn|skip)$/ && NF >= 3 { st++; next }
        { bad = bad "stray line: " $0 "\n" }
        END {
            if (st != n) bad = bad "status lines: " st ", wanted " n "\n"
            if (nexts != 1) bad = bad "next lines: " nexts "\n"
            if (nextat != NR) bad = bad "next line is not last\n"
            if (bad != "") { printf "%s", bad; exit 1 }
        }' || {
        echo "$output"
        return 1
    }
}
