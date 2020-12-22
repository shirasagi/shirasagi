#!/bin/bash
for i in $(seq 1 5)
do
  echo "$i of 5: bundle install --without development --path vendor/bundle"
  bundle install --without development --path vendor/bundle
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    break
  fi
done

exit $exit_code
