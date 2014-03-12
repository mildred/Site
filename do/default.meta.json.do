
JSESC=../node_modules/jsesc/bin/jsesc
YAML2JSON=../node_modules/js-yaml-cli/bin/yaml2json.js
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

redo-ifchange "$2"

(

  read first_line <"$2"
  if [ "a$first_line" = "a---" ] && meta="$( (cat "$2"; echo ---) | $YAML2JSON)" 2>/dev/null; then
    echo "$meta" | $JSONTOOL [0]
  fi

  (
    git log --pretty=format:'%H%n%an%n%ae%n%ai%n%at%n' -1 -- "$2"
    git log --pretty=format:'%H%n%an%n%ae%n%ai%n%at%n' --follow -- "$2" | tail -n 5
  ) | (
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
    
    : ${first_commit_id:=$last_commit_id}
    : ${first_commit_name:=$last_commit_name}
    : ${first_commit_mail:=$last_commit_mail}
    : ${first_commit_date:=$last_commit_date}
    : ${first_commit_stamp:=$last_commit_stamp}
    
    cat <<EOF
{
  "date_created":       $($JSESC --json <<<"$first_commit_date"),
  "timestamp_created":  $first_commit_stamp,
  "date_modified":      $($JSESC --json <<<"$last_commit_date"),
  "timestamp_modified": $last_commit_stamp,
  "creator":            $($JSESC --json <<<"$first_commit_name"),
  "creator_email":      $($JSESC --json <<<"$first_commit_mail"),
  "last_editor":        $($JSESC --json <<<"$last_commit_name"),
  "last_editor_email":  $($JSESC --json <<<"$last_commit_mail")
}
EOF

  )

) | $JSONTOOL --merge >"$3"

