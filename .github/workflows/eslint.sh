#!/bin/bash
if [ ! -f tmp/eslint-formatter-rdjson.js ]; then
  echo "formatter is not found" >&2
  exit 1
fi

npx eslint --resolve-plugins-relative-to=$(npm root -g) -f tmp/eslint-formatter-rdjson.js 'app/assets/**/*.{js,js.erb}'
