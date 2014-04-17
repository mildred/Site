

file="$( (cd "`dirname "$2"`"; echo "$PWD/`basename "$2.jade"`") )"
out="$( (cd "`dirname "$3"`"; echo "$PWD/`basename "$3"`") )"

redo-ifchange "$2.jade.run"

cd "`dirname "$file"`"

"$file.run" "$file" "$file" "$out"

