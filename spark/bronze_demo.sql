-- таблицы
SHOW NAMESPACES IN bronze;
SHOW TABLES IN bronze.tpch;
DESCRIBE TABLE bronze.tpch.orders;

-- количество строк
SELECT 'customer' AS tbl, count(*) AS rows_cnt FROM bronze.tpch.customer
UNION ALL SELECT 'orders',   count(*) FROM bronze.tpch.orders
UNION ALL SELECT 'lineitem', count(*) FROM bronze.tpch.lineitem;

-- снапшоты и файлы
SELECT snapshot_id, operation, committed_at FROM bronze.tpch.lineitem.snapshots;
SELECT count(*) AS data_files, round(sum(file_size_in_bytes) / 1048576, 1) AS size_mb
FROM bronze.tpch.lineitem.files;

-- Q3
SELECT
  l.orderkey,
  sum(l.extendedprice * (1 - l.discount)) AS revenue,
  o.orderdate,
  o.shippriority
FROM bronze.tpch.customer AS c
JOIN bronze.tpch.orders   AS o ON c.custkey = o.custkey
JOIN bronze.tpch.lineitem AS l ON l.orderkey = o.orderkey
WHERE c.mktsegment = 'BUILDING'
  AND o.orderdate < DATE '1995-03-15'
  AND l.shipdate > DATE '1995-03-15'
GROUP BY l.orderkey, o.orderdate, o.shippriority
ORDER BY revenue DESC
LIMIT 10;
