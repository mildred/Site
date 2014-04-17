# kate: hl sh;
set -e
JADE=../node_modules/jade/bin/jade.js
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

srcdir="${2%/*}"
outdir="${3%/*}"
basefile1="${1##*/}"
basefile2="${2##*/}"

redo-ifchange "$2.index.meta.json"

filter="$($JSONTOOL filter <"$2.index.meta.json")"
if [ -z "$filter" ]; then
  filter=true
fi

filelist="$($JSONTOOL filelist <"$2.index.meta.json")"
if [ -z "$filelist" ]; then
  filelist=..srclist
fi
filelistdir="$(dirname "$filelist")"
filelist="${2%/*}/$filelist"

redo-ifchange "$filelist"

#echo "redo $2.index" >&2

list="$(
  while read f; do
    [ "a$2.index" = "a$filelistdir/$f" ] && continue
    redo-ifchange "$srcdir/$filelistdir/$f.dest"
    [ -s "$srcdir/$filelistdir/$f.dest" ] || continue
    redo-dofile "$srcdir/$filelistdir/$f.htm" >/dev/null || continue
    printf '%s\n' "$f"
  done <"$filelist")"

if [ -n "$list" ]; then
  echo "$list" | tr '\n' '\0' | xargs -0 -n 1 printf "%s/%s.meta.json\0" "$srcdir/$filelistdir" | xargs -0 sh -c '"$0" "$@" || exit 255' redo-ifchange
fi

(
  echo "["
  sep=""
  echo "$list" | while read f; do
    echo "$sep"
    echo "{\"file\": $(echo "$filelistdir/$f" | $JSESC --json),"
    echo " \"meta\":"
    if [ -s "$srcdir/$filelistdir/$f.meta.json" ]; then
      cat "$srcdir/$filelistdir/$f.meta.json"
    else
      echo "{}"
    fi
    echo "}"
    sep=","
  done
  echo "]"
) | $JSONTOOL -C "$filter" | $JSONTOOL -a meta.timestamp_modified meta.timestamp_created file >"$3"

