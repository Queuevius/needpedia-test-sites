#!/bin/bash
set -euo pipefail

rm -f /app/tmp/pids/server.pid || true

if [ "${RAILS_ENV:-development}" != "production" ]; then
  echo "Waiting for database to become ready..."
  for i in $(seq 1 30); do
    if bundle exec rails db:migrate >/tmp/db-migrate.log 2>&1; then
      echo "Database is ready and migrated."
      break
    fi
    echo "Database not ready, retrying in 5s... (attempt $i/30)"
    sleep 5
    if [ "$i" = "30" ]; then
      echo "Database did not become ready in 30 attempts." >&2
      echo "Last migration error:" >&2
      tail -n 30 /tmp/db-migrate.log >&2 || true
      exit 1
    fi
  done
fi

exec "$@"


