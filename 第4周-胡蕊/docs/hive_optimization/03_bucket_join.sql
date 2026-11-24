-- ============================================================
-- 优化场景 3：分桶 + Map Join（Bucket Map Join）
-- 场景：dwd_order（15000+ 行，持续增长）× dim_product（约 500 行）
--       默认走 Common Join，需要 Shuffle 全量事实表
-- ============================================================

-- 1) 维度表按关联键分桶（一次性建表，后续可增量写入）
DROP TABLE IF EXISTS ydsh_dwd.dim_product_bucket;
CREATE TABLE ydsh_dwd.dim_product_bucket (
    product_id    STRING,
    product_name  STRING,
    category      STRING,
    sub_category  STRING,
    brand         STRING,
    price         DOUBLE
)
CLUSTERED BY (product_id) INTO 16 BUCKETS
STORED AS PARQUET;

INSERT OVERWRITE TABLE ydsh_dwd.dim_product_bucket
SELECT product_id, product_name, category, sub_category, brand, price
FROM ydsh_dwd.dim_product;

-- 2) 事实表同样按 product_id 分桶（生产环境按天增量写入分桶表）
DROP TABLE IF EXISTS ydsh_dwd.dwd_order_bucket;
CREATE TABLE ydsh_dwd.dwd_order_bucket (
    order_id      STRING,
    user_id       STRING,
    store_id      STRING,
    product_id    STRING,
    quantity      INT,
    unit_price    DOUBLE,
    amount        DOUBLE,
    pay_type      STRING,
    order_status  STRING,
    channel       STRING
)
CLUSTERED BY (product_id) INTO 16 BUCKETS
PARTITIONED BY (order_date STRING)
STORED AS PARQUET;

-- 3) ❌ 优化前：普通 JOIN，事实表参与 Shuffle
EXPLAIN
SELECT
    p.category,
    SUM(o.amount) AS gmv
FROM ydsh_dwd.dwd_order o
JOIN ydsh_dwd.dim_product p ON o.product_id = p.product_id
WHERE o.order_date BETWEEN '2024-11-01' AND '2024-11-30'
GROUP BY p.category;

-- 4) ✅ 优化后：分桶表 + 自动 Map Join，小表广播、无 Reduce 端 Shuffle
SET hive.auto.convert.join = true;
SET hive.auto.convert.join.noconditionaltask = true;
SET hive.auto.convert.join.noconditionaltask.size = 20971520;  -- 20MB
SET hive.optimize.bucketmapjoin = true;

EXPLAIN
SELECT /*+ MAPJOIN(p) */
    p.category,
    SUM(o.amount) AS gmv
FROM ydsh_dwd.dwd_order_bucket o
JOIN ydsh_dwd.dim_product_bucket p ON o.product_id = p.product_id
WHERE o.order_date BETWEEN '2024-11-01' AND '2024-11-30'
GROUP BY p.category;

-- 5) 附加优化：列裁剪 + 谓词下推 + 小文件合并
SET hive.optimize.ppd = true;             -- 谓词下推（默认开启）
SET hive.merge.mapfiles = true;           -- 合并 Map 输出小文件
SET hive.merge.mapredfiles = true;        -- 合并 Reduce 输出小文件
SET hive.merge.size.per.task = 134217728; -- 128MB
SET hive.merge.smallfiles.avgsize = 16777216;

-- 只 SELECT 需要的列（避免 SELECT * 读取全部列）
SELECT o.order_date, o.amount
FROM ydsh_dwd.dwd_order_bucket o
WHERE o.order_date = '2024-11-11'
  AND o.order_status = '已完成';
