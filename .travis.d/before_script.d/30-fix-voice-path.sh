#!/bin/bash
echo "cp config/defaults/voice.yml config/"
cp config/defaults/voice.yml config/

echo "fixing open jtalk path"
sed -i "s#/usr/local/bin/open_jtalk#$HOME/.local/bin/open_jtalk#" config/voice.yml
sed -i "s#/usr/local/dic#$HOME/.local/dic#" config/voice.yml
sed -i "s#/usr/local/bin/sox#/usr/bin/sox#" config/voice.yml
sed -i "s#/usr/local/bin/lame#/usr/bin/lame#" config/voice.yml

diff -u config/defaults/voice.yml config/voice.yml
exit 0
