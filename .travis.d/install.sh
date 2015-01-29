#!/bin/bash
base_dir=$(cd "$(dirname "$0")" && pwd)

for script in $base_dir/install.d/*.sh
do
  pushd .
  bash $script
  if [ $? -ne 0 ]; then
    exit $?
  fi
  popd
done
