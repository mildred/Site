
JADE=../node_modules/jade/bin/jade.js
JSONTOOL=../node_modules/jsontool/lib/jsontool.js
JSESC=../node_modules/jsesc/bin/jsesc

srcdir="${1%/*}"

redo-ifchange "$2.index.list"
metafile="$($JSONTOOL metafile <"$2.index.list")"

(
  echo "{ 'pagenum': $($JSONTOOL pagenum <"$2.index.list"), 'files': ["
  i=0
  count="$($JSONTOOL items.length <"$2.index.list")"
  while [ $i -lt $count ]; do
    curfile="$($JSONTOOL "items[$i]" <"$2.index.list")"
    redo-ifchange "$srcdir/$curfile.meta.json" "$srcdir/$curfile.htm" "$srcdir/$curfile.dest"
    echo "{'meta':"
    cat "$srcdir/$curfile.meta.json"
    echo ", 'srcpath':"
    echo "$curfile" | $JSESC --json
    echo ", 'destpath':"
    echo "$(dirname "$curfile")/$(cat "$srcdir/$curfile.dest")" | $JSESC --json
    echo ", 'html':"
    $JSESC --json <"$srcdir/$curfile.htm"
    echo "},"
    i=$((i+1))
  done
  echo "] }"
) >"$3"

