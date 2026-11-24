-- ============================================================
-- 第3周 子任务1（下）：ADS 应用层 ETL + 核心KPI计算
-- 数据源：ydsh_dws 汇总层 + ydsh_dwd 明细层
-- 核心KPI：GMV、订单量、客单价、活跃用户数、复购率、品类销售占比
-- ============================================================

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

-- ============================================================
-- 1. ads_sales_daily：销售日报（含同比/环比）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_ads.ads_sales_daily
SELECT
    s.stat_date,
    s.gmv,
    s.order_cnt,
    s.user_cnt,
    s.aov,
    s.avg_per_user,
    s.item_cnt,
    -- 同比：去年同日 GMV 增长率（数据仅2024年，同比暂不可用，置NULL保留字段）
    CAST(NULL AS DOUBLE) AS gmv_yoy,
    -- 环比：相对昨日 GMV 增长率
    ROUND((s.gmv - LAG(s.gmv) OVER (ORDER BY s.stat_date))
          / LAG(s.gmv) OVER (ORDER BY s.stat_date), 4) AS gmv_mom
FROM ydsh_dws.dws_sales_1d s
ORDER BY s.stat_date;

-- ============================================================
-- 2. ads_category_topn：品类销售TopN（取全周期品类排名）
-- ============================================================
INSERT OVERWRITE TABLE ydsh_ads.ads_category_topn
SELECT
    '2024全年' AS stat_date,
    t.category,
    t.gmv,
    t.order_cnt,
    t.user_cnt,
    t.gmv_share,
    ROW_NUMBER() OVER (ORDER BY t.gmv DESC) AS rank_no
FROM (
    SELECT
        p.category,
        ROUND(SUM(d.amount), 2) AS gmv,
        COUNT(DISTINCT d.order_id) AS order_cnt,
        COUNT(DISTINCT d.user_id) AS user_cnt,
        ROUND(SUM(d.amount) / SUM(SUM(d.amount)) OVER (), 4) AS gmv_share
    FROM ydsh_dwd.dwd_order d
    JOIN ydsh_dwd.dim_product p ON d.product_id = p.product_id
    GROUP BY p.category
) t;

-- ============================================================
-- 3. ads_user_value_segment：用户价值分层（RFM模型）
--    R=最近消费距今天数，F=消费频次，M=消费金额
--    以数据集中最大日期作为"今天"基准
-- ============================================================
INSERT OVERWRITE TABLE ydsh_ads.ads_user_value_segment
WITH user_rfm AS (
    SELECT
        user_id,
        ROUND(SUM(amount), 2) AS total_gmv,
        COUNT(DISTINCT order_id) AS total_order_cnt,
        DATEDIFF(MAX(order_date), MIN(order_date)) + 1 AS lifecycle_days,
        DATEDIFF((SELECT MAX(order_date) FROM ydsh_dwd.dwd_order), MAX(order_date)) AS recency_days
    FROM ydsh_dwd.dwd_order
    GROUP BY user_id
),
rfm_scored AS (
    SELECT
        user_id,
        total_gmv,
        total_order_cnt,
        recency_days,
        total_order_cnt AS frequency,
        total_gmv AS monetary,
        -- R得分：recency越小越好，分5档(1-5)
        CASE
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 90 THEN 4
            WHEN recency_days <= 180 THEN 3
            WHEN recency_days <= 270 THEN 2
            ELSE 1
        END AS r_score,
        -- F得分：频次越高越好
        CASE
            WHEN total_order_cnt >= 10 THEN 5
            WHEN total_order_cnt >= 6 THEN 4
            WHEN total_order_cnt >= 3 THEN 3
            WHEN total_order_cnt >= 2 THEN 2
            ELSE 1
        END AS f_score,
        -- M得分：金额越高越好，按分位数近似分档
        CASE
            WHEN total_gmv >= 5000 THEN 5
            WHEN total_gmv >= 2000 THEN 4
            WHEN total_gmv >= 800 THEN 3
            WHEN total_gmv >= 200 THEN 2
            ELSE 1
        END AS m_score
    FROM user_rfm
)
SELECT
    user_id,
    total_gmv,
    total_order_cnt,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN '重要价值用户'
        WHEN r_score >= 4 AND f_score <= 2 AND m_score >= 4 THEN '重要发展用户'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN '重要保持用户'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4 THEN '重要挽留用户'
        WHEN r_score >= 4 AND f_score >= 4 AND m_score <= 2 THEN '一般价值用户'
        WHEN r_score >= 4 AND f_score <= 2 AND m_score <= 2 THEN '一般发展用户'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score <= 2 THEN '一般保持用户'
        ELSE '一般挽留用户'
    END AS rfm_label
FROM rfm_scored;

-- ============================================================
-- 4. ads_core_kpi：核心KPI总表（2024全年）
--    GMV、订单量、客单价、活跃用户数、复购率、品类销售占比
-- ============================================================
INSERT OVERWRITE TABLE ydsh_ads.ads_core_kpi
SELECT
    '2024全年' AS stat_period,
    ROUND(SUM(d.amount), 2) AS gmv,
    COUNT(DISTINCT d.order_id) AS order_cnt,
    COUNT(DISTINCT d.user_id) AS user_cnt,
    ROUND(SUM(d.amount) / COUNT(DISTINCT d.order_id), 2) AS aov,
    -- 复购率：下单>=2次的用户数 / 总下单用户数
    ROUND(
        SUM(CASE WHEN u.order_cnt >= 2 THEN 1 ELSE 0 END) * 1.0
        / COUNT(DISTINCT d.user_id), 4
    ) AS repurchase_rate,
    -- 活跃用户数：有下单行为的用户（行为表也可计入，此处用下单用户）
    COUNT(DISTINCT d.user_id) AS active_user_cnt
FROM ydsh_dwd.dwd_order d
LEFT JOIN (
    SELECT user_id, COUNT(DISTINCT order_id) AS order_cnt
    FROM ydsh_dwd.dwd_order
    GROUP BY user_id
) u ON d.user_id = u.user_id;

-- ============================================================
-- 5. ads_repurchase_daily：复购率日趋势
-- ============================================================
INSERT OVERWRITE TABLE ydsh_ads.ads_repurchase_daily
WITH daily_users AS (
    SELECT order_date, user_id, MIN(order_date) OVER (PARTITION BY user_id) AS first_order_date
    FROM ydsh_dwd.dwd_order
)
SELECT
    order_date AS stat_date,
    COUNT(DISTINCT user_id) AS order_user_cnt,
    COUNT(DISTINCT CASE WHEN order_date > first_order_date THEN user_id END) AS repurchase_user_cnt,
    ROUND(
        COUNT(DISTINCT CASE WHEN order_date > first_order_date THEN user_id END) * 1.0
        / COUNT(DISTINCT user_id), 4
    ) AS repurchase_rate
FROM daily_users
GROUP BY order_date
ORDER BY order_date;

-- ============================================================
-- 验证查询：核心KPI结果
-- ============================================================
-- SELECT * FROM ydsh_ads.ads_core_kpi;
-- SELECT * FROM ydsh_ads.ads_category_topn ORDER BY rank_no;
-- SELECT rfm_label, COUNT(*) AS user_cnt, ROUND(AVG(total_gmv),2) AS avg_gmv
-- FROM ydsh_ads.ads_user_value_segment GROUP BY rfm_label ORDER BY avg_gmv DESC;
