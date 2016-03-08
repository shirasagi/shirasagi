#!/bin/bash

if [ -f "$HOME/.local/bin/open_jtalk" ]; then
  echo 'Using cached open jtalk.'
  exit 0
fi

echo "wget http://downloads.sourceforge.net/open-jtalk/open_jtalk-1.07.tar.gz"
wget http://downloads.sourceforge.net/open-jtalk/open_jtalk-1.07.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

echo "tar xvzf open_jtalk-1.07.tar.gz"
tar xvzf open_jtalk-1.07.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

cd open_jtalk-1.07
sed -i "s/#define MAXBUFLEN 1024/#define MAXBUFLEN 10240/" bin/open_jtalk.c
sed -i "s/0x00D0 SPACE/0x000D SPACE/" mecab-naist-jdic/char.def

echo "./configure --with-charset=UTF-8 --prefix=$HOME/.local"
./configure --with-charset=UTF-8 --prefix=$HOME/.local --with-hts-engine-header-path=$HOME/.local/include --with-hts-engine-library-path=$HOME/.local/lib

echo "make"
make
if [ $? -ne 0 ]; then
  exit 2
fi

echo "make install"
make install
