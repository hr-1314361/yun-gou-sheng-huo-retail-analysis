-- ============================================================
-- 第2周 子任务3：数据清洗（二）—— 字段拆分合并与编码映射
-- 说明：
--   ① 合并 order_date + order_time → order_timestamp（已在01/02脚本
--      于 ods_order_clean 中实现为 concat(order_date,' ',order_time)）
--   ② 合并 province + city → region（门店/用户区域字段）
--   ③ 建支付方式/会员等级编码维度表，并验证清洗后无残留英文编码
-- 验收：新字段生成正确、映射可关联、编码值收敛
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dwd;
USE ydsh_ods;

-- 1. 用户区域合并：province + city → region（重建用户清洗表追加region列）
DROP TABLE IF EXISTS ods_user_clean_v2;
CREATE TABLE ods_user_clean_v2 AS
SELECT user_id, user_name, gender, age, city, province,
       concat(province, city) AS region,
       register_date, member_level, phone, email
FROM ods_user_clean;
DROP TABLE ods_user_clean;
ALTER TABLE ods_user_clean_v2 RENAME TO ods_user_clean;

-- 2. 门店区域合并：province + city → region（重建门店清洗表追加region列）
DROP TABLE IF EXISTS ods_store_clean_v2;
CREATE TABLE ods_store_clean_v2 AS
SELECT store_id, store_name, province, city, district, address,
       concat(province, city) AS region,
       open_date, area, manager
FROM ods_store_clean;
DROP TABLE ods_store_clean;
ALTER TABLE ods_store_clean_v2 RENAME TO ods_store_clean;

-- 3. 字段合并验证：order_timestamp = order_date + ' ' + order_time
--    （拆回前后比对，预期不一致数为0）
SELECT COUNT(*) AS timestamp_mismatch
FROM ods_order_clean
WHERE order_timestamp <> concat(order_date, ' ', order_time);

-- 4. 编码维度表：支付方式映射表
DROP TABLE IF EXISTS ydsh_dwd.dim_pay_type;
CREATE TABLE ydsh_dwd.dim_pay_type (
    code STRING COMMENT '编码',
    name STRING COMMENT '中文标准名称'
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE;

INSERT INTO ydsh_dwd.dim_pay_type VALUES
    ('alipay', '支付宝'),
    ('wechat', '微信支付'),
    ('wx',     '微信支付'),
    ('cash',   '货到付款'),
    ('card',   '银行卡');

-- 5. 编码维度表：会员等级映射表
DROP TABLE IF EXISTS ydsh_dwd.dim_member_level;
CREATE TABLE ydsh_dwd.dim_member_level (
    code STRING COMMENT '编码',
    name STRING COMMENT '中文标准名称'
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE;

INSERT INTO ydsh_dwd.dim_member_level VALUES
    ('diamond', '钻石会员'),
    ('gold',    '金卡会员'),
    ('silver',  '银卡会员'),
    ('normal',  '普通会员');

-- 6. 映射关联验证1：清洗后订单表不应残留英文支付编码（预期0行）
SELECT o.pay_type, d.name
FROM ods_order_clean o
JOIN ydsh_dwd.dim_pay_type d ON o.pay_type = d.code
LIMIT 10;

-- 7. 映射关联验证2：清洗后用户表不应残留英文等级编码（预期0行）
SELECT u.member_level, d.name
FROM ods_user_clean u
JOIN ydsh_dwd.dim_member_level d ON u.member_level = d.code
LIMIT 10;

-- 8. 编码值域收敛验证（应输出6行规范值）
SELECT pay_type, COUNT(*) AS cnt FROM ods_order_clean GROUP BY pay_type;
