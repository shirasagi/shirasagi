#!/bin/bash

echo "tar xzf mecab-ruby-0.996.tar.gz"
tar xzf vendor/mecab/mecab-ruby-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 3
fi

cd mecab-ruby-0.996

#
# 標準の mecab ruby はオレオレインストールの mecab の include/lib を見れない。
# extconf.rb にパッチを当ててオレオレインストールの mecab の include/lib を見れるようにする。
#
cat << EOT | patch -p0
--- extconf.rb.orig	2013-02-17 17:24:16.000000000 +0000
+++ extconf.rb	2016-03-06 15:07:59.570019579 +0000
@@ -4,6 +4,7 @@
 use_mecab_config = enable_config('mecab-config')

 \`mecab-config --libs-only-l\`.chomp.split.each { | lib |
+  dir_config(lib)
   have_library(lib)
 }
EOT

echo "ruby extconf.rb --with-mecab-dir=$HOME/.local"
ruby extconf.rb "--with-mecab-dir=$HOME/.local"

echo "make"
make
if [ $? -ne 0 ]; then
  exit 3
fi

echo "make install"
make install
