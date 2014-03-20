
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js


redo-ifchange "$2.meta.json"

template=$($JSONTOOL template <"$2.meta.json")
if [ -z "$template" ]; then
  template=template.jade
fi

template="${2%/*}/$template"
redo-ifchange "$template.runfile"

template="$(dirname "$template")/$(cat "$template.runfile")"

file="$( (cd "`dirname "$2"`"; echo "$PWD/`basename "$2"`") )"
out="$( (cd "`dirname "$3"`"; echo "$PWD/`basename "$3"`") )"
abstemplate="$( (cd "`dirname "$template"`"; echo "$PWD/`basename "$template"`") )"

cd "`dirname "$abstemplate"`"

relfile="$(python -c 'import sys, os; print os.path.relpath(sys.argv[1], sys.argv[2])' "$file" "$PWD")"

# $PWD: template directory
# $1: subject file (relative to $PWD)
# $2: output file (unspecified if relative or absolute)

"$abstemplate" "$abstemplate" "$relfile" "$out"

