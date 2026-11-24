-- ============================================================
-- 第4周 子任务1：Superset Dataset 定义 SQL
-- 说明：Superset 创建 Dataset 时使用 "SQL Lab → 保存为 Dataset（Virtual Dataset）" 方式，
--       即把下列 SQL 粘贴进 SQL Lab，另存为 Dataset。
--       所有数据集均只读 ADS 层结果表，不扫明细，保证看板查询稳定在秒级。
-- 数据库：ydsh_ads（Hive）
-- ============================================================

-- ------------------------------------------------------------
-- DS-1 销售趋势数据集（折线图 / KPI 卡）
-- 时间列：stat_date（DATETIME）；指标：gmv / order_cnt / user_cnt / aov
-- ------------------------------------------------------------
SELECT
    stat_date,
    gmv,
    order_cnt,
    user_cnt,
    aov,
    avg_per_user,
    item_cnt,
    gmv_yoy,
    gmv_mom
FROM ydsh_ads.ads_sales_daily;

-- ------------------------------------------------------------
-- DS-2 品类销售数据集（柱状图 / 品类筛选器）
-- ------------------------------------------------------------
SELECT
    stat_date,
    category,
    gmv,
    order_cnt,
    user_cnt,
    gmv_share,
    rank_no
FROM ydsh_ads.ads_category_topn;

-- ------------------------------------------------------------
-- DS-3 区域销售数据集（地图 / 区域筛选器）
-- 注意：province 需与 ECharts/Superset 地图名称一致（如 "广东省"）
-- ------------------------------------------------------------
SELECT
    stat_date,
    province,
    gmv,
    order_cnt,
    user_cnt,
    store_cnt,
    gmv_share
FROM ydsh_ads.ads_region_sales;

-- ------------------------------------------------------------
-- DS-4 支付方式数据集（饼图）
-- ------------------------------------------------------------
SELECT
    stat_date,
    pay_type,
    gmv,
    order_cnt,
    user_cnt,
    aov,
    gmv_share
FROM ydsh_ads.ads_pay_type_daily;

-- ------------------------------------------------------------
-- DS-5 TopN 排行数据集（排行榜表）
-- ------------------------------------------------------------
SELECT
    stat_date,
    category,
    gmv,
    order_cnt,
    gmv_share,
    rank_no
FROM ydsh_ads.ads_category_topn
WHERE rank_no <= 10;

-- ------------------------------------------------------------
-- DS-6 核心 KPI 数据集（大数字卡）
-- ------------------------------------------------------------
SELECT
    stat_period,
    gmv,
    order_cnt,
    user_cnt,
    aov,
    repurchase_rate,
    active_user_cnt
FROM ydsh_ads.ads_core_kpi;
