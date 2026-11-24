-- ============================================================
-- 第3周 子任务1（上）：DWS 汇总层 DDL
-- 设计思路：
--   DWS = Data Warehouse Summary，面向主题的轻度汇总层
--   以 dwd_order 明细事实表为基础，按 时间(天/周/月) × 维度(品类/门店/渠道)
--   汇总 GMV、订单量、用户数、客单价等核心度量，供 ADS 层与看板直接消费
--   命名规范：dws_<主题>_<粒度>，如 dws_sales_1d 表示销售主题日粒度
-- 分区设计：日粒度表按 stat_date 分区，支持按天增量刷新
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dws;
USE ydsh_dws;

-- 1. 销售日汇总表（全量，按天）
DROP TABLE IF EXISTS dws_sales_1d;
CREATE TABLE dws_sales_1d (
    stat_date   STRING COMMENT '统计日期(yyyy-MM-dd)',
    gmv         DOUBLE COMMENT '成交总额(元)=SUM(amount)',
    order_cnt   BIGINT COMMENT '订单量=COUNT(DISTINCT order_id)',
    user_cnt    BIGINT COMMENT '下单用户数=COUNT(DISTINCT user_id)',
    item_cnt    BIGINT COMMENT '商品件数=SUM(quantity)',
    aov         DOUBLE COMMENT '客单价=gmv/order_cnt',
    avg_per_user DOUBLE COMMENT '人均消费=gmv/user_cnt'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;

-- 2. 销售-品类日汇总表（天 × 品类）
DROP TABLE IF EXISTS dws_sales_category_1d;
CREATE TABLE dws_sales_category_1d (
    stat_date   STRING COMMENT '统计日期',
    category    STRING COMMENT '商品品类',
    gmv         DOUBLE COMMENT '品类成交总额',
    order_cnt   BIGINT COMMENT '品类订单量',
    user_cnt    BIGINT COMMENT '品类下单用户数',
    item_cnt    BIGINT COMMENT '品类商品件数',
    gmv_share   DOUBLE COMMENT '品类GMV占当日总GMV比例'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;

-- 3. 销售-门店日汇总表（天 × 门店）
DROP TABLE IF EXISTS dws_sales_store_1d;
CREATE TABLE dws_sales_store_1d (
    stat_date   STRING COMMENT '统计日期',
    store_id    STRING COMMENT '门店ID',
    store_name  STRING COMMENT '门店名',
    province    STRING COMMENT '所在省',
    city        STRING COMMENT '所在市',
    gmv         DOUBLE COMMENT '门店成交总额',
    order_cnt   BIGINT COMMENT '门店订单量',
    user_cnt    BIGINT COMMENT '门店下单用户数',
    aov         DOUBLE COMMENT '门店客单价'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;

-- 4. 销售-渠道日汇总表（天 × 下单渠道）
DROP TABLE IF EXISTS dws_sales_channel_1d;
CREATE TABLE dws_sales_channel_1d (
    stat_date   STRING COMMENT '统计日期',
    channel     STRING COMMENT '下单渠道(APP/小程序/PC官网/门店)',
    gmv         DOUBLE COMMENT '渠道成交总额',
    order_cnt   BIGINT COMMENT '渠道订单量',
    user_cnt    BIGINT COMMENT '渠道下单用户数',
    gmv_share   DOUBLE COMMENT '渠道GMV占当日总GMV比例'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;

-- 5. 销售周汇总表（按自然周）
DROP TABLE IF EXISTS dws_sales_1w;
CREATE TABLE dws_sales_1w (
    week_key    STRING COMMENT '周标识(yyyy-Www)',
    week_start  STRING COMMENT '周起始日(周一)',
    week_end    STRING COMMENT '周结束日(周日)',
    gmv         DOUBLE COMMENT '周成交总额',
    order_cnt   BIGINT COMMENT '周订单量',
    user_cnt    BIGINT COMMENT '周下单用户数',
    aov         DOUBLE COMMENT '周客单价'
) STORED AS PARQUET;

-- 6. 销售月汇总表（按月）
DROP TABLE IF EXISTS dws_sales_1m;
CREATE TABLE dws_sales_1m (
    month_key   STRING COMMENT '月份(yyyy-MM)',
    gmv         DOUBLE COMMENT '月成交总额',
    order_cnt   BIGINT COMMENT '月订单量',
    user_cnt    BIGINT COMMENT '月下单用户数',
    aov         DOUBLE COMMENT '月客单价',
    mom_gmv     DOUBLE COMMENT 'GMV环比增长率(相对上月)'
) STORED AS PARQUET;

-- 7. 用户消费日汇总表（天 × 用户，用于复购率、用户价值分层）
DROP TABLE IF EXISTS dws_user_consume_1d;
CREATE TABLE dws_user_consume_1d (
    stat_date   STRING COMMENT '统计日期',
    user_id     STRING COMMENT '用户ID',
    order_cnt   BIGINT COMMENT '当日下单次数',
    gmv         DOUBLE COMMENT '当日消费金额',
    item_cnt    BIGINT COMMENT '当日购买件数'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;
