#!/bin/bash

if [ -f $HOME/.local/bin/mecab ]; then
  echo 'Using cached mecab.'
  exit 0
fi

echo "tar xzf mecab-0.996.tar.gz"
tar xzf vendor/mecab/mecab-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

cd mecab-0.996
echo "./configure --enable-utf8-only --prefix=$HOME/.local"
./configure --enable-utf8-only --prefix=$HOME/.local

echo "make"
make
if [ $? -ne 0 ]; then
  exit 1
fi

echo "make install"
make install
