
JSESC=../node_modules/jsesc/bin/jsesc
YAML2JSON=../node_modules/js-yaml-cli/bin/yaml2json.js
JSONTOOL=../node_modules/jsontool/lib/jsontool.js

redo-ifchange "$2.meta.json"

cat <<EOF >"$3"

var meta  = $(cat "$2.meta.json");
var proto = {};

$($JSONTOOL prototype <"$2.index.meta.json")

Current = function(meta) {
  for(var k in meta) {
    this[k] = meta[k];
  }
};
Current.prototype = proto;

exports = new Current(meta);

EOF
