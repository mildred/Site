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

filter="$($JSONTOOL filter <"$2.index.meta.json")"
if [ -z "$filter" ]; then
  filter=true
fi

filelist="$($JSONTOOL filelist <"$2.index.meta.json")"
if [ -z "$filelist" ]; then
  filelist=..srclist
fi
filelistdir="$(dirname "$filelist")"
filelist="${2%/*}/$filelist"

redo-ifchange "$filelist"
redo-ifchange "$template"

#echo "redo $2.index" >&2

list="$(
  while read f; do
    [ "a$2.index" = "a$filelistdir/$f" ] && continue
    redo-ifchange "$srcdir/$filelistdir/$f.dest"
    [ -s "$srcdir/$filelistdir/$f.dest" ] || continue
    redo-dofile "$srcdir/$filelistdir/$f.htm" >/dev/null || continue
    printf '%s\n' "$f"
  done <"$filelist")"

echo "$list" | tr '\n' '\0' | xargs -0 -n 1 printf "%s/%s.meta.json\0" "$srcdir/$filelistdir" | xargs -0 redo-ifchange

sortable_list="$(
  (
    echo "["
    sep=""
    echo "$list" | while read f; do
      echo "$sep"
      echo "{\"file\": $($JSESC --json <<<"$f"),"
      echo " \"meta\":"
      if [ -s "$srcdir/$filelistdir/$f.meta.json" ]; then
        cat "$srcdir/$filelistdir/$f.meta.json"
      else
        echo "{}"
      fi
      echo "}"
      sep=","
    done
    echo "]"
  ) | $JSONTOOL -C "$filter" | $JSONTOOL -a meta.timestamp_modified meta.timestamp_created file)"

sorted_list_asc="$(echo "$sortable_list" | sort -n | cut -d' ' -f3-)"
sorted_list_desc="$(echo "$sortable_list" | sort -n -r | cut -d' ' -f3-)"

generate(){
  let srcdirlen=${#srcdir}+1
  echo "{"
  echo "  \"pagenum\":  $([ -n "$1" ] && echo "$1" || echo null),"
  echo "  \"template\": $($JSESC --json <<<"${template:$srcdirlen}"),"
  echo "  \"items\": ["
  separator=""
  while read f; do
    printf "$separator    %s" "$(echo "$filelistdir/$f" | $JSESC --json)"
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
  : >"$outdir/$basefile2.$pagenum.index.src"
  echo "$basefile2.$pagenum.index" >>"$3"
  let i+=$numitems j+=$numitems pagenum+=1
done

