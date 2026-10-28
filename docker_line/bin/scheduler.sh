#!/usr/bin/env bash
# 本番 cron（settings/cron.html）の代わりに、LINE 配信予約とリッチメニュー更新を定期実行する。
#   - cms:line:deliver        LINE_DELIVER_INTERVAL 秒ごと（既定 900 = 15 分。本番 cron は */15）
#   - cms:line:apply_richmenu 1 日ごと（本番 cron は毎日 1:00）
set -uo pipefail
cd /app

SITE_HOST="${SITE_HOST:-www}"
DELIVER_INTERVAL="${LINE_DELIVER_INTERVAL:-900}"

echo "scheduler: site=${SITE_HOST} deliver every ${DELIVER_INTERVAL}s, apply_richmenu every 86400s"

(
  while true; do
    bundle exec rake cms:line:deliver site="${SITE_HOST}" || echo "cms:line:deliver failed (continue)"
    sleep "${DELIVER_INTERVAL}"
  done
) &

(
  while true; do
    bundle exec rake cms:line:apply_richmenu site="${SITE_HOST}" || echo "cms:line:apply_richmenu failed (continue)"
    sleep 86400
  done
) &

wait
