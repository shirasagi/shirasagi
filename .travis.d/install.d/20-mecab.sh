#!/bin/bash

#
# install mecab
#
pushd .

echo "wget http://mecab.googlecode.com/files/mecab-0.996.tar.gz"
wget http://mecab.googlecode.com/files/mecab-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

echo "tar xzf mecab-0.996.tar.gz"
tar xzf mecab-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 1
fi

cd mecab-0.996
echo "./configure --enable-utf8-only"
./configure --enable-utf8-only

echo "make"
make
if [ $? -ne 0 ]; then
  exit 1
fi

echo "make install"
sudo make install

echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf.d/user-local.conf
echo "ldconfig"
sudo ldconfig
popd

#
# install ipadic
#

pushd .

echo "wget http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz"
wget http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

echo "tar xzf mecab-ipadic-2.7.0-20070801.tar.gz"
tar xzf mecab-ipadic-2.7.0-20070801.tar.gz
if [ $? -ne 0 ]; then
  exit 2
fi

cd mecab-ipadic-2.7.0-20070801
echo "./configure --with-charset=utf8"
./configure --with-charset=utf8

echo "make"
make
if [ $? -ne 0 ]; then
  exit 2
fi

echo "make install"
sudo make install
popd

#
# install mecab-ruby
#

pushd .

echo "wget http://mecab.googlecode.com/files/mecab-ruby-0.996.tar.gz"
wget http://mecab.googlecode.com/files/mecab-ruby-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 3
fi

echo "tar xzf mecab-ruby-0.996.tar.gz"
tar xzf mecab-ruby-0.996.tar.gz
if [ $? -ne 0 ]; then
  exit 3
fi

cd mecab-ruby-0.996

echo "ruby extconf.rb"
ruby extconf.rb

echo "make"
make
if [ $? -ne 0 ]; then
  exit 3
fi

echo "make install"
make install
popd
