
if which rdiscount >/dev/null 2>&1; then
  MARKDOWN=rdiscount
else
  redo-ifchange Markdown
  MARKDOWN=Markdown
fi

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
) <"$2.ymd" | (
  if [ $MARKDOWN = rdiscount ]; then
    ruby -e 'require "rdiscount"; STDOUT.write(RDiscount.new(STDIN.read, :autolink).to_html)'
  else
    ./Markdown
  fi
) | perl -pe 's/\n/\&#x000A;/g if (/<pre>/ .. /<\/pre>/ and not m/<\/pre>/)' >"$3"

