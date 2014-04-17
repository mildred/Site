
JADE=../node_modules/jade/bin/jade.js
JSONTOOL=../node_modules/jsontool/lib/jsontool.js
JSESC=../node_modules/jsesc/bin/jsesc

srcdir="${1%/*}"

indexlist="$2.$ext.list"
redo-ifchange "$2.$ext.src" "$indexlist"
metafile="$($JSONTOOL metafile <"$indexlist")"

genfiles(){
  i=0
  count="$($JSONTOOL items.length <"$indexlist")"
  while [ $i -lt $count ]; do
    curfile="$($JSONTOOL "items[$i]" <"$indexlist")"
    redo-ifchange "$srcdir/$curfile.meta.json" "$srcdir/$curfile.htm" "$srcdir/$curfile.dest"
    cat <<EOF
    {
      path:     path.resolve(argsdir, $(echo "$curfile" | $JSESC --json)),
      srcpath:  path.resolve(argsdir, $(echo "$curfile" | $JSESC --json)),
      destpath: path.resolve(argsdir, $(echo "$(dirname "$curfile")/$(cat "$srcdir/$curfile.dest")" | $JSESC --json)),
      meta:     $(cat "$srcdir/$curfile.meta.json"),
      html:     $($JSESC --json <"$srcdir/$curfile.htm")
    },
EOF
    i=$((i+1))
  done
}

genpages(){
  i=0
  count="$($JSONTOOL pages.length <"$indexlist")"
  while [ $i -lt $count ]; do
    curfile="$($JSONTOOL "pages[$i]" <"$indexlist")"
    cat <<EOF
      {srcpath: path.resolve(argsdir, $(echo "$curfile" | $JSESC --json))},
EOF
    i=$((i+1))
  done
}

(
  cat <<EOF
  {
    'pagenum':    $($JSONTOOL pagenum <"$indexlist"),
    'firstitem':  $($JSONTOOL firstitem <"$indexlist"),
    'lastitem':   $($JSONTOOL lastitem <"$indexlist"),
    'latestpage': {'srcpath': path.resolve(argsdir, $($JSONTOOL latestpage <"$indexlist" | $JSESC --json))},
    'atompage':   {'srcpath': path.resolve(argsdir, $($JSONTOOL atompage   <"$indexlist" | $JSESC --json))},
    'pages':      [$(genpages)],
    'files':      [$(genfiles)]
  }
EOF
) >"$3"

