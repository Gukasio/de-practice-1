#!/usr/bin/env bash
# остановить стек, с --purge удалить ещё и данные
set -euo pipefail

docker rm -f p1-trino p1-lakekeeper p1-pg p1-minio 2>/dev/null || true

if [ "${1:-}" = "--purge" ]; then
  docker volume rm p1-minio-data p1-pg-data 2>/dev/null || true
fi
