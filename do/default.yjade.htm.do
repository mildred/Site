
JADE=$node_modules/jade/bin/jade.js

(
  read line
  if [ "a$line" = "a---" ]; then
    while read line; do
      [ "a$line" = "a---" ] && break
    done
    cat
  else
    cat "$2.yjade"
  fi
) <"$2.yjade" | ./Markdown >"$3"

