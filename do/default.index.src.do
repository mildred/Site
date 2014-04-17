# kate: hl sh;
set -e
JADE=../node_modules/jade/bin/jade.js
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

srcdir="${2%/*}"
outdir="${3%/*}"
basefile1="${1##*/}"
basefile2="${2##*/}"

redo-ifchange "$2.index.meta.json"

template="$($JSONTOOL template <"$2.index.meta.json")"
: ${template:=template.jade}
template="$srcdir/$template"

atomtemplate="$($JSONTOOL atomtemplate <"$2.index.meta.json")"
: ${atomtemplate:=index.atom.jade}

numitems="$($JSONTOOL numitems <"$2.index.meta.json")"
: ${numitems:=10}

itemlistfile="$2.index.itemlist"
redo-ifchange "$itemlistfile"

sorted_list_asc="$(sort -n <"$itemlistfile" | cut -d' ' -f3-)"
sorted_list_desc="$(sort -n -r <"$itemlistfile" | cut -d' ' -f3-)"

generate(){
  let srcdirlen=${#srcdir}+1
  echo "{"
  echo "  \"pagenum\":   $([ -n "$1" ] && echo "$1" || echo null),"
  echo "  \"firstitem\": $([ -n "$2" ] && echo "$(($2-1))" || echo null),"
  echo "  \"lastitem\":  $([ -n "$3" ] && echo "$(($3-1))" || echo null),"
  echo "  \"template\":     $(echo "${template:$srcdirlen}"     | $JSESC --json),"
  echo "  \"atomtemplate\": $(echo "${atomtemplate}"            | $JSESC --json),"
  echo "  \"metafile\":     $(echo "$basefile2.index.meta.json" | $JSESC --json),"
  echo "  \"atompage\":     $(echo "$basefile2.atom.xml"        | $JSESC --json),"
  echo "  \"latestpage\":   $(echo "$basefile2.index"           | $JSESC --json),"
  echo "  \"pages\": ["
  local i=1
  separator=""
  while [ $i -le $numpages ]; do
    printf "$separator%s" "$(echo "$basefile2.$i.index" | $JSESC --json)"
    separator=",\n"
    i=$((i+1))
  done
  printf "\n],"
  echo "  \"items\": ["
  separator=""
  while read f; do
    [ -z "$f" ] && continue
    printf "$separator    %s" "$(echo "$f" | $JSESC --json)"
    separator=",\n"
  done
  printf "\n  ]"
  printf "}"
}

countitems=$(echo "$sorted_list_desc" | wc -l)
numpages=$(($countitems/$numitems))
if [ $(($countitems%$numitems)) -ne 0 ]; then
  numpages=$(($numpages+1))
fi

echo "$sorted_list_desc" \
  | head -n $numitems \
  | generate "" $(($countitems-$numitems+1)) $countitems >"$outdir/$basefile2.index.list"
echo "$basefile2.index" >>"$3"

echo "$basefile2.atom.xml" >>"$3"
$JSONTOOL -E "this.template = $(echo "${atomtemplate}" | $JSESC --json)" <"$outdir/$basefile2.index.list" >"$outdir/$basefile2.atom.xml.list"
$JSONTOOL -E "this.template = $(echo "${atomtemplate}" | $JSESC --json)" <"$2.index.meta.json" >"$outdir/$basefile2.atom.xml.meta.json"

let i=1 j=$numitems pagenum=1
while list="$(echo "$sorted_list_asc" | sed -n "${i},${j}p")"; [ -n "$list" ]; do
  echo "$list" | generate $pagenum $i $(($i+$(echo "$list" | wc -l)-1)) >"$outdir/$basefile2.$pagenum.index.list"
  cp --reflink "$2.index.meta.json" "$outdir/$basefile2.$pagenum.index.meta.json"
  : >"$outdir/$basefile2.$pagenum.index.src"
  echo "$basefile2.$pagenum.index" >>"$3"
  let i+=$numitems j+=$numitems pagenum+=1
done

