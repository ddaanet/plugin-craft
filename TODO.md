## Remaining

- Run `plans/classifier-no-verdict/plan.md` probes P4 (Edit, NotebookEdit) and P5 (heredoc); none blocks anything shipped.
- Run the `claude --version` matcher tests under gawk and macOS awk; only mawk has run them.
- `check_python` in `bin/plugin-craft-creation-status` parses `dist.include` by hand rather than via the vendored `plugin-dev/dist.sh paths <root>`: it drops a legal `foo..bar`, accepts blanks and globs, and reads the working tree rather than HEAD. Declined for 0.1.5 to avoid depending on the vendored toolkit; revisit if it bites.
