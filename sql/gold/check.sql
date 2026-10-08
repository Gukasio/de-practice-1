-- сравнение gold с исходным Q3 по tpch.sf1, должно быть 0
WITH reference AS (
  SELECT l.orderkey,
         round(sum(l.extendedprice * (1 - l.discount)), 2) AS revenue,
         o.orderdate, o.shippriority
  FROM tpch.sf1.customer c
  JOIN tpch.sf1.orders o ON c.custkey = o.custkey
  JOIN tpch.sf1.lineitem l ON l.orderkey = o.orderkey
  WHERE c.mktsegment = 'BUILDING'
    AND o.orderdate < DATE '1995-03-15'
    AND l.shipdate > DATE '1995-03-15'
  GROUP BY l.orderkey, o.orderdate, o.shippriority
  ORDER BY revenue DESC
  LIMIT 10
),
gold AS (
  SELECT orderkey, round(revenue, 2) AS revenue, orderdate, shippriority
  FROM gold.tpch.q3_shipping_priority
)
SELECT count(*) AS diff_rows FROM (
  (SELECT * FROM reference EXCEPT SELECT * FROM gold)
  UNION ALL
  (SELECT * FROM gold EXCEPT SELECT * FROM reference)
);
