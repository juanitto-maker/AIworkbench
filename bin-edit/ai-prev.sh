#!/usr/bin/env bash
# Start a simple static server (http-server) and open the index
set -eo pipefail
PORT="${1:-8080}"
pgrep -f "http-server -p $PORT" >/dev/null 2>&1 || npx http-server -p "$PORT" >/dev/null 2>&1 &
sleep 1
termux-open-url "http://127.0.0.1:$PORT/"
echo "🌐 Opened http://127.0.0.1:$PORT/"