redo-always
basedir="${2%/*}/"
git ls-files "$2" | cut -c$((${#basedir}+1))- | tee "$3"
redo-stamp <"$3"

