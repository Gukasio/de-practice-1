-- bronze: сырые таблицы из tpch.sf1 + источник и время загрузки

CREATE SCHEMA IF NOT EXISTS bronze.tpch;

SET SESSION bronze.compression_codec = 'ZSTD';

DROP TABLE IF EXISTS bronze.tpch.customer;
CREATE TABLE bronze.tpch.customer WITH (format = 'PARQUET') AS
SELECT c.*, 'tpch.sf1' AS _source, localtimestamp(6) AS _ingested_at
FROM tpch.sf1.customer AS c;

DROP TABLE IF EXISTS bronze.tpch.orders;
CREATE TABLE bronze.tpch.orders WITH (format = 'PARQUET') AS
SELECT o.*, 'tpch.sf1' AS _source, localtimestamp(6) AS _ingested_at
FROM tpch.sf1.orders AS o;

DROP TABLE IF EXISTS bronze.tpch.lineitem;
CREATE TABLE bronze.tpch.lineitem WITH (format = 'PARQUET') AS
SELECT l.*, 'tpch.sf1' AS _source, localtimestamp(6) AS _ingested_at
FROM tpch.sf1.lineitem AS l;
