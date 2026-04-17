#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/shirasagi

server="${APP_SERVER:-puma}"
server="${server,,}"
port="${PORT:-3000}"

puma_pidfile="${PUMA_PIDFILE:-tmp/pids/puma.pid}"
unicorn_pidfile="${UNICORN_PIDFILE:-tmp/pids/unicorn.pid}"

mkdir -p tmp/pids log

stop_pidfile() {
  local pidfile="$1"
  local signal="$2"

  if [[ -f "$pidfile" ]]; then
    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"
    if [[ -n "${pid}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "-$signal" "$pid" 2>/dev/null || true
      sleep 1
    fi
    rm -f "$pidfile"
  fi
}

stop_existing_servers() {
  stop_pidfile "$puma_pidfile" TERM
  stop_pidfile "tmp/pids/server.pid" TERM
  stop_pidfile "$unicorn_pidfile" QUIT
}

wait_for_port() {
  local retries=30
  local i

  for i in $(seq 1 "$retries"); do
    if ss -ltn | rg -q ":${port}\\b"; then
      echo "Web server is listening on port ${port} (${server})."
      return 0
    fi
    sleep 1
  done

  echo "Web server did not start on port ${port}. Check log/*.log" >&2
  return 1
}

start_puma() {
  nohup bundle exec puma \
    -C config/puma.rb \
    --pidfile "$puma_pidfile" \
    --redirect-stdout log/puma.stdout.log \
    --redirect-stderr log/puma.stderr.log \
    >/tmp/devcontainer-puma.out 2>&1 &
}

start_unicorn() {
  bundle exec rake unicorn:start
}

stop_existing_servers

case "$server" in
  puma)
    start_puma
    ;;
  unicorn)
    start_unicorn
    ;;
  *)
    echo "Unsupported APP_SERVER='${APP_SERVER:-}'. Use 'puma' or 'unicorn'." >&2
    exit 1
    ;;
esac

wait_for_port
