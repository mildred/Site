if ! [ -e Markdown_1.0.1.zip.do ]; then
  echo 'wget http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip -O "$3"' >Markdown_1.0.1.zip.do
fi

redo-ifchange Markdown_1.0.1.zip
unzip -cq Markdown_1.0.1.zip Markdown_1.0.1/Markdown.pl >"$3"
chmod +x "$3"

