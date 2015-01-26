#!/bin/bash

#
# install mecab
#
pushd .

wget http://mecab.googlecode.com/files/mecab-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

tar xvzf mecab-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

cd mecab-0.996
./configure --enable-utf8-only
make
if [ $? -ne 0 ]; then
  exit 1
fi

sudo make install

echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf.d/user-local.conf
sudo ldconfig
popd

#
# install ipadic
#

pushd .

wget http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

tar xvzf mecab-ipadic-2.7.0-20070801.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

cd mecab-ipadic-2.7.0-20070801
./configure --with-charset=utf8
make
if [ $? -ne 0 ]; then
  exit 2
fi

sudo make install
popd

#
# install mecab-ruby
#

pushd .

wget http://mecab.googlecode.com/files/mecab-ruby-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 3
fi

tar xvzf mecab-ruby-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 3
fi

cd mecab-ruby-0.996
ruby extconf.rb
make
if [ $? -ne 0 ]; then
  exit 3
fi

make install
popd
