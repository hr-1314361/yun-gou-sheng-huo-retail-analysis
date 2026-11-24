-- ============================================================
-- 第3周 子任务1：核心KPI指标结果查询
-- 输出：GMV、订单量、客单价、活跃用户数、复购率、品类销售占比
-- 执行方式：beeline -f 03_kpi_results.sql > kpi_results.txt
-- ============================================================

USE ydsh_ads;

-- 1. 核心KPI总览（2024全年）
SELECT '=== 1. 核心KPI总览(2024全年) ===' AS section;
SELECT
    stat_period,
    gmv              AS 'GMV(元)',
    order_cnt        AS '订单量',
    user_cnt         AS '下单用户数',
    aov              AS '客单价(元)',
    repurchase_rate  AS '复购率',
    active_user_cnt  AS '活跃用户数'
FROM ads_core_kpi;

-- 2. 品类销售占比TopN
SELECT '=== 2. 品类销售占比排名 ===' AS section;
SELECT
    rank_no          AS '排名',
    category         AS '品类',
    gmv              AS 'GMV(元)',
    order_cnt        AS '订单量',
    user_cnt         AS '下单用户数',
    gmv_share        AS 'GMV占比'
FROM ads_category_topn
ORDER BY rank_no;

-- 3. 用户价值分层分布
SELECT '=== 3. 用户价值分层(RFM)分布 ===' AS section;
SELECT
    rfm_label        AS '用户分层',
    COUNT(*)         AS '用户数',
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (), 4) AS '用户占比',
    ROUND(AVG(total_gmv), 2) AS '人均消费(元)',
    ROUND(AVG(total_order_cnt), 2) AS '人均订单数'
FROM ads_user_value_segment
GROUP BY rfm_label
ORDER BY 人均消费 DESC;

-- 4. 月度GMV趋势（含环比）
SELECT '=== 4. 月度GMV趋势(含环比) ===' AS section;
SELECT
    month_key        AS '月份',
    gmv              AS 'GMV(元)',
    order_cnt        AS '订单量',
    user_cnt         AS '下单用户数',
    aov              AS '客单价(元)',
    mom_gmv          AS 'GMV环比增长率'
FROM ydsh_dws.dws_sales_1m
ORDER BY month_key;

-- 5. 复购率日趋势（抽样最近30天）
SELECT '=== 5. 复购率日趋势(最近30天) ===' AS section;
SELECT
    stat_date        AS '日期',
    order_user_cnt   AS '下单用户数',
    repurchase_user_cnt AS '复购用户数',
    repurchase_rate  AS '复购率'
FROM ads_repurchase_daily
ORDER BY stat_date DESC
LIMIT 30;

-- 6. 渠道GMV占比（全年）
SELECT '=== 6. 渠道GMV占比(全年) ===' AS section;
SELECT
    channel          AS '渠道',
    ROUND(SUM(gmv), 2) AS 'GMV(元)',
    ROUND(SUM(gmv) / SUM(SUM(gmv)) OVER (), 4) AS 'GMV占比'
FROM ydsh_dws.dws_sales_channel_1d
GROUP BY channel
ORDER BY GMV DESC;

-- 7. 门店销售Top10（全年）
SELECT '=== 7. 门店销售Top10(全年) ===' AS section;
SELECT
    store_name       AS '门店',
    province         AS '省',
    city             AS '市',
    ROUND(SUM(gmv), 2) AS 'GMV(元)',
    SUM(order_cnt)   AS '订单量'
FROM ydsh_dws.dws_sales_store_1d
GROUP BY store_name, province, city
ORDER BY GMV DESC
LIMIT 10;
