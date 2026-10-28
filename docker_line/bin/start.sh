#!/usr/bin/env bash
# web サービスの起動スクリプト（コンテナ内で実行される）。
# 依存の導入 → アセットが無ければビルド → puma 起動。
set -euo pipefail
cd /app

bundle check >/dev/null 2>&1 || bundle install
yarn install --frozen-lockfile || yarn install

# 管理画面の JS/CSS（webpack の出力先 app/assets/builds）が無ければビルドする。
# JS を変更したら `docker compose exec web yarn build` で再ビルドする。
if ! ls app/assets/builds/*.js >/dev/null 2>&1; then
  yarn build
fi

rm -f tmp/pids/server.pid
exec bundle exec puma -b tcp://0.0.0.0:3000
