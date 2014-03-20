
if [ -e "$2" ]; then
  redo-ifchange "$2.run"
  echo "${2##*/}.run" >"$3"
else
  redo-ifcreate "$2"
  parent="$(dirname "$2")/../$(basename "$2")"
  redo-ifchange "$parent.runfile"
  echo "../$(cat "$parent.runfile")" >"$3"
fi
