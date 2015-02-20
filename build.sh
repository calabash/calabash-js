#!/usr/bin/env bash

rm -rf build
mkdir -p build

CALABASH_TMP_JS=build/calabash-min.tmp.js
SET_TEXT_TMP_JS=build/set_text-min.tmp.js

java -jar deps/yuicompressor-2.4.7.jar --type js --charset utf-8 -v --nomunge --preserve-semi --disable-optimizations src/calabash.js > $CALABASH_TMP_JS
java -jar deps/yuicompressor-2.4.7.jar --type js --charset utf-8 -v --nomunge --preserve-semi --disable-optimizations src/set_text.js > $SET_TEXT_TMP_JS

sed "s/\"/'/g" $CALABASH_TMP_JS > build/calabash-min.js
sed "s/\"/'/g" $SET_TEXT_TMP_JS > build/set_text-min.js

rm -f $CALABASH_TMP_JS
rm -f $SET_TEXT_TMP_JS

