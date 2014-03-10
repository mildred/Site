#!/bin/bash
JADE=../node_modules/jade/bin/jade.js
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

outdir="${3%/*}"
basefile1="${1##*/}"
basefile2="${2##*/}"
srclistfile="$outdir/$basefile2.index.src"

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

list="$(tr '\n' '\0' <"$filelist" | xargs -0 -n 1 printf "%s/%s\n" "${2%/*}" | fgrep -v "$2.index" \
  | while read f; do
      redo-ifchange "$f.dest"
      [ -s $f.dest ] || continue
      printf '%s\n' "$f"
    done)"

echo "$list" | while read f; do printf "%s.meta.json\0%s.htm\0" "$f" "$f"; done | xargs -0 redo-ifchange

sortable_list="$(
  echo "$list" | while read f; do
    printf "%i %s\n" "$($JSONTOOL timestamp_modified <"$f.meta.json")" "$f";
  done)"

sorted_list_asc="$(echo "$sortable_list" | sort -n | cut -d' ' -f2-)"
sorted_list_desc="$(echo "$sortable_list" | sort -n -r | cut -d' ' -f2-)"

latest_items="$(echo "$sorted_list_desc" | head -n $numitems)"

readnlines(){
  let i=0
  while [ $i -lt $1 ]; do
    if ! read l; then
      if [ $i -eq 0 ]; then
        return 0
      else
        return 1
      fi
    fi
    echo "$l"
    let i=i+1
  done
}

#selectpage(){
#  local wantedpage=$1
#  local pagelength=$2
#  let pagenum=1
#  while [ $pagenum -lt $wantedpage ]; do
#    readnlines $pagelength >/dev/null || return 1
#    let pagenum=pagenum+1
#  done
#  readnlines $pagelength || return 1 
#}

generateargs(){
  echo "{ 'files': ["
  while read f; do
    echo "{'meta':"
    cat "$f.meta.json"
    echo ", 'html':"
    $JSESC --json <"$f.htm"
    echo "},"
  done
  echo "] }"
}

$JADE -O "$(echo "$sorted_list_desc" | readnlines $numitems | generateargs)" <"$template" >"$3"

echo "$basefile2.index" >"$srclistfile"

pageitems=""
break=false
let pagenum=1
let i=0
echo "$sorted_list_asc" | while true; do
  if read item; then
    pageitems="$pageitems
$item"
  else
    let i=$numitems
    break=true
  fi
  let i=i+1
  if [ $i -ge $numitems ]; then
    let i=0
    # skip first empty line
    pageitems=${pageitems:1}
    #echo "$pagenum: $pageitems <<< $(echo "$pageitems" | generateargs)" >&2
    $JADE \
      -O "$(echo "$pageitems" | generateargs)" \
      <"$template" \
      >"$outdir/$basefile2.index.$pagenum.out"
    #echo "-- $outdir/$basefile2.index.$pagenum.out"
    echo "$basefile2.index.$pagenum" >>"$srclistfile"
    let pagenum++
    $break && break
  fi
done

#let pagenum=1
#echo "$sorted_list_asc" | while pageitems="$(readnlines $numitems)"; do
#  #echo "$pagenum: $pageitems <<< $(echo "$pageitems" | generateargs)" >&2
#  $JADE \
#    -O "$(echo "$pageitems" | generateargs)" \
#    <"$template" \
#    >"$outdir/$basefile2.index.$pagenum.out"
#  echo "-- $outdir/$basefile2.index.$pagenum.out"
#  let pagenum=pagenum+1
#done

