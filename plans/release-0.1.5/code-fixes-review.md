# Code fixes review (tasks A-J)

Reviewed the uncommitted diff on `dev` (hooks, lib, bin, justfile, tests,
plus `docs/design.md` D-11 and L-3). I found no high or medium findings. Every
brief item is implemented, every new test the brief asked to be red is red
against the HEAD code, and the route reports the same thing on all 40 repos
under `/Users/david/code` before and after the change.

## Findings

### Low

1. **`docs/design.md:77` (D-11) says the matcher is "linear in the command
   length".** That is true for the code's structure, but the measured cost
   grows faster than linear for one long word, because awk concatenates
   `word = word c` one character at a time. With mawk, timing one quoted word
   of N bytes followed by `; claude -v`: 30 KB took 52 ms, 60 KB took 107 ms
   and 120 KB took 517 ms. A space-separated command of the same sizes took
   43, 124 and 219 ms. The Linux 128 KB per-string limit keeps this far below
   the 5 s timeout, so there is no behavioural defect. The
   `hooks/claude-version.sh` comment says "near-linear", which is more
   accurate. Suggested wording: "a single awk pass", or "near-linear".

2. **The bounds in the header of `hooks/is-claude-version-call.sh` (lines
   20-27) leave out unquoted backticks.** The header says "`$(...)` or
   backticks inside quotes are not interpreted". Unquoted, `$(claude -v)` is
   matched, because `(` splits the command, but `` v=`claude -v` `` is not:
   the backtick is read as a word character. Reproduced: `` echo `claude -v` ``
   gives exit 1 with both the old and the new matcher, so this is not a
   regression. It is a gap in the stated bounds. The same paragraph says the
   ~128 KB limit applies because "the command travels in the environment",
   but `claude-version.sh` passes the same string as argv first
   (`bash "$dir/is-claude-version-call.sh" "$command"`), so argv hits E2BIG
   before the environment does. Reproduced: a 187 KB command gives
   `Argument list too long`, rc 126, and the hook treats that as no match. The
   bound itself is true; only the reason given is incomplete.

3. **Two contracts in `settings_wired` are not pinned by their own tests**
   (`tests/plugin-craft-creation-status.bats:118-152`). The swapped-event test
   moves version-guard and session-start together, and the type test touches
   only the session-start entry. Mutation: I replaced `wired("PreToolUse"; $a)`
   with `(wired("PreToolUse"; $a) or wired("SessionStart"; $a))` in a scratch
   copy, and the route suite stayed 16/16 green. So a regression that accepted
   version-guard (or pre-tool) under the wrong event would not be caught, as
   long as session-start stayed correct. Fix: a single test that moves only
   version-guard to SessionStart and expects `missing toolkit`.

4. **The departure in `check_memory_url`
   (`bin/plugin-craft-creation-status:297-301`) has no test.** The branch is
   reached only when `.gitmodules` is not in HEAD. In that state
   `gitlore_probe` has already emitted `missing gitlore` ("present but not
   committed: .gitmodules"), which comes earlier in the route, so `next` never
   comes from this row. The row only gives information, and its action
   ("commit .gitmodules …") agrees with the gitlore row's action.

## The two departures in the report

- **Extra header bounds:** both are accurate. `\r`, `\f` and `\v` end a
  simple command, and `$'claude\r-v'` gives exit 1 with both matchers. The
  128 KB bound is real, apart from the incomplete reason in finding 2.
  Accepted.
- **`missing memory-url ".gitmodules is not committed"`:** accepted. The
  alternative, falling through with `url=""`, would emit a misleading
  `decision` row ("neither https nor ssh: "). Its effect on the route is nil,
  as explained in finding 4.

## Claims I verified that hold

- **A, no regression.** I ran old and new matchers side by side on 46
  commands: plain, piped, `2>&1`, assignments, quotes, `$#`, `${#a}`, `#` in
  words and at word start, continuation inside and outside quotes, `"\\"`,
  `"\$"`, `` "\`" ``, `$(...)`, `{ … }`, a trailing backslash, `&>`. The only
  differences are the intended ones: `claude "\-v"`, `echo #x; claude -v`,
  `echo x;#; claude -v` and `claude --version\<NL>`. bash itself treats `#`
  as a comment in `[[ … == #* ]]` and `case … in #*)`, so the word-start rule
  does not produce false negatives there.
- **awk portability (from reading the code; no other awk could be run):**
  - Only POSIX constructs: `ENVIRON`, `substr`, `length`, a regex match, and
    a user function called with no space before `(`.
  - The `\v` string escape is POSIX and accepted by mawk, gawk, onetrue and
    busybox.
  - `if (x) s; else t` on one line is valid POSIX grammar.
  - The program has only BEGIN plus a function, so awk never reads stdin.
  - `LC_ALL=C` makes `length` and `substr` count bytes in gawk.
  - The command is passed through ENVIRON, which avoids `-v` escape
    processing.
- **C.** With the HEAD matcher in a scratch copy, 8 tests fail: the three
  matcher tests and three hook tests named in the report, plus both 50 KB
  timing tests (status 124). Replacing the matcher with `exit 0` fails 15
  tests, including "hook is silent … not claude --version", so that test now
  reaches the matcher. Mutating `!have` away fails the `a#b` test. Mutating
  the comment so it runs to the end of the string fails "ends a comment at the
  newline".
- **D-G.** With the HEAD `bin/` and `lib/`, the Stop, swapped,
  type-not-command, commented-import, working-tree-url and digit-owner tests
  fail. The rescoped-matcher and port tests are guards and pass under both.
  The `settings_wired` event and matcher rule agrees with `add_hook`'s
  `has_cmd` in `plugin-dev/install.sh:170`. The extra `type == "command"`
  check is stricter than install.sh, but every entry install.sh writes has
  that type.
- **E** matches `install.sh:125` (`grep -qxF "$import_line"`).
- **H.** `bash -n a b c` checks only `a`; the loop checks each file and
  quotes `"$f"`.
- **I.** All 36 original test names are present across the three files, plus
  8 new ones. Line counts: 174, 179 and 131, and the helper is 173, all under
  400.
- **J.** `WINDOW` now comes after its user.
- **`docs/design.md`.** D-11 describes the comment and continuation rules and
  the 5 s timeout correctly (apart from "linear", finding 1). L-3's listed
  bounds are still true.

## Checks run

- `git diff`, `git status --short`, and a read of the HEAD matcher and the
  implementer's report.
- `plugin-dev/run-bats.sh tests/*.bats`: 119 passed, 0 failed.
- `just precommit`: jq on the manifest, the `bash -n` loop, shellcheck on
  scripts and hooks, `shellcheck -x` on the probe and lib, jq on
  `hooks.json`, `check-skill-text` (no wikilinks … in 9 files) and bats (119
  passed). All passed.
- `bin/plugin-craft-creation-status .`: every row ok, `next none`, rc 0, and
  identical to the HEAD version.
- HEAD and new `plugin-craft-creation-status` on all 40 git repos under
  `/Users/david/code`: full output identical.
- Old against new matcher on the 46-command corpus.
- Red runs in a scratch copy under `$TMPDIR`:
  - HEAD matcher against `claude-version-hook.bats`: 8 fail.
  - Matcher replaced with `exit 0`: 15 fail.
  - Three matcher mutations: `!have` removed (1 fail), comment runs to the
    end of the string (1 fail), continuation sets `have` (survives; it only
    affects a comment right after a continuation).
  - HEAD `bin/` and `lib/` against the three creation-status files: 6 fail.
  - The `settings_wired` event mutation: survives (finding 3).
- Timing with mawk:
  - one quoted word of 30, 60 and 120 KB: 52, 107 and 517 ms;
  - a spaced command of the same sizes: 43, 124 and 219 ms;
  - a 187 KB command: E2BIG, rc 126.
- shellcheck on `tests/creation-status-helpers.bash` and the `.bats` files
  (not part of the gate). Only SC2154 for the bats-provided `$output` and
  SC2030/2031 infos.
- **Not run:** gawk, BSD awk and busybox awk. None is installed, only mawk
  (`awk` and `nawk` both point to it). I downloaded the Debian
  `original-awk`, `busybox` and `gawk` packages, but the auto-mode classifier
  denied running the extracted binaries, so I deleted them without running
  them. Portability is judged by reading the code only.
