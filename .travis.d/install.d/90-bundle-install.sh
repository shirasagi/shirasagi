#!/bin/bash
for i in $(seq 1 5)
do
  echo "$i of 5: bundle install --without development"
  bundle install --without development
  if [ $? -eq 0 ]; then
    break
  fi
done
