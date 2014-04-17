
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js


redo-ifchange "$2.meta.json"

template=$($JSONTOOL template <"$2.meta.json")
: ${template:=template.jade}

template="${2%/*}/$template"
redo-ifchange "$template.runfile"

template="$(dirname "$template")/$(cat "$template.runfile")"

redo-ifchange "$template"

file="$( (cd "`dirname "$2"`"; echo "$PWD/`basename "$2"`") )"
out="$( (cd "`dirname "$3"`"; echo "$PWD/`basename "$3"`") )"
abstemplate="$( (cd "`dirname "$template"`"; echo "$PWD/`basename "$template"`") )"

cd "`dirname "$abstemplate"`"

"$abstemplate" "$abstemplate" "$file" "$out"

