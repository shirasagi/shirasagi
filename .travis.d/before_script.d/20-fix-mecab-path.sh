#!/bin/bash
echo "cp config/defaults/kana.yml config/"
cp config/defaults/kana.yml config/

echo "fixing mecab path"
sed -i "s#/usr/local/libexec/mecab/mecab-dict-index#$HOME/.local/libexec/mecab/mecab-dict-index#" config/kana.yml
sed -i "s#/usr/local/lib/mecab/dic/ipadic#$HOME/.local/lib/mecab/dic/ipadic#" config/kana.yml

diff -u config/defaults/kana.yml config/kana.yml
exit 0
