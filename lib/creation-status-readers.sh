# shellcheck shell=bash
# File-format readers for bin/plugin-craft-creation-status. Sourced, never run:
# it lives outside bin/ so it stays off every user's PATH. Each reader looks at
# one file format and shares no state with the route logic, except the globals
# the entry script sets (ROOT, QROOT) and ENVRC_ARGS, which the .envrc readers
# own. Residual bound for the .envrc readers: one pair of quotes or a trailing
# comment is stripped from a PATH_add operand; escapes and expansions are not
# modelled.

envrc_load_file() { # ENVRC_ARGS from the working-tree .envrc
    ENVRC_ARGS=()
    ! [ -f "$ROOT/.envrc" ] || envrc_parse < "$ROOT/.envrc"
}

envrc_parse() { # stdin: an .envrc; ENVRC_ARGS gets the operand of each non-comment PATH_add
    local line
    ENVRC_ARGS=()
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line#"${line%%[![:space:]]*}"}
        case $line in
            PATH_add[[:space:]]*)
                ENVRC_ARGS+=("$(envrc_operand "${line#PATH_add}")")
                ;;
        esac
    done
}

envrc_operand() { # the first word of $1: quotes around it, or a trailing comment, are dropped
    local s=$1 q
    s=${s#"${s%%[![:space:]]*}"}
    q=${s:0:1}
    if [[ $q == \' || $q == \" ]] && [[ ${s:1} == *"$q"* ]]; then
        s=${s:1}
        printf '%s' "${s%%"$q"*}"
        return
    fi
    s=${s%%[[:space:]]#*}
    printf '%s' "${s%"${s##*[![:space:]]}"}"
}

envrc_has() { # is $1 among the parsed PATH_add operands
    local a
    for a in ${ENVRC_ARGS[@]+"${ENVRC_ARGS[@]}"}; do
        [ "$a" = "$1" ] && return 0
    done
    return 1
}

envrc_ordered() { # the last PATH_add is plugin-dev/bin and an earlier one is .gitlore/bin
    local n
    envrc_load_file
    n=${#ENVRC_ARGS[@]}
    [ "$n" -gt 1 ] && [ "${ENVRC_ARGS[n - 1]}" = plugin-dev/bin ] || return 1
    unset 'ENVRC_ARGS[n - 1]'
    envrc_has .gitlore/bin
}

manifest_valid() { # stdin: a manifest
    jq -e '(.name | type == "string" and length > 0)
           and (.version | type == "string" and length > 0)' >/dev/null 2>&1
}

settings_wired() { # $1: settings file; the three commands, spelled as install.sh spells them
    # shellcheck disable=SC2016 # ${CLAUDE_PROJECT_DIR} stays literal on purpose
    jq -e --arg a 'bash "${CLAUDE_PROJECT_DIR}/plugin-dev/version-guard.sh"' \
        --arg b 'bash "${CLAUDE_PROJECT_DIR}/plugin-dev/dogfood.sh" pre-tool' \
        --arg c 'bash "${CLAUDE_PROJECT_DIR}/plugin-dev/dogfood.sh" session-start' \
        '[.hooks[]?[]? | .hooks[]? | .command // empty] as $cmds
         | all([$a, $b, $c][]; . as $w | any($cmds[]; . == $w))' "$1" >/dev/null 2>&1
}

# shellcheck disable=SC2016 # the command text is printed, not expanded here
toolkit_install_block() { # the plugin-dev/README.md block as one pasteable line
    local repo='repo=ddaanet/claude-plugin-dev'
    local url='"https://github.com/$repo.git"'
    local raw='"https://raw.githubusercontent.com/$repo/$tag/install.sh"'
    local find_tag="tag=\$(git ls-remote --tags --refs --sort=-v:refname $url 'dist-v*'"
    find_tag+=" | head -1 | sed 's|.*/||')"
    printf 'cd %s && %s && %s && %s' "$QROOT" "$repo" "$find_tag" \
        "curl -fsSL $raw | bash -s -- \"\$tag\""
}

ssh_to_https() { # an scp-like or ssh:// url on stdout as https://host/path; 1 when it is neither
    local re='^(ssh://)?[^@/]+@([^:/]+)(:[0-9]+)?[:/](.+)$'
    [[ $1 =~ $re ]] || return 1
    printf 'https://%s/%s' "${BASH_REMATCH[2]}" "${BASH_REMATCH[4]}"
}

first_python() { # prints the first python file under the root-relative entry $1
    local f
    while IFS= read -r -d '' f; do
        if is_python "${f#./}"; then
            printf '%s' "${f#./}"
            return 0
        fi
    done < <(cd "$ROOT" && find "./$1" -type f -print0 | sort -z)
}

is_python() { # root-relative path: *.py, or a python shebang on the first line
    local shebang
    case $1 in *.py) return 0 ;; esac
    shebang=$(head -c 128 -- "$ROOT/$1" | tr -d '\000')
    [[ ${shebang%%$'\n'*} == '#!'*python* ]]
}
