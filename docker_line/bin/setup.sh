#!/usr/bin/env bash
# 初回セットアップ（コンテナ内で実行される）。再実行しても壊れないようにしてある。
#   docker compose -f docker_line/docker-compose.yml run --rm web bash docker_line/bin/setup.sh
#
# やること:
#   1. gem / node modules の導入とアセットビルド
#   2. MongoDB インデックス作成
#   3. 自治体サンプルサイト（host=www）の作成とデモデータ投入
#      → デモデータには LINE HUB フォルダー（receiver）、ログイン（login）、マイページ（mypage）、
#        LINE 配信カテゴリー／配信条件が含まれる
#   4. LINE 連携マニュアルの「マイページ設定」に沿ったフォルダー整備と公開ドメイン設定
#      （docker_line/bin/setup_line_site.rb）
set -euo pipefail
cd /app

PORT="${PORT:-3000}"
SITE_HOST="${SITE_HOST:-www}"

echo "== Installing dependencies =="
bundle check >/dev/null 2>&1 || bundle install
yarn install --frozen-lockfile || yarn install
yarn build

echo "== Create indexes =="
bundle exec rake db:create_indexes

if bundle exec rails runner "exit(Cms::Site.where(host: '${SITE_HOST}').exists? ? 0 : 1)" >/dev/null 2>&1; then
  echo "== Site '${SITE_HOST}' already exists. skip seeding =="
else
  echo "== Create site '${SITE_HOST}' and seed demo data =="
  bundle exec rake ss:create_site data="{ name: '自治体サンプル', host: '${SITE_HOST}', domains: 'www.example.jp:${PORT}', mypage_domain: 'localhost:${PORT}', map_api: 'openlayers' }"
  bundle exec rake db:seed site="${SITE_HOST}" name=demo
  find public/sites/ -name '*.html' -delete
fi

echo "== Setup LINE related nodes / public domain =="
bundle exec rails runner docker_line/bin/setup_line_site.rb

cat <<MSG

== Done ==
管理画面:   http://localhost:${PORT}/.mypage  （admin / pass）
公開サイト: http://www.example.jp:${PORT}/     （/etc/hosts で 127.0.0.1 に向ける）
次の手順は docker_line/README.md の「LINE 側の設定」を参照。
MSG
