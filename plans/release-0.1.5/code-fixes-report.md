# Code fixes report (tasks A-J)

Not committed. `just precommit` tail: `check-refs ... ok`, `check-skill-text: no wikilinks ... in 9 files`, `bats: 119 passed, 0 failed`.
Only mawk was available here; gawk and BSD awk were not run (program uses POSIX constructs only; ENVIRON, substr, index-free).

## A. hooks/is-claude-version-call.sh
Rewritten as one awk program (`awk_program` heredoc, run `CMD=... LC_ALL=C awk`). Comments, continuation, double-quote backslash as specified; header residual bounds rewritten. Extra bounds stated in header: \r \f \v end a simple command like newline (old behaviour kept); command over ~128 KB (env string limit) cannot run and reads as no match (any awk failure maps to exit 1).
hooks/claude-version.sh ~line 19 comment rewritten (awk pass, near-linear, still a process spawn).
Timings (mawk): 82297-byte heredoc ending in `claude --version`: 0.17 s, exit 0. Codex repro (`: "` + 50000 x + `"; claude -v`): 0.29 s, exit 0. (Old: ~108 s.)

## B. hooks/hooks.json
`"timeout": 5` added to the claude-version command.

## C. tests/claude-version-hook.bats
Repaired: "not claude --version" test (stdout now `2.1.300 (Claude Code)`, comment fixed); 50 KB timing test (stdout version-shaped, command ends `echo claude --version` so it passes both prefilters). Added hook tests: comment-word negative, `claude "\-v"` negative, line-continuation positive, 50 KB heredoc ending `claude --version` expecting mismatch output; plus 7 matcher unit tests (comment, `a#b`, comment ends at newline, continuation, dq backslash literal, dq escaped quote, single-quote backslash).
Red against `git show HEAD:hooks/is-claude-version-call.sh` (then restored): 8 failed, 39 passed: matcher "refuses after a comment word", "joins continuation", "keeps backslash literal in double quotes"; hook "silent after comment word", "silent for dq backslash", "reports mismatch for line continuation", both 50 KB timing tests (status 124 timeout). Not red under old, by design: the repaired "not claude --version" test (old matcher already refuses it; it now reaches the matcher), the dq-escaped-quote, single-quote-backslash, `a#b` and comment-ends-at-newline matcher tests (guard existing/new behaviour that old code already satisfied).

## D. lib/creation-status-readers.sh `settings_wired` (line 63)
Each command required under its own event (version-guard and pre-tool under PreToolUse, session-start under SessionStart), `type == "command"`, matcher not checked. Tests (tests/plugin-craft-creation-status.bats): all under Stop, swapped events, type not command (all red on old); rescoped matcher still wired (guard, passes both).

## E. bin/plugin-craft-creation-status check_toolkit
`grep -qsxF`. Test: commented-out import -> toolkit missing (red on old).

## F. check_memory_url
Reads `HEAD:.gitmodules` via `g config --blob`; with .gitmodules not in HEAD (incl. no HEAD) it emits `missing memory-url ".gitmodules is not committed"` (agent, commit it). Test in tests/creation-status-checks.bats: ssh committed, https in working tree -> missing (red on old).

## G. ssh_to_https
Split into `ssh_re` (port allowed) and `scp_re` (no port group). Tests: `git@github.com:123/mem.git` -> `https://github.com/123/mem.git` (red on old); `ssh://git@example.com:2222/o/mem.git` -> port dropped (green both).

## H. justfile
`for f in scripts/*.sh hooks/*.sh lib/*.sh bin/plugin-craft-creation-status; do bash -n "$f" || exit 1; done`.

## I. Split
Test count before: 36 (545 lines). After the split alone: 11 + 15 + 10 = 36. Then 8 new tests from D-G (5 in plugin-craft-creation-status.bats, 3 in creation-status-checks.bats).
Files: tests/plugin-craft-creation-status.bats (route, 11 orig + 5 new), tests/creation-status-checks.bats (15 orig + 3 new), tests/creation-status-report.bats (10), helper tests/creation-status-helpers.bash (175 lines, `load`ed, not .bats). All under 400 lines (max 379 is claude-version-hook.bats).
Suite total 119 passed.

## J. hooks/running-version.sh
`WINDOW=400` moved to just before `main "$@"`.

## Not done
Nothing skipped. Not run: gawk / BSD awk. Task A header notes the \r\f\v and 128 KB bounds, which the brief did not name.

## Review follow-up (findings 2 and 3)
- hooks/is-claude-version-call.sh header: added that an unquoted backtick substitution is not matched (backtick is a word character); the ~128 KB bound now says claude-version.sh passes the command as an argument and fails there with E2BIG (rc 126), read as no match.
- tests/plugin-craft-creation-status.bats: new test "only version-guard moved to SessionStart: not wired". Red against a mutated `settings_wired` accepting version-guard under either event (`not ok 14`, 16 passed 1 failed); mutation restored.
- `just precommit`: `bats: 120 passed, 0 failed`.
