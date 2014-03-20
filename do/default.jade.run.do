
node_modules=$( (cd ".."; echo "$PWD") )/node_modules
JADE=$node_modules/jade/bin/jade.js
JSESC=$node_modules/jsesc/bin/jsesc

cat <<EOF >"$3"
#!/bin/sh

JADE='${JADE}'
JSESC='$JSESC'

EOF

cat <<"EOF" >>"$3"
template="${0%.run}"
relfile="$2"
out="$3"

redo-ifchange "$relfile.meta.json"
redo-ifchange "$relfile.dest"
redo-ifchange "$relfile.htm"
redo-ifchange "$relfile.args"

relpath="$(dirname "$relfile")/$(dirname "$(cat "$relfile.dest")")"
relpath="${relpath#./}"

args="(function(){
  var sh = require('execSync');

  var relpath = $(echo "$relpath" | $JSESC --json);
  var args = $(cat "$relfile.args");
  args.file = {
    'path': $(echo "$relfile" | $JSESC --json),
    'srcpath': $(echo "$relfile" | $JSESC --json),
    'destpath': $($JSESC --json <"$relfile.dest"),
    'meta': $(cat "$relfile.meta.json"),
    'html': $($JSESC --json <"$relfile.htm")
  };
  args.relpath = relpath;

  args.link = function(target) {
    if(target.match(/^[:/]+:/) || target.match(/^\//)) {
      return target;
    } else {

      var targetlink = path.relative(relpath, target);

      sh.run('redo-ifchange \'' + target.replace(/'/, '\'\"\'\"\'') + '.dest\'');

      //var spawn = require('child_process').spawn;
      //var redo = spawn('redo-ifchange', [target + '.dest'], {
      //  env: process.env,
      //  stdio: 'inherit' //[process.stdin, process.stderr, process.stderr]
      //});
      //redo.on('exit', function (code, signal) {
      //});

      try {
        data = fs.readFileSync(target + '.dest');
        var dest = data.toString('utf8').replace(/\n\$/, '');
        return path.relative(relpath, path.resolve(relpath, path.dirname(targetlink), dest));
      } catch(err) {
        return targetlink;
      }
    }
  };

  return args;
})()"

echo "$args" >"$out.args"
"$JADE" -O "$args" <"$template" >"$out"
EOF

chmod +x "$3"

