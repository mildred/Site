#!/usr/bin/env node

var arg1 = "../";
var input = "<toto><a href='titi'>link1</a><a href='tutu'>link2</a></toto>";

var jsdom = require("jsdom").jsdom;
var doc = jsdom(input, null, {});

function fixURLs(doc, tagName, attributeName, callback) {
  var links = doc.getElementsByTagName(tagName);
  for(var i = 0; i < links.length; ++i) {
    var href = links[i].getAttribute(attributeName);
    if(href) {
      links[i].setAttribute(attributeName, callback(href));
    }
  }
}

function makeCallbackPrefixURL(prefix) {
  return function(url) {
    return prefix + url;
  };
}

var htmlLinks = [
  ['img', 'src'],
  ['a',   'href']
]

var fix = makeCallbackPrefixURL(arg1);
for(var i = 0; i < htmlLinks.length; ++i) {
  fixURLs(doc, htmlLinks[i][0], htmlLinks[i][1], fix);
}

console.log(doc.innerHTML);
