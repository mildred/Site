
JSESC=../node_modules/jsesc/bin/jsesc
YAML2JSON=../node_modules/js-yaml-cli/bin/yaml2json.js
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

(

if meta="$($YAML2JSON <"$2")" 2>/dev/null; then
  echo "$meta" | $JSONTOOL [0]
fi

git log --follow --pretty=format:'%H%n%an%n%ae%n%ai' -- redo.py | (read l; echo "$l"; tail -n 1) | (
  read last_commit_id
  read last_commit_name
  read last_commit_mail
  read last_commit_date
  read first_commit_id
  read first_commit_name
  read first_commit_mail
  read first_commit_date
  cat <<EOF
{
  "date_created":      $(JSESC --json "$first_commit_date"),
  "date_modified":     $(JSESC --json "$last_commit_date"),
  "creator":           $(JSESC --json "$first_commit_name"),
  "creator_email":     $(JSESC --json "$first_commit_mail"),
  "last_editor":       $(JSESC --json "$last_commit_name"),
  "last_editor_email": $(JSESC --json "$last_commit_mail")
}
EOF
)

) | $JSONTOOL --merge >"$3"
