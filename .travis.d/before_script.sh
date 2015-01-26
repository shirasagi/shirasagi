#!/bin/sh
base_dir=$(cd "$(dirname "$0")" && pwd)

for script in $base_dir/before_script.d/*.sh
do
  pushd .
  sh $script
  if [ $? -ne 0 ]; then
    exit $?
  fi
  popd
done
