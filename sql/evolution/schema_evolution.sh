#!/usr/bin/env bash
# schema evolution на silver.tpch.building_orders
set -euo pipefail

T='silver.tpch.building_orders'
S='silver.tpch."building_orders$snapshots"'
q() { docker exec p1-trino trino --output-format ALIGNED --execute "$1" 2>&1 | grep -vE 'WARNING|jline'; }
v() { docker exec p1-trino trino --output-format TSV --execute "$1" 2>/dev/null; }

echo '--- исходная схема'
q "DESCRIBE $T"
FIRST=$(v "SELECT snapshot_id FROM silver.tpch.\"building_orders\$refs\" WHERE name = 'main'")
q "SELECT count(*) AS snapshots FROM $S"

echo '--- add column'
q "ALTER TABLE $T ADD COLUMN orderpriority varchar"
q "SELECT orderkey, orderdate, shippriority, orderpriority FROM $T ORDER BY orderkey LIMIT 3"
q "SELECT count(*) AS snapshots FROM $S"

echo '--- заполняем колонку из bronze'
q "MERGE INTO $T AS t
   USING bronze.tpch.orders AS s ON t.orderkey = s.orderkey
   WHEN MATCHED THEN UPDATE SET orderpriority = s.orderpriority"
q "SELECT orderpriority, count(*) AS orders FROM $T GROUP BY orderpriority ORDER BY 1"
q "SELECT snapshot_id, operation, committed_at FROM $S ORDER BY committed_at"

echo '--- rename column'
q "ALTER TABLE $T RENAME COLUMN shippriority TO ship_priority"
q "SELECT orderkey, ship_priority, orderpriority FROM $T ORDER BY orderkey LIMIT 3"
echo 'запрос со старым именем:'
q "SELECT shippriority FROM $T LIMIT 1" || true

echo '--- первый снапшот'
q "SELECT * FROM $T FOR VERSION AS OF $FIRST ORDER BY orderkey LIMIT 3"

echo '--- возвращаем имя'
q "ALTER TABLE $T RENAME COLUMN ship_priority TO shippriority"
q "DESCRIBE $T"
