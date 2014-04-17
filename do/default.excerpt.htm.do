redo-ifchange "$2.htm"
sed -n '1,/^<!--\s*break\s*-->$/ p' <"$2.htm" >"$3"
