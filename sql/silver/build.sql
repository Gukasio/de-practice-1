-- silver: заказы BUILDING до 1995-03-15 и их позиции с отгрузкой после этой даты

CREATE SCHEMA IF NOT EXISTS silver.tpch;

SET SESSION silver.compression_codec = 'ZSTD';

DROP TABLE IF EXISTS silver.tpch.building_orders;
CREATE TABLE silver.tpch.building_orders WITH (format = 'PARQUET') AS
SELECT o.orderkey, o.custkey, c.mktsegment, o.orderdate, o.shippriority
FROM bronze.tpch.orders o
JOIN bronze.tpch.customer c ON c.custkey = o.custkey
WHERE c.mktsegment = 'BUILDING' AND o.orderdate < DATE '1995-03-15';

DROP TABLE IF EXISTS silver.tpch.order_lines;
CREATE TABLE silver.tpch.order_lines WITH (format = 'PARQUET') AS
SELECT l.orderkey, l.linenumber, bo.orderdate, bo.shippriority, l.shipdate,
       l.extendedprice, l.discount, l.extendedprice * (1 - l.discount) AS line_revenue
FROM bronze.tpch.lineitem l
JOIN silver.tpch.building_orders bo ON bo.orderkey = l.orderkey
WHERE l.shipdate > DATE '1995-03-15';
