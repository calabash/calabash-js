#!/bin/bash
mkdir -p build
java -jar deps/yuicompressor-2.4.7.jar --type js --charset utf-8 -v --nomunge --preserve-semi --disable-optimizations src/calabash.js > calabash-min.tmp.js
java -jar deps/yuicompressor-2.4.7.jar --type js --charset utf-8 -v --nomunge --preserve-semi --disable-optimizations src/set_text.js > set_text-min.tmp.js

sed "s/\"/'/g" calabash-min.tmp.js > build/calabash-min.js
sed "s/\"/'/g" set_text-min.tmp.js > build/set_text-min.js
rm *-min.tmp.js
