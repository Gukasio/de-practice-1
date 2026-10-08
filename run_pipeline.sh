#!/usr/bin/env bash
# bronze -> silver -> gold, проверка и метрики
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
run() { echo "### $1"; docker exec -i p1-trino trino --output-format ALIGNED < "$ROOT/$1" 2>/dev/null; }

run sql/bronze/load.sql
run sql/silver/build.sql
run sql/gold/build.sql
run sql/gold/check.sql
run sql/metrics.sql
