#!/bin/bash

wget http://mecab.googlecode.com/files/mecab-0.996.tar.gz
wget http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz
wget http://mecab.googlecode.com/files/mecab-ruby-0.996.tar.gz

pushd .
tar xvzf mecab-0.996.tar.gz && cd mecab-0.996
./configure --enable-utf8-only && make
sudo make install
popd

pushd .
tar xvzf mecab-ipadic-2.7.0-20070801.tar.gz && cd mecab-ipadic-2.7.0-20070801
./configure --with-charset=utf8 && make
sudo make install
popd

pushd .
tar xvzf mecab-ruby-0.996.tar.gz && cd mecab-ruby-0.996
ruby extconf.rb && make
make install
popd

echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf
sudo ldconfig
