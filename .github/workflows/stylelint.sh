#!/bin/bash
# stylelint を reviewdog に組み込むための実行コマンドが長いのでシェルスクリプトにする。
#
# 参考: https://github.com/reviewdog/action-stylelint/blob/master/entrypoint.sh
/usr/bin/env npx stylelint -f json '{app,db}/**/*.{css,scss,sass}'\
  | jq -r '.[] | {source: .source, warnings:.warnings[]} | "\(.source):\(.warnings.line):\(.warnings.column):\(.warnings.severity): \(.warnings.text) [\(.warnings.rule)](https://stylelint.io/user-guide/rules/\(.warnings.rule))"'
