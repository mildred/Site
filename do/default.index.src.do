# kate: hl sh;
JADE=../node_modules/jade/bin/jade.js
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

srcdir="${2%/*}"
outdir="${3%/*}"
basefile1="${1##*/}"
basefile2="${2##*/}"

redo-ifchange "$2.index.meta.json"

template="$($JSONTOOL template <"$2.index.meta.json")"
if [ -z "$template" ]; then
  template=index.jade
fi
template="${2%/*}/$template"

numitems="$($JSONTOOL numitems <"$2.index.meta.json")"
if [ -z "$numitems" ]; then
  numitems=10
fi

filelist="$($JSONTOOL filelist <"$2.index.meta.json")"
if [ -z "$filelist" ]; then
  filelist=..srclist
fi
filelist="${2%/*}/$filelist"

redo-ifchange "$filelist"
redo-ifchange "$template"

echo "redo $2.index" >&2

list="$(
  while read f; do
    [ "a$2.index" = "a$srcdir/$f" ] && continue
    redo-ifchange "$srcdir/$f.dest"
    [ -s "$srcdir/$f.dest" ] || continue
    printf '%s\n' "$f"
  done <"$filelist")"

echo "$list" | tr '\n' '\0' | xargs -0 -n 1 printf "%s/%s.meta.json\0" "$srcdir" | xargs -0 redo-ifchange

sortable_list="$(
  echo "$list" | while read f; do
    printf "%i %s\n" "$($JSONTOOL timestamp_modified <"$srcdir/$f.meta.json")" "$f";
  done)"

sorted_list_asc="$(echo "$sortable_list" | sort -n | cut -d' ' -f2-)"
sorted_list_desc="$(echo "$sortable_list" | sort -n -r | cut -d' ' -f2-)"

generate(){
  let srcdirlen=${#srcdir}+1
  echo "{"
  echo "  \"pagenum\":  $([ -n "$1" ] && echo "$1" || echo null),"
  echo "  \"template\": $($JSESC --json <<<"${template:$srcdirlen}"),"
  echo "  \"items\": ["
  separator=""
  while read f; do
    printf "$separator    %s" "$(echo "$f" | $JSESC --json)"
    separator=",\n"
  done
  printf "\n  ]"
  printf "}"
}

echo "$sorted_list_desc" | head -n $numitems | generate >"$outdir/$basefile2.index.list"
echo "$basefile2.index" >>"$3"

let i=1 j=$numitems pagenum=1
while list="$(echo "$sorted_list_asc" | sed -n "${i},${j}p")"; [ -n "$list" ]; do
  echo "$list" | generate $pagenum >"$outdir/$basefile2.$pagenum.index.list"
  echo "$basefile2.$pagenum.index" >>"$3"
  let i+=$numitems j+=$numitems pagenum+=1
done

