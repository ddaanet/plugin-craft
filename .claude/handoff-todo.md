## Open decisions

- Whether to split `classifier-denied-self-config` in the ddaanet tier. It is past the 4096-byte recall cap, so its tail is unreachable by the mechanism meant to reach it, and the newly added exception about a nested cross-repo push sits near that boundary. The frontmatter description carries the routing signal either way, which is the argument for leaving it.
- Whether to run a `/gitlore:index-audit` pass. The root memory index sits near the loader's byte budget, past which trailing entries are dropped with no warning.

## Remaining

- Revisit the `toolkit-release` first-release section once `claude-plugin-dev` acts on the inbox brief. The section currently documents a hand-edit-then-commit workaround that a toolkit fix would make obsolete, and a stale workaround is worse than none.
