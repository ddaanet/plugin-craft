## Current task

plugin-craft is seeded and documented: four skills under `skills/`, `scripts/check-skill-text.sh` wired into `just precommit`, and a living `docs/design.md` with its changelog beside it. The live thread is the first release.

A second thread is not this repo's to drive: the sibling extraction passes for `craft` and `shell-scripting` run in parallel against the same ddaanet memory tier. `hook-output-channels` was reduced here to its section 7, which is `craft`'s source, and the inbound pointers in facts that stay were repointed at the new skills. If a parallel pass wrote those same files, it surfaces as a merge on the memory store rather than as silent loss.