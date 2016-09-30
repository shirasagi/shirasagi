#!/bin/bash

if [ -f $HOME/.local/lib/mecab/dic/ipadic/matrix.bin ]; then
  echo 'Using cached mecab ipadic.'
  exit 0
fi

echo "wget http://downloads.sourceforge.net/mecab/mecab-ipadic/2.7.0-20070801/mecab-ipadic-2.7.0-20070801.tar.gz"
wget http://downloads.sourceforge.net/mecab/mecab-ipadic/2.7.0-20070801/mecab-ipadic-2.7.0-20070801.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

echo "tar xzf mecab-ipadic-2.7.0-20070801.tar.gz"
tar xzf mecab-ipadic-2.7.0-20070801.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

cd mecab-ipadic-2.7.0-20070801
echo "./configure --with-charset=utf8 --prefix=$HOME/.local"
./configure --with-charset=utf8 --prefix=$HOME/.local

echo "make"
make
if [ $? -ne 0 ]; then
  exit 2
fi

echo "make install"
make install
