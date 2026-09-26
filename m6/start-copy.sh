#!/usr/bin/env bash
# Convenience wrapper around the per-copy compose file.
# Usage: ./start-copy.sh <copy-name> <domain> [db-name]
set -euo pipefail

COPY_NAME="${1:?usage: start-copy.sh COPY_NAME DOMAIN [DB_NAME]}"
DOMAIN="${2:?usage: start-copy.sh COPY_NAME DOMAIN [DB_NAME]}"
PG_DB="${3:-needpedia_${COPY_NAME}}"

export COPY_NAME DOMAIN PG_DB
export DOMAIN_PROTOCOL="${DOMAIN_PROTOCOL:-http}"
export PG_USER="${PG_USER:-needpedia}"
export PG_PASSWORD="${PG_PASSWORD:-needpedia}"
export WEB_PORT="${WEB_PORT:-0}"

cd "$(dirname "$0")/.."

docker compose -p "np-${COPY_NAME}" -f m6/needpedia-copy.yml up -d

echo "Copy '${COPY_NAME}' started in project np-${COPY_NAME}."
echo "First boot: wait for the web container to become healthy, then run:"
echo "  docker compose -p np-${COPY_NAME} -f m6/needpedia-copy.yml exec -e DISABLE_SPRING=1 web bundle exec rails runner m6/demo_seeds.rb"
