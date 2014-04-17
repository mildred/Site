
JSESC=../node_modules/jsesc/bin/jsesc
YAML2JSON=../node_modules/js-yaml-cli/bin/yaml2json.js
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

if [ -f "$2" ]; then
  redo-ifchange "$2"
else
  redo-ifcreate "$2"
  exit 1
fi

(
  created_at=
  created_at_stamp=
  author=
  author_email=

  read first_line <"$2" || exit 1
  if [ "a$first_line" = "a---" ]; then
    yaml="$(sed -n -r -e '1 p; 2,/^(---|\.\.\.)\s*(name:.*)?$/ p' "$2")"
    if meta="{\"self\": $(echo "$yaml" | $YAML2JSON) }"; then
      meta="$(echo "$meta" | $JSONTOOL -e 'self = (self.__proto__.length === 0) ? self[0] : self' self)"
      echo "$meta"
      created_at="$(echo "$meta" | $JSONTOOL created_at)"
      created_at_stamp="$(echo "$created_at" | date +%s)"
      author="$(echo "$meta" | $JSONTOOL author)"
      author_email="$(echo "$meta" | $JSONTOOL author_email)"
    else
      echo "$yaml" >&2
      echo "$meta" >&2
    fi
  fi

  ( set +e
    cd "$(dirname "$2")"
    f="$(basename "$2")"
    git log --pretty=format:'%H%n%an%n%ae%n%ai%n%at%n' -1 -- "$f"
    git log --pretty=format:'%H%n%an%n%ae%n%ai%n%at%n' --follow -- "$f" | tail -n 5
  ) | (
    set +e
    read last_commit_id
    read last_commit_name
    read last_commit_mail
    read last_commit_date
    read last_commit_stamp
    read first_commit_id
    read first_commit_name
    read first_commit_mail
    read first_commit_date
    read first_commit_stamp
    
    : ${last_commit_stamp:=null}
    : ${first_commit_id:=$last_commit_id}
    : ${first_commit_name:=$last_commit_name}
    : ${first_commit_mail:=$last_commit_mail}
    : ${first_commit_date:=$last_commit_date}
    : ${first_commit_stamp:=$last_commit_stamp}
    
    cat <<EOF
{
  "date_created":       $(echo "${created_at:-$first_commit_date}" | $JSESC --json),
  "timestamp_created":  ${created_at_stamp:-$first_commit_stamp},
  "date_modified":      $(echo "$last_commit_date"  | $JSESC --json),
  "timestamp_modified": ${last_commit_stamp},
  "creator":            $(echo "${author:-$first_commit_name}" | $JSESC --json),
  "creator_email":      $(echo "${author_email:-$first_commit_mail}" | $JSESC --json),
  "last_editor":        $(echo "$last_commit_name"  | $JSESC --json),
  "last_editor_email":  $(echo "$last_commit_mail"  | $JSESC --json)
}
EOF

  )
  
  echo "{}"

) | $JSONTOOL --merge >"$3"

redo-stamp <"$3"

if ! [ -s "$3" ]; then
  echo "Poscondition failed: empty ${2##*/}.meta.json file" >&2
  exit 1
fi


