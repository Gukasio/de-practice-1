#!/usr/bin/env bash
# тест кодеков: пересоздаём bronze, рестартуем, гоняем Q3 1 раз холодным и 3 раза повторно
# ZSTD последним, чтобы он остался в bronze
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CODECS="${CODECS:-GZIP SNAPPY NONE ZSTD}"

trino() { docker exec -i p1-trino trino "$@" 2>/dev/null; }

wait_trino() {
  until curl -sf http://localhost:9000/minio/health/ready >/dev/null; do sleep 1; done
  until [ "$(docker inspect -f '{{.State.Health.Status}}' p1-trino)" = healthy ]; do sleep 2; done
}

for codec in $CODECS; do
  echo "=== $codec"
  sed "s/compression_codec = 'ZSTD'/compression_codec = '$codec'/" "$ROOT/sql/bronze/load.sql" \
    | trino --source "load-$codec" >/dev/null

  # время записи (до рестарта, иначе история пропадёт)
  trino --output-format ALIGNED --execute "
    SELECT source, regexp_extract(query, 'bronze\.tpch\.(\w+)', 1) AS tbl,
           date_diff('millisecond', started, \"end\") / 1000.0 AS write_sec
    FROM system.runtime.queries
    WHERE source = 'load-$codec' AND query LIKE 'CREATE TABLE%'
    ORDER BY created" \
    | tee -a "$ROOT/results/50_perf_load_times.txt"

  trino --output-format ALIGNED --execute "
    SELECT '$codec' AS codec,
           round(sum(file_size_in_bytes) / 1048576.0, 1) AS bronze_mb
    FROM (SELECT file_size_in_bytes FROM bronze.tpch.\"customer\$files\"
          UNION ALL SELECT file_size_in_bytes FROM bronze.tpch.\"orders\$files\"
          UNION ALL SELECT file_size_in_bytes FROM bronze.tpch.\"lineitem\$files\")" \
    | tee -a "$ROOT/results/50_perf_sizes.txt"

  docker restart p1-minio p1-trino >/dev/null
  wait_trino
  trino --source "q3-$codec-cold" < "$ROOT/sql/perf/q3_bronze.sql" >/dev/null
  for i in 1 2 3; do
    trino --source "q3-$codec-warm$i" < "$ROOT/sql/perf/q3_bronze.sql" >/dev/null
  done

  trino --output-format ALIGNED --execute "
    SELECT source, state,
           date_diff('millisecond', started, \"end\") / 1000.0 AS exec_sec
    FROM system.runtime.queries
    WHERE source LIKE 'q3-$codec-%'
    ORDER BY created" \
    | tee -a "$ROOT/results/50_perf_times.txt"
done
