redo-always
( cd "$(dirname "$2")";
  git ls-files "${2##*/}") | tee "$3" >/dev/null
redo-stamp <"$3"

