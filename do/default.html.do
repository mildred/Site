
JADE=../node_modules/jade/bin/jade.js
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js


redo-ifchange "$2.meta.json"

template=$($JSONTOOL template <"$2.meta.json")
if [ -z "$template" ]; then
  template=template.jade
fi

template="${2%/*}/$template"
redo-ifchange "$template"
redo-ifchange "$2.htm"

args="{
  'file_meta': $(cat "$2.meta.json"),
  'file_html': $($JSESC --json <"$2.htm")
}"

$JADE -O "$args" <"$template" >"$3"
