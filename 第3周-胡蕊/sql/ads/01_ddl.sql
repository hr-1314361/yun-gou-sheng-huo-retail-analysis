-- ============================================================
-- 第3周 子任务1（下）：ADS 应用层 DDL
-- 设计思路：
--   ADS = Application Data Service，面向具体业务场景的结果表
--   直接对接业务报表/看板/API，命名规范：ads_<业务场景>
--   本层不再分区，数据量小、查询频繁，按业务维度组织
-- 核心KPI：GMV、订单量、客单价、活跃用户数、复购率、品类销售占比
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_ads;
USE ydsh_ads;

-- 1. 销售日报表（每日核心经营指标，对接日报看板）
DROP TABLE IF EXISTS ads_sales_daily;
CREATE TABLE ads_sales_daily (
    stat_date        STRING COMMENT '统计日期',
    gmv              DOUBLE COMMENT '成交总额(元)',
    order_cnt        BIGINT COMMENT '订单量',
    user_cnt         BIGINT COMMENT '下单用户数',
    aov              DOUBLE COMMENT '客单价',
    avg_per_user     DOUBLE COMMENT '人均消费',
    item_cnt         BIGINT COMMENT '商品件数',
    gmv_yoy          DOUBLE COMMENT 'GMV同比(去年同日)',
    gmv_mom          DOUBLE COMMENT 'GMV环比(昨日)'
) STORED AS PARQUET;

-- 2. 品类销售TopN表（品类排名与占比，对接品类分析看板）
DROP TABLE IF EXISTS ads_category_topn;
CREATE TABLE ads_category_topn (
    stat_date        STRING COMMENT '统计日期',
    category         STRING COMMENT '品类',
    gmv              DOUBLE COMMENT '品类GMV',
    order_cnt        BIGINT COMMENT '品类订单量',
    user_cnt         BIGINT COMMENT '品类下单用户数',
    gmv_share        DOUBLE COMMENT '品类GMV占比',
    rank_no          INT    COMMENT '品类GMV排名'
) STORED AS PARQUET;

-- 3. 用户价值分层表（RFM模型简化版，对接用户运营）
DROP TABLE IF EXISTS ads_user_value_segment;
CREATE TABLE ads_user_value_segment (
    user_id          STRING COMMENT '用户ID',
    total_gmv        DOUBLE COMMENT '累计消费金额',
    total_order_cnt  BIGINT COMMENT '累计订单数',
    recency_days     INT    COMMENT '最近一次消费距今天数',
    frequency        BIGINT COMMENT '消费频次(订单数)',
    monetary         DOUBLE COMMENT '消费金额(同total_gmv)',
    r_score          INT    COMMENT 'R得分(1-5)',
    f_score          INT    COMMENT 'F得分(1-5)',
    m_score          INT    COMMENT 'M得分(1-5)',
    rfm_label        STRING COMMENT 'RFM分层标签(重要价值/重要发展/重要保持/重要挽留/一般价值/一般发展/一般保持/一般挽留)'
) STORED AS PARQUET;

-- 4. 核心KPI总表（全量周期汇总，对接经营驾驶舱）
DROP TABLE IF EXISTS ads_core_kpi;
CREATE TABLE ads_core_kpi (
    stat_period      STRING COMMENT '统计周期(如2024全年/2024-Q3)',
    gmv              DOUBLE COMMENT '成交总额',
    order_cnt        BIGINT COMMENT '订单量',
    user_cnt         BIGINT COMMENT '下单用户数',
    aov              DOUBLE COMMENT '客单价',
    repurchase_rate  DOUBLE COMMENT '复购率=复购用户数/总下单用户数',
    active_user_cnt  BIGINT COMMENT '活跃用户数(有行为/下单的用户)'
) STORED AS PARQUET;

-- 5. 复购率日趋势表（对接用户留存看板）
DROP TABLE IF EXISTS ads_repurchase_daily;
CREATE TABLE ads_repurchase_daily (
    stat_date        STRING COMMENT '统计日期',
    order_user_cnt   BIGINT COMMENT '当日下单用户数',
    repurchase_user_cnt BIGINT COMMENT '当日复购用户数(历史曾下单)',
    repurchase_rate  DOUBLE COMMENT '复购率'
) STORED AS PARQUET;
