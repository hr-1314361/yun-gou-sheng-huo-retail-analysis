-- ============================================================
-- ClickHouse 初始化：建库 + 建表（承接 ADS 结果，供即席分析/压测）
-- ============================================================
CREATE DATABASE IF NOT EXISTS ydsh_ads;

CREATE TABLE IF NOT EXISTS ydsh_ads.ads_sales_daily
(
    stat_date   Date,
    gmv         Float64,
    order_cnt   UInt64,
    user_cnt    UInt64,
    aov         Float64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(stat_date)
ORDER BY stat_date;

CREATE TABLE IF NOT EXISTS ydsh_ads.ads_category_topn
(
    stat_date   Date,
    category    String,
    gmv         Float64,
    order_cnt   UInt64,
    gmv_share   Float64,
    rank_no     UInt8
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(stat_date)
ORDER BY (stat_date, rank_no);
