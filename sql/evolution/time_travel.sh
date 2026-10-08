#!/usr/bin/env bash
# удаляем часть данных из silver.tpch.order_lines и восстанавливаем из снапшота
set -euo pipefail

T='silver.tpch.order_lines'
q() { docker exec p1-trino trino --output-format ALIGNED --execute "$1" 2>/dev/null; }
v() { docker exec p1-trino trino --output-format TSV --execute "$1" 2>/dev/null; }

echo '--- до удаления'
q "SELECT snapshot_id, operation, committed_at FROM silver.tpch.\"order_lines\$snapshots\" ORDER BY committed_at"
GOOD=$(v "SELECT snapshot_id FROM silver.tpch.\"order_lines\$refs\" WHERE name = 'main'")
echo "snapshot: $GOOD"
q "SELECT count(*) AS rows_cnt, round(sum(line_revenue), 2) AS revenue FROM $T"

echo '--- удаляем'
q "DELETE FROM $T WHERE orderdate >= DATE '1995-01-01'"
q "SELECT count(*) AS rows_cnt, round(sum(line_revenue), 2) AS revenue FROM $T"
q "SELECT snapshot_id, operation, committed_at FROM silver.tpch.\"order_lines\$snapshots\" ORDER BY committed_at"

echo '--- старая версия'
q "SELECT count(*) AS rows_cnt FROM $T FOR VERSION AS OF $GOOD"

echo '--- откат'
q "ALTER TABLE $T EXECUTE rollback_to_snapshot($GOOD)"
q "SELECT count(*) AS rows_cnt, round(sum(line_revenue), 2) AS revenue FROM $T"
q "SELECT made_current_at, snapshot_id, parent_id, is_current_ancestor
   FROM silver.tpch.\"order_lines\$history\" ORDER BY made_current_at"
