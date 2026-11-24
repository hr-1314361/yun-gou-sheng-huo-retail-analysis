-- ============================================================
-- 第4周 子任务1：ADS 层扩展表
-- 目的：第3周 ADS 层缺少「支付方式」「区域」两个分析主题，
--       为使 Superset 所有图表均基于 ADS 层（而非直连 DWD 明细），
--       在此补充 2 张 ADS 汇总表，并给出 ETL。
-- 依赖：ydsh_dwd.dwd_order、ydsh_dwd.dim_store、ydsh_dws.dws_sales_store_1d
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_ads;
USE ydsh_ads;

-- 6. 支付方式日汇总表（对接支付方式占比饼图）
DROP TABLE IF EXISTS ads_pay_type_daily;
CREATE TABLE ads_pay_type_daily (
    stat_date   STRING COMMENT '统计日期',
    pay_type    STRING COMMENT '支付方式(支付宝/微信支付/货到付款/银行卡)',
    gmv         DOUBLE COMMENT '支付方式成交总额',
    order_cnt   BIGINT COMMENT '支付方式订单量',
    user_cnt    BIGINT COMMENT '支付方式下单用户数',
    aov         DOUBLE COMMENT '支付方式客单价',
    gmv_share   DOUBLE COMMENT '支付方式GMV占当日总GMV比例'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;

-- 7. 区域销售日汇总表（对接区域分布地图）
DROP TABLE IF EXISTS ads_region_sales;
CREATE TABLE ads_region_sales (
    stat_date   STRING COMMENT '统计日期',
    province    STRING COMMENT '省份(映射为地图名称，如 广东省)',
    gmv         DOUBLE COMMENT '区域成交总额',
    order_cnt   BIGINT COMMENT '区域订单量',
    user_cnt    BIGINT COMMENT '区域下单用户数',
    store_cnt   BIGINT COMMENT '区域有成交门店数',
    gmv_share   DOUBLE COMMENT '区域GMV占当日总GMV比例'
) PARTITIONED BY (dt STRING COMMENT '分区列=stat_date')
STORED AS PARQUET;

-- ------------------------------------------------------------
-- ETL 1：支付方式日汇总（从 DWD 明细按日 × 支付方式聚合）
-- 说明：支付方式维度基数极低(4)，直接在 DWD 上聚合成本可控
-- ------------------------------------------------------------
INSERT OVERWRITE TABLE ads_pay_type_daily PARTITION (dt)
SELECT
    t.stat_date,
    t.pay_type,
    t.gmv,
    t.order_cnt,
    t.user_cnt,
    CASE WHEN t.order_cnt = 0 THEN 0 ELSE t.gmv / t.order_cnt END AS aov,
    CASE WHEN t.total_gmv = 0 THEN 0 ELSE t.gmv / t.total_gmv END AS gmv_share
FROM (
    SELECT
        order_date AS stat_date,
        pay_type,
        SUM(amount)                AS gmv,
        COUNT(DISTINCT order_id)    AS order_cnt,
        COUNT(DISTINCT user_id)     AS user_cnt,
        SUM(SUM(amount)) OVER (PARTITION BY order_date) AS total_gmv
    FROM ydsh_dwd.dwd_order
    WHERE order_status IN ('已支付', '已完成')
    GROUP BY order_date, pay_type
) t;

-- ------------------------------------------------------------
-- ETL 2：区域日汇总（从 DWS 门店日汇总上卷到省，避免重复扫明细）
-- 说明：dws_sales_store_1d 已按 天 × 门店 聚合，
--       上卷到省只需一次轻量聚合，符合"从汇总层复用"的原则
-- ------------------------------------------------------------
INSERT OVERWRITE TABLE ads_region_sales PARTITION (dt)
SELECT
    t.stat_date,
    t.province,
    t.gmv,
    t.order_cnt,
    t.user_cnt,
    t.store_cnt,
    CASE WHEN t.total_gmv = 0 THEN 0 ELSE t.gmv / t.total_gmv END AS gmv_share
FROM (
    SELECT
        stat_date,
        province,
        SUM(gmv)                          AS gmv,
        SUM(order_cnt)                    AS order_cnt,
        SUM(user_cnt)                     AS user_cnt,
        COUNT(DISTINCT store_id)          AS store_cnt,
        SUM(SUM(gmv)) OVER (PARTITION BY stat_date) AS total_gmv
    FROM ydsh_dws.dws_sales_store_1d
    GROUP BY stat_date, province
) t;

-- ------------------------------------------------------------
-- 校验
-- ------------------------------------------------------------
-- 支付方式占比之和应为 1
SELECT stat_date, SUM(gmv_share) FROM ads_pay_type_daily GROUP BY stat_date LIMIT 5;
-- 区域占比之和应为 1
SELECT stat_date, SUM(gmv_share) FROM ads_region_sales GROUP BY stat_date LIMIT 5;
