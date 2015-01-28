#!/bin/bash

#
# install hts_engine_API
#
pushd .

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

echo "./configure"
./configure

echo "make"
make
if [ $? -ne 0 ]; then
  exit 1
fi

echo "make install"
sudo make install

popd

#
# install open_jtalk
#
pushd .

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

echo "./configure --with-charset=UTF-8"
./configure --with-charset=UTF-8

echo "make"
make
if [ $? -ne 0 ]; then
  exit 2
fi

echo "make install"
sudo make install

popd

#
# install lame
#
pushd .

echo "wget http://downloads.sourceforge.net/lame/lame-3.99.5.tar.gz"
wget http://downloads.sourceforge.net/lame/lame-3.99.5.tar.gz
if [ $? -ne 0 ]; then
  exit 3
fi

tar xvzf lame-3.99.5.tar.gz
cd lame-3.99.5
echo "./configure"
./configure

echo "make"
make
if [ $? -ne 0 ]; then
  exit 3
fi

echo "make install"
sudo make install

popd

#
# install sox
#
pushd .

echo "wget http://downloads.sourceforge.net/sox/sox-14.4.1.tar.gz"
wget http://downloads.sourceforge.net/sox/sox-14.4.1.tar.gz
if [ $? -ne 0 ]; then
  exit 4
fi

echo "tar xvzf sox-14.4.1.tar.gz"
tar xvzf sox-14.4.1.tar.gz
if [ $? -ne 0 ]; then
  exit 4
fi

cd sox-14.4.1

echo "./configure"
./configure
if [ $? -ne 0 ]; then
  exit 4
fi

echo "make"
make
if [ $? -ne 0 ]; then
  exit 4
fi

echo "make install"
sudo make install

popd

sudo ldconfig

exit 0
