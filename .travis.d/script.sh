#!/bin/bash
base_dir=$(cd "$(dirname "$0")" && pwd)

export PATH=$PATH:$HOME/.local/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib
export LD_RUN_PATH=$LD_RUN_PATH:$HOME/.local/lib

allow_open_jtalk=1 bundle exec rspec -p 30

## TestQueue
#
# rm -rf spec/jobs
# TEST_QUEUE_WORKERS=2 allow_open_jtalk=1 bundle exec bin/rspec-queue -r ./spec/silent_formatter.rb -f SilentFormatter --force-color spec/
