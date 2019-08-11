#!/bin/bash
base_dir=$(cd "$(dirname "$0")" && pwd)

for script in $base_dir/install.d/*.sh
do
  echo "== $script"
  bash $script
  if [ $? -ne 0 ]; then
    exit $?
  fi
done
