# TODO

- `scripts/check-skill-text.sh`: the wikilink pattern matches bash's `[[ … ]]`
  in prose, so skill text cannot name that construct (found while adding the
  post-deny absorption fact to `hook-authoring`; the text was reworded around
  it). Exempt code spans, or require a non-space after `[[`.
