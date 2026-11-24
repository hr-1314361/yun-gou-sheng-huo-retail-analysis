-- ============================================================
-- 第3周 子任务1（上）：DWS 汇总层 ETL
-- 从 ydsh_dwd.dwd_order 与维度表加载到 ydsh_dws 各汇总表
-- 策略：日粒度表按 stat_date 动态分区写入；周/月表全量重算
-- ============================================================

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 2048;
SET hive.exec.max.dynamic.partitions.pernode = 2048;

-- ============================================================
-- 1. dws_sales_1d：销售日汇总（全量，按天分区）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_sales_1d PARTITION (dt)
SELECT
    order_date AS stat_date,
    ROUND(SUM(amount), 2) AS gmv,
    COUNT(DISTINCT order_id) AS order_cnt,
    COUNT(DISTINCT user_id) AS user_cnt,
    SUM(quantity) AS item_cnt,
    ROUND(SUM(amount) / COUNT(DISTINCT order_id), 2) AS aov,
    ROUND(SUM(amount) / COUNT(DISTINCT user_id), 2) AS avg_per_user,
    order_date AS dt
FROM ydsh_dwd.dwd_order
GROUP BY order_date;

-- ============================================================
-- 2. dws_sales_category_1d：销售-品类日汇总（含GMV占比）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_sales_category_1d PARTITION (dt)
SELECT
    d.order_date AS stat_date,
    p.category,
    ROUND(SUM(d.amount), 2) AS gmv,
    COUNT(DISTINCT d.order_id) AS order_cnt,
    COUNT(DISTINCT d.user_id) AS user_cnt,
    SUM(d.quantity) AS item_cnt,
    ROUND(SUM(d.amount) / SUM(SUM(d.amount)) OVER (PARTITION BY d.order_date), 4) AS gmv_share,
    d.order_date AS dt
FROM ydsh_dwd.dwd_order d
JOIN ydsh_dwd.dim_product p ON d.product_id = p.product_id
GROUP BY d.order_date, p.category;

-- ============================================================
-- 3. dws_sales_store_1d：销售-门店日汇总
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_sales_store_1d PARTITION (dt)
SELECT
    d.order_date AS stat_date,
    s.store_id,
    s.store_name,
    s.province,
    s.city,
    ROUND(SUM(d.amount), 2) AS gmv,
    COUNT(DISTINCT d.order_id) AS order_cnt,
    COUNT(DISTINCT d.user_id) AS user_cnt,
    ROUND(SUM(d.amount) / COUNT(DISTINCT d.order_id), 2) AS aov,
    d.order_date AS dt
FROM ydsh_dwd.dwd_order d
JOIN ydsh_dwd.dim_store s ON d.store_id = s.store_id
GROUP BY d.order_date, s.store_id, s.store_name, s.province, s.city;

-- ============================================================
-- 4. dws_sales_channel_1d：销售-渠道日汇总（含GMV占比）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_sales_channel_1d PARTITION (dt)
SELECT
    order_date AS stat_date,
    channel,
    ROUND(SUM(amount), 2) AS gmv,
    COUNT(DISTINCT order_id) AS order_cnt,
    COUNT(DISTINCT user_id) AS user_cnt,
    ROUND(SUM(amount) / SUM(SUM(amount)) OVER (PARTITION BY order_date), 4) AS gmv_share,
    order_date AS dt
FROM ydsh_dwd.dwd_order
GROUP BY order_date, channel;

-- ============================================================
-- 5. dws_sales_1w：销售周汇总（自然周，周一至周日）
--    利用 dim_date 计算 week_key / week_start / week_end
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_sales_1w
SELECT
    concat(CAST(dd.year AS STRING), '-W', LPAD(CAST(FLOOR((dd.day + (SELECT MIN(day) FROM ydsh_dwd.dim_date WHERE year=dd.year AND month=1)) / 7) + 1 AS STRING), 2, '0')) AS week_key,
    MIN(d.order_date) AS week_start,
    MAX(d.order_date) AS week_end,
    ROUND(SUM(d.amount), 2) AS gmv,
    COUNT(DISTINCT d.order_id) AS order_cnt,
    COUNT(DISTINCT d.user_id) AS user_cnt,
    ROUND(SUM(d.amount) / COUNT(DISTINCT d.order_id), 2) AS aov
FROM ydsh_dwd.dwd_order d
JOIN ydsh_dwd.dim_date dd ON d.order_date = dd.date_key
GROUP BY dd.year, FLOOR((dd.day - 1) / 7)
ORDER BY week_start;

-- ============================================================
-- 6. dws_sales_1m：销售月汇总（含GMV环比）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_sales_1m
SELECT
    month_key,
    gmv,
    order_cnt,
    user_cnt,
    aov,
    ROUND((gmv - LAG(gmv) OVER (ORDER BY month_key)) / LAG(gmv) OVER (ORDER BY month_key), 4) AS mom_gmv
FROM (
    SELECT
        substr(order_date, 1, 7) AS month_key,
        ROUND(SUM(amount), 2) AS gmv,
        COUNT(DISTINCT order_id) AS order_cnt,
        COUNT(DISTINCT user_id) AS user_cnt,
        ROUND(SUM(amount) / COUNT(DISTINCT order_id), 2) AS aov
    FROM ydsh_dwd.dwd_order
    GROUP BY substr(order_date, 1, 7)
) t;

-- ============================================================
-- 7. dws_user_consume_1d：用户消费日汇总（复购率、价值分层用）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_dws.dws_user_consume_1d PARTITION (dt)
SELECT
    order_date AS stat_date,
    user_id,
    COUNT(DISTINCT order_id) AS order_cnt,
    ROUND(SUM(amount), 2) AS gmv,
    SUM(quantity) AS item_cnt,
    order_date AS dt
FROM ydsh_dwd.dwd_order
GROUP BY order_date, user_id;

-- ============================================================
-- 验证：抽查 2024-06-01 日汇总与品类汇总
-- ============================================================
-- SELECT * FROM ydsh_dws.dws_sales_1d WHERE dt='2024-06-01';
-- SELECT category, gmv, gmv_share FROM ydsh_dws.dws_sales_category_1d WHERE dt='2024-06-01' ORDER BY gmv DESC;
