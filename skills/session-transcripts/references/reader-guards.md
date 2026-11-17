# Reader guards: line types and jq offsets

Open when writing the loop that reads transcript lines, or a jq program that
slices them.

## Two guards, not one

A line-by-line JSONL reader needs two guards. Dropping lines that fail to
parse is the obvious half. A line that parses to a **scalar or an array**
passes that filter and kills the reader at the first field access.

**jq.** `fromjson? // empty` filters parse failures (and `null`/`false`). It
does not filter `42`, `"a string"` or `[1,2]`, and indexing one of those is a
fatal error, not a null:

```
$ printf '42\n' | jq -Rn '[inputs | fromjson? // empty | .foo]'
jq: error (at <stdin>:0): Cannot index number with "foo"
$ echo $status
5
```

It aborts the whole program, so one bad line poisons every other line in the
same invocation. Guard with `select(type == "object")` immediately after the
`fromjson?`.

**Python.** `json.loads("42")` returns `42`, and `entry.get("type")` on it
raises `AttributeError`; the `except json.JSONDecodeError: continue` around
the parse does not catch it. Guard with `isinstance(entry, dict)`.

The blast radius is the reason to guard against a line nobody has seen. In a
hook under `set -euo pipefail` the error takes the hook down on every
invocation for as long as the line sits in the read window (with a `tail -c`
window, until it scrolls out), and a hook that dies is a feature that
silently stops working, not an error anyone is shown. There is no published
schema to appeal to, so "the harness only ever writes objects" assumes a
format that is conventional rather than specified.

## `index()` is bytes, slicing is codepoints

jq's `index($sub)` on a **string** returns a **byte** offset, while
`$s[$a:$b]` slicing and `$s | length` count **codepoints**. Feeding an
`index` result into a slice holds only while the text before the match is
pure ASCII, and cuts inside a character as soon as it is not. Nothing warns:
the result is a mangled string, or an offset that matches nothing.

One command shows the units disagreeing:

```
$ jq -cn '"— A\n— X\n" as $s | "\n— X" as $old
  | {index: ($s|index($old)), slice_needs: ($s|split($old)|.[0]|length)}'
{"index":5,"slice_needs":3}
```

Take the offset from the same unit system as the slice, the prefix `split`
leaves behind:

```
($s | split($old)) as $parts
| if ($parts|length) < 2 then empty          # no occurrence
  else ($parts[0] | length) as $i | ...      # codepoints, like the slice
  end
```

`split/1` is literal; only `split/2` is a regex. `$parts[0]` is the text
before the first occurrence, the semantics a replace-style computation wants.
Verified against jq 1.7.

The reason to be in jq for this at all is `--rawfile`, which binds a whole
file as one string with its final byte intact: `$(cat f)` strips the trailing
newline, and in a format where a newline is the separator that byte is
usually the one that matters.
