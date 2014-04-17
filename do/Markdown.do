if ! [ -e Markdown_1.0.1.zip.do ]; then
  echo 'wget http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip -O "$3"' >Markdown_1.0.1.zip.do
fi

redo-ifchange Markdown_1.0.1.zip
unzip -cq Markdown_1.0.1.zip Markdown_1.0.1/Markdown.pl >"$3"
chmod +x "$3"

# Patch Markdown to generate &#x000A; entities in code blocks instead of real
# line needs that could be easily normalized away in HTML.

#sed -r -i.bak -e '
#/sub _DoCodeBlocks/,/sub _DoCodeSpans/ {
#  /\$result =/ i			$codeblock =~ s/\\n/\&#x000A;/g;
#  s:\\n</code>:\&#x000A;</code>:
#}
#s:	(\$list =~ s/\\n\{2,\}/\\n\\n\\n/g;):	#\1:
#' "$3"

