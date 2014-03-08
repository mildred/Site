
JADE=../node_modules/jade/bin/jade.js
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

redo-ifchange "$2.index.meta.json"

template="$($JSONTOOL template <"$2.index.meta.json")"
if [ -z "$template" ]; then
  template=index.jade
fi
template="${2%/*}/$template"

filelist="$($JSONTOOL filelist <"$2.index.meta.json")"
if [ -z "$filelist" ]; then
  filelist=..srclist
fi
filelist="${2%/*}/$filelist"

redo-ifchange "$filelist"
redo-ifchange "$template"

list="$(tr '\n' '\0' <"$filelist" | xargs -0 -n 1 printf "%s/%s\n" "${2%/*}" | fgrep -v "$2.index" \
  | while read f; do
      redo-ifchange "$f.dest"
      [ -s $f.dest ] || continue
      printf '%s\n' "$f"
    done)"

echo "$list" | while read f; do printf "%s.meta.json\0%s.htm\0" "$f" "$f"; done | xargs -0 redo-ifchange

args="{
  'files': [$(
    echo "$list" | while read file; do
      echo "{'meta':"
      cat "$file.meta.json"
      echo ", 'html':"
      $JSESC --json <"$file.htm"
      echo "},"
    done
  )]
}"

$JADE -O "$args" <"$template" >"$3"
