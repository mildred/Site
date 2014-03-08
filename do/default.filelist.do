redo-always
basedir="${2%/*}/"
find "$2" -type f | egrep -v '\.(out|dest)$' | egrep -v '/.redo/' | cut -c$((${#basedir}+1))- | tee "$3"
redo-stamp <"$3"

