-- ============================================================
-- 第2周 子任务6（上）：DWD 层维度建模 DDL
-- 星型模型：以订单事实表为核心
--   事实表：dwd_order（订单明细粒度，按 order_date 分区，PARQUET）
--   维度表：dim_user / dim_product / dim_store / dim_date
-- 分区设计：dwd_order 按 order_date 一级分区，支持分区裁剪
-- 命名规范：ODS=ods_ / DWD=dwd_ / DWS=dws_ / ADS=ads_（见架构设计文档）
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dwd;
USE ydsh_dwd;

-- 1. 用户维度表
DROP TABLE IF EXISTS dim_user;
CREATE TABLE dim_user (
    user_id       STRING COMMENT '用户ID(主键)',
    user_name     STRING COMMENT '姓名',
    gender        STRING COMMENT '性别(男/女/未知)',
    age           INT    COMMENT '年龄(均值填充后)',
    province      STRING COMMENT '省',
    city          STRING COMMENT '市',
    region        STRING COMMENT '省市合并区域',
    register_date STRING COMMENT '注册日期(yyyy-MM-dd)',
    member_level  STRING COMMENT '会员等级(规范中文)',
    phone         STRING COMMENT '手机号(11位)',
    email         STRING COMMENT '邮箱(缺失标记unknown@)'
) STORED AS PARQUET;

-- 2. 商品维度表
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    product_id   STRING  COMMENT '商品ID(主键)',
    product_name STRING  COMMENT '商品名',
    category     STRING  COMMENT '品类',
    sub_category STRING  COMMENT '子类目',
    brand        STRING  COMMENT '品牌',
    price        DOUBLE  COMMENT '售价(异常处理后)',
    cost         DOUBLE  COMMENT '成本(异常处理后)',
    stock        INT     COMMENT '库存',
    status       STRING  COMMENT '状态(在售/缺货/下架)',
    launch_date  STRING  COMMENT '上架日期'
) STORED AS PARQUET;

-- 3. 门店维度表
DROP TABLE IF EXISTS dim_store;
CREATE TABLE dim_store (
    store_id   STRING  COMMENT '门店ID(主键)',
    store_name STRING  COMMENT '门店名',
    province   STRING  COMMENT '省',
    city       STRING  COMMENT '市',
    district   STRING  COMMENT '区',
    address    STRING  COMMENT '地址',
    region     STRING  COMMENT '省市合并区域',
    open_date  STRING  COMMENT '开业日期',
    area       DOUBLE  COMMENT '面积(㎡)',
    manager    STRING  COMMENT '店长'
) STORED AS PARQUET;

-- 4. 日期维度表（由订单日期生成，y/m/d/季度/星期）
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    date_key STRING COMMENT '日期yyyy-MM-dd(主键)',
    year     INT    COMMENT '年',
    month    INT    COMMENT '月',
    day      INT    COMMENT '日',
    quarter  INT    COMMENT '季度',
    weekday  INT    COMMENT '星期几(1=周一)'
) STORED AS PARQUET;

-- 5. 订单事实表（订单明细粒度，按订单日期分区，PARQUET列式存储）
DROP TABLE IF EXISTS dwd_order;
CREATE TABLE dwd_order (
    order_id     STRING COMMENT '订单ID',
    item_id      STRING COMMENT '明细ID',
    user_id      STRING COMMENT '用户ID(→dim_user)',
    store_id     STRING COMMENT '门店ID(→dim_store)',
    product_id   STRING COMMENT '商品ID(→dim_product)',
    quantity     INT    COMMENT '数量(异常修复后)',
    unit_price   DOUBLE COMMENT '成交单价(异常修复后)',
    discount     DOUBLE COMMENT '折扣率',
    amount       DOUBLE COMMENT '明细金额=数量*单价',
    pay_type     STRING COMMENT '支付方式(规范中文)',
    order_status STRING COMMENT '订单状态(规范中文)',
    channel      STRING COMMENT '下单渠道(规范中文)'
) PARTITIONED BY (order_date STRING COMMENT '订单日期(分区列)')
STORED AS PARQUET;
