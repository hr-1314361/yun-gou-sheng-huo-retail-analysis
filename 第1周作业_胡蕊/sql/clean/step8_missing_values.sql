-- 步骤8: 数据清洗（一）——缺失值处理
-- 策略：age 用均值填充；email 保留空值标记 unknown@；launch_date 按规则补全（默认 2024-01-01）
-- 输出 DWD 目标表：dwd_user、dwd_product
USE ydsh_ods;

-- 1. 定位缺失字段
SELECT 'ods_user.age' AS field_name,
       SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM ods_user;

SELECT 'ods_user.email' AS field_name,
       SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM ods_user;

SELECT 'ods_product.launch_date' AS field_name,
       SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM ods_product;

-- 2. 用户表：age 用均值填充、email 保留空值标记，输出 DWD 目标表 dwd_user
DROP TABLE IF EXISTS dwd_user;
CREATE TABLE dwd_user AS
SELECT
    user_id,
    user_name,
    gender,
    COALESCE(age, u.avg_age) AS age,
    city,
    province,
    register_date,
    member_level,
    phone,
    CASE WHEN email IS NULL OR email = '' THEN 'unknown@' ELSE email END AS email
FROM ods_user
CROSS JOIN (SELECT ROUND(AVG(age)) AS avg_age FROM ods_user) u;

-- 3. 商品表：launch_date 缺失按规则补全（默认 2024-01-01），输出 dwd_product
DROP TABLE IF EXISTS dwd_product;
CREATE TABLE dwd_product AS
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    price,
    cost,
    stock,
    status,
    CASE WHEN launch_date IS NULL OR launch_date = '' THEN '2024-01-01' ELSE launch_date END AS launch_date
FROM ods_product;

-- 4. 验证：清洗后目标字段空值率显著下降（email 已转为可识别标记）
SELECT 'dwd_user.age' AS field_name,
       SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM dwd_user;

SELECT 'dwd_user.email' AS field_name,
       SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM dwd_user;

SELECT 'dwd_product.launch_date' AS field_name,
       SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM dwd_product;
