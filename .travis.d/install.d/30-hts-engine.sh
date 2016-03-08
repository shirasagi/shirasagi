#!/bin/bash

if [ -f "$HOME/.local/include/HTS_engine.h" ]; then
  echo 'Using cached HTS Engine.'
  exit 0
fi

echo "wget http://downloads.sourceforge.net/hts-engine/hts_engine_API-1.08.tar.gz"
wget http://downloads.sourceforge.net/hts-engine/hts_engine_API-1.08.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

echo "tar xvzf hts_engine_API-1.08.tar.gz"
tar xvzf hts_engine_API-1.08.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

cd hts_engine_API-1.08

echo "./configure --prefix=$HOME/.local"
./configure --prefix=$HOME/.local

echo "make"
make
if [ $? -ne 0 ]; then
  exit 1
fi

echo "make install"
make install
