
redo-ifchange Markdown

(
  read line
  if [ "a$line" = "a---" ]; then
    while read line; do
      [ "a$line" = "a---" ] && break
    done
    cat
  else
    cat "$2.ymd"
  fi
) <"$2.ymd" | ./Markdown >"$3"

