-- строки, файлы и размер таблиц (размер только по файлам данных)
WITH f AS (
  SELECT 'bronze.customer' AS tbl, content, file_size_in_bytes FROM bronze.tpch."customer$files"
  UNION ALL SELECT 'bronze.orders', content, file_size_in_bytes FROM bronze.tpch."orders$files"
  UNION ALL SELECT 'bronze.lineitem', content, file_size_in_bytes FROM bronze.tpch."lineitem$files"
  UNION ALL SELECT 'silver.building_orders', content, file_size_in_bytes FROM silver.tpch."building_orders$files"
  UNION ALL SELECT 'silver.order_lines', content, file_size_in_bytes FROM silver.tpch."order_lines$files"
  UNION ALL SELECT 'gold.q3_shipping_priority', content, file_size_in_bytes FROM gold.tpch."q3_shipping_priority$files"
),
r AS (
  SELECT 'bronze.customer' AS tbl, count(*) AS rows_cnt FROM bronze.tpch.customer
  UNION ALL SELECT 'bronze.orders', count(*) FROM bronze.tpch.orders
  UNION ALL SELECT 'bronze.lineitem', count(*) FROM bronze.tpch.lineitem
  UNION ALL SELECT 'silver.building_orders', count(*) FROM silver.tpch.building_orders
  UNION ALL SELECT 'silver.order_lines', count(*) FROM silver.tpch.order_lines
  UNION ALL SELECT 'gold.q3_shipping_priority', count(*) FROM gold.tpch.q3_shipping_priority
)
SELECT r.tbl, r.rows_cnt,
       count(*) AS files,
       sum(f.file_size_in_bytes) AS bytes,
       round(sum(f.file_size_in_bytes) / 1048576.0, 2) AS size_mb
FROM r JOIN f ON f.tbl = r.tbl AND f.content = 0
GROUP BY r.tbl, r.rows_cnt
ORDER BY 1;

-- формат и кодек
SELECT 'bronze.lineitem' AS tbl, key, value FROM bronze.tpch."lineitem$properties"
WHERE key IN ('write.format.default', 'write.parquet.compression-codec')
UNION ALL
SELECT 'silver.order_lines', key, value FROM silver.tpch."order_lines$properties"
WHERE key IN ('write.format.default', 'write.parquet.compression-codec')
UNION ALL
SELECT 'gold.q3_shipping_priority', key, value FROM gold.tpch."q3_shipping_priority$properties"
WHERE key IN ('write.format.default', 'write.parquet.compression-codec');
