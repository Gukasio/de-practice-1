-- gold: топ-10 заказов по выручке (ответ Q3)

CREATE SCHEMA IF NOT EXISTS gold.tpch;

SET SESSION gold.compression_codec = 'ZSTD';

DROP TABLE IF EXISTS gold.tpch.q3_shipping_priority;
CREATE TABLE gold.tpch.q3_shipping_priority WITH (format = 'PARQUET') AS
SELECT orderkey, sum(line_revenue) AS revenue, orderdate, shippriority
FROM silver.tpch.order_lines
GROUP BY orderkey, orderdate, shippriority
ORDER BY revenue DESC
LIMIT 10;
