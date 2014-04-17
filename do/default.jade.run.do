
node_modules=$( (cd ".."; echo "$PWD") )/node_modules
JADE=$node_modules/jade/bin/jade.js
JSESC=$node_modules/jsesc/bin/jsesc

cat <<EOF >"$3"
#!/bin/sh

# Expects $PWD to be in the template directory
# $1 is the template file (not used, inferred from $0)
# $2 is the subject file, may not be empty
# $3 is the output file

set -e
JADE='${JADE}'
JSESC='$JSESC'

EOF

cat <<"EOF" >>"$3"
template="${0%.run}"
relfile="$(python -c 'import sys, os; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$2" "$PWD")"
out="$3"

if [ "a$2" = "a$1" ]; then
  istemplate=false
else
  istemplate=true
fi

redo-ifchange "$template"
redo-ifchange "$template.meta.json"
redo-ifchange "$template.args"
redo-ifchange "$relfile.meta.json"
redo-ifchange "$relfile.dest"
redo-ifchange "$relfile.args"
if $istemplate; then
  redo-ifchange "$relfile.htm"
  redo-ifchange "$relfile.excerpt.htm"
fi

relpath="$(dirname "$relfile")"
relpath="${relpath#./}"

reldestpath="$(dirname "$(cat "$relfile.dest")")"

html_content="$(if $istemplate; then $JSESC --json <"$relfile.htm"; fi)"
: ${html_content:=null}

html_excerpt="$(if $istemplate; then $JSESC --json <"$relfile.excerpt.htm"; fi)"
: ${html_excerpt:=$html_content}

args="(function(){
  var sh = require('execSync');

  var relpath = $(echo "$relpath" | $JSESC --json);
  var reldestpath = path.join(relpath, $(echo "$reldestpath" | $JSESC --json));
  var argsdir = relpath;
  var args = $(cat "$relfile.args");
  args.meta = $(cat "$template.meta.json")
  args.file = {
    'path':     path.resolve(relpath, $(echo "$(basename "$relfile")" | $JSESC --json)),
    'srcpath':  path.resolve(relpath, $(echo "$(basename "$relfile")" | $JSESC --json)),
    'destpath': path.resolve(relpath, $($JSESC --json <"$relfile.dest")),
    'meta': $(cat "$relfile.meta.json"),
    'html': $html_content,
    'excerpt': $html_excerpt,
    link: function(target) {
      return args.link(target, reldestpath, relpath);
    }
  };
  args.relpath = relpath;
  args.template = $(cat "$template.args");
  
  args.require = require;
  
  args.link = function(target, reldest, relpath) {
    if(!reldest) reldest = reldestpath;
    if(!relpath) relpath = '.';
    if(target.match(/^[:/]+:/) || target.match(/^\/\//)) {
      return target;
    } else {

      var destfile = path.resolve(relpath, target + '.dest')

      sh.run('redo-ifchange \'' + destfile.replace(/'/, '\'\"\'\"\'') + '\'');

      //var spawn = require('child_process').spawn;
      //var redo = spawn('redo-ifchange', [destfile], {
      //  env: process.env,
      //  stdio: 'inherit' //[process.stdin, process.stderr, process.stderr]
      //});
      //redo.on('exit', function (code, signal) {
      //});

      var absdest = target;
      
      try {
        data = fs.readFileSync(destfile);
        var dest = data.toString('utf8').replace(/\n\$/, '');
        if(dest !== '') {
          absdest = path.resolve(path.dirname(destfile), dest);
        }
      } catch(err) {
      }

      var res = path.relative(reldest, absdest).replace(/\/index.html/, '/');
      if(target[target.length-1] == '/') {
        if(res == '') res = './'
        else          res += '/';
      }
      return res;
    }
  };

  return args;
})()"

echo "$args" >"$out.args"



(
  read line
  if [ "a$line" = "a---" ]; then
    echo
    while read line; do
      echo
      [ "a$line" = "a---" ] && break
    done
    cat
  else
    cat "$template"
  fi
) <"$template" | "$JADE" -O "$args" >"$out"

EOF

chmod +x "$3"

