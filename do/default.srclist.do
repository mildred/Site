redo-always
basedir="${2%/*}/"
git ls-files "$2" | cut -c$((${#basedir}+1))- | tee "$3" >/dev/null
redo-stamp <"$3"

