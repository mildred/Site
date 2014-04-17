# kate: hl sh;
JSESC=../node_modules/jsesc/bin/jsesc
JSONTOOL=../node_modules/jsontool/lib/jsontool.js
YAML2JSON=../node_modules/js-yaml-cli/bin/yaml2json.js

srcdir="${2%/*}"
outdir="${3%/*}"
basefile1="${1##*/}"
basefile2="${2##*/}"

redo-ifchange "$2.tags.meta.json"

relfilelist="$($JSONTOOL filelist <"$2.tags.meta.json")"
if [ -z "$relfilelist" ]; then
  relfilelist=..srclist
fi
filelistdir="${filelist%/*}"
filelist="${2%/*}/$relfilelist"

template="$($JSONTOOL template <"$2.tags.meta.json")"
: ${template:=template.jade}

tagattr="$($JSONTOOL tags <"$2.tags.meta.json")"
if [ -z "$tagattr" ]; then
  tagattr=tags
fi

redo-ifchange "$filelist"

tr '\n' '\0' <"$filelist" | xargs -0 -n 1 printf "%s/%s.meta.json\0" "$srcdir/$filelistdir" | xargs -0 sh -c '"$0" "$@" || exit 255' redo-ifchange

tag_list="$(
  (
    echo "["
    sep=""
    while read f; do
      echo "$sep"
      echo "{\"file\": $(echo "$f" | $JSESC --json),"
      echo " \"meta\":"
      if [ -s "$srcdir/$filelistdir/$f.meta.json" ]; then
        cat "$srcdir/$filelistdir/$f.meta.json"
      else
        echo null
      fi
      echo "}"
      sep=","
    done <"$filelist"
    echo "]"
  ) | $JSONTOOL -a "meta.$tagattr" | $JSONTOOL -g -a | sort | uniq
)"

:>"$3"

echo "$tag_list" >"$outdir/$basefile2.tags.taglist"

echo "$tag_list" | while read tag; do
  [ -z "$tag" ] && continue
  echo "$basefile2/$tag/index.index" >>"$3"
  mkdir -p "$outdir/$basefile2/$tag"
  (
    echo "---"
    (
      cat "$2.tags" | $YAML2JSON 
      filter="(this.meta.tags || []).indexOf($(echo "$tag" | $JSESC --json))>=0"
      printf "\n{\"filelist\": %s, \"filter\": %s, \"template\": %s}\n" \
        "$(echo "../../$relfilelist" | $JSESC --json)" \
        "$(echo "$filter" | $JSESC --json)" \
        "$(echo "../../$template" | $JSESC --json)"
    ) | $JSONTOOL -a --merge
  ) >"$outdir/$basefile2/$tag/index.index"
done

