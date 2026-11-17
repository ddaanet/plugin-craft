# A file write fails with "classifier gave no verdict" under `--plugin-dir`

Part of `verifying-plugin-changes`: an edit to a plugin loaded from the tree
being edited.

Scope: the hard-failure text only — `auto mode classifier gave no verdict`,
then `This is a hard failure` and `Don't retry it`. The transient and
one-retry texts say to retry once; do that instead. A denial, where the
classifier judged the action and blocked it saying why, is a different
failure, and no route around it is sanctioned.

Cause: `--plugin-dir` marks the loaded directory's content sensitive on
purpose, so `Write`, `Edit` and `NotebookEdit` there all get the hard failure,
and retrying repeats the answer. Fix: relaunch with the plugin loaded through
the toolkit's dogfood launcher, which loads a synced copy rather than the
checkout, or without `--plugin-dir`: ask the user to relaunch that way, since
only the user can. Meanwhile, as the error says, continue with work that does
not need the write; if the write is essential, stop and tell the user. Do not
look for another way to write the file.
