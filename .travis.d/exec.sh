#!/bin/bash
base_dir=$(cd "$(dirname "$0")" && pwd)
script=$base_dir/$1.d/$2.sh

echo "== $script"
bash $script
if [ $? -ne 0 ]; then
  exit $?
fi

exit 0
