#!/bin/bash
base_dir=$(cd "$(dirname "$0")" && pwd)

export PATH=$PATH:$HOME/.local/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib
export LD_RUN_PATH=$LD_RUN_PATH:$HOME/.local/lib

for script in $base_dir/before_script.d/*.sh
do
  echo "== $script"
  bash $script
  if [ $? -ne 0 ]; then
    exit $?
  fi
done

exit 0
