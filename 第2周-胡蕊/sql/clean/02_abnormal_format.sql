-- ============================================================
-- 第2周 子任务2：数据清洗（二）—— 异常值与格式标准化
-- 说明：处理负金额、超大金额、年龄异常；统一日期为yyyy-MM-dd、
--       手机号11位、行为时间yyyy-MM-dd HH:mm:ss
-- 异常画像（清洗前统计）：
--   pay_amount <0      : 310 条      → ABS 修复
--   pay_amount >100000 : 312 条(超大,最大995万) → 置NULL标记不可信
--   discount_amount <0 : 769 条      → ABS 修复
--   price <0           : 20 条       → ABS 修复
--   price >10000       : 16 条(超大,最大85万)   → 置NULL
--   unit_price <0      : 798 条      → ABS 修复
--   quantity <=0       : 718 条(最小-2)         → ABS 修复
--   age 异常           : 27 条(负4/零8/>100共15)→ 置NULL后均值填充
--   age 缺失           : 51 条       → 均值填充
--   日期含'/'          : order_date 1902 / register_date 100
--   日期yyyymmdd       : register_date 25 条
--   行为时间'/'且无秒   : 6088 条
--   手机号带'-'        : 102 条
--   email为空串        : 193 条
--   launch_date缺失    : 11 条
-- ============================================================

USE ydsh_ods;

-- 1. 用户表：年龄异常/缺失 → 均值填充；手机号去分隔符；日期统一；邮箱补全
INSERT OVERWRITE TABLE ods_user_clean
SELECT t.user_id,
       t.user_name,
       t.gender,
       CAST(COALESCE(t.age_ok, m.avg_age) AS INT) AS age,
       t.city,
       t.province,
       CASE WHEN t.register_date REGEXP '^[0-9]{8}$'
            THEN concat(substr(t.register_date, 1, 4), '-', substr(t.register_date, 5, 2), '-', substr(t.register_date, 7, 2))
            ELSE regexp_replace(t.register_date, '/', '-')
       END AS register_date,
       t.member_level,
       regexp_replace(t.phone, '-', '') AS phone,
       CASE WHEN t.email = '' OR t.email IS NULL THEN 'unknown@' ELSE t.email END AS email
FROM (SELECT user_id, user_name, gender, age, city, province, register_date, member_level, phone, email,
             CASE WHEN age IS NOT NULL AND age >= 0 AND age <= 100
                  THEN CAST(age AS DOUBLE) END AS age_ok
      FROM ods_user_clean) t
CROSS JOIN (SELECT ROUND(AVG(CASE WHEN age IS NOT NULL AND age >= 0 AND age <= 100
                                  THEN CAST(age AS DOUBLE) END), 0) AS avg_age
            FROM ods_user_clean) m;

-- 2. 订单表：负金额取绝对值、超大金额置NULL、日期统一为yyyy-MM-dd、时间戳重算
INSERT OVERWRITE TABLE ods_order_clean
SELECT order_id,
       user_id,
       store_id,
       regexp_replace(order_date, '/', '-') AS order_date,
       order_time,
       concat(regexp_replace(order_date, '/', '-'), ' ', order_time) AS order_timestamp,
       CASE WHEN CAST(pay_amount AS DOUBLE) > 100000 THEN NULL
            ELSE ABS(CAST(pay_amount AS DOUBLE)) END AS pay_amount,
       ABS(CAST(discount_amount AS DOUBLE)) AS discount_amount,
       pay_type,
       order_status,
       channel
FROM ods_order_clean;

-- 3. 行为表：行为时间统一为 yyyy-MM-dd HH:mm:ss（'/'转'-'，缺秒补:00）
INSERT OVERWRITE TABLE ods_user_behavior_clean
SELECT behavior_id,
       user_id,
       product_id,
       behavior_type,
       CASE WHEN behavior_time REGEXP '/'
            THEN concat(regexp_replace(substr(behavior_time, 1, 10), '/', '-'),
                        ' ',
                        concat(substr(behavior_time, 12, 5), ':00'))
            ELSE behavior_time
       END AS behavior_time,
       session_id
FROM ods_user_behavior_clean;

-- 4. 商品表：负价格/负成本取绝对值、超大价格置NULL、缺失上架日期补默认值、
--    品类/子品类/品牌去除首尾及全角空格（27条品类值带尾部空格，导致分组分裂）
INSERT OVERWRITE TABLE ods_product_clean
SELECT product_id,
       product_name,
       regexp_replace(category, '\\s+|　', '') AS category,
       regexp_replace(sub_category, '\\s+|　', '') AS sub_category,
       brand,
       CASE WHEN CAST(price AS DOUBLE) > 10000 THEN NULL
            ELSE ABS(CAST(price AS DOUBLE)) END AS price,
       ABS(CAST(cost AS DOUBLE)) AS cost,
       stock,
       status,
       CASE WHEN launch_date = '' OR launch_date IS NULL THEN '2024-01-01' ELSE launch_date END AS launch_date
FROM ods_product_clean;

-- 5. 订单明细表：负数量/负单价/负折扣取绝对值
INSERT OVERWRITE TABLE ods_order_item_clean
SELECT item_id,
       order_id,
       product_id,
       CAST(ABS(CAST(quantity AS INT)) AS INT) AS quantity,
       ABS(CAST(unit_price AS DOUBLE)) AS unit_price,
       ABS(CAST(discount AS DOUBLE)) AS discount
FROM ods_order_item_clean;

-- 6. 门店表：营业面积负值取绝对值（当前无异常，作为兜底保障）
INSERT OVERWRITE TABLE ods_store_clean
SELECT store_id,
       store_name,
       province,
       city,
       district,
       address,
       open_date,
       ABS(CAST(area AS DOUBLE)) AS area,
       manager
FROM ods_store_clean;

-- 7. 验证：无负金额、格式统一（预期均为0）
-- SELECT COUNT(*) FROM ods_order_clean WHERE pay_amount < 0 OR discount_amount < 0;
-- SELECT COUNT(*) FROM ods_order_clean WHERE order_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
-- SELECT COUNT(*) FROM ods_user_clean WHERE phone NOT REGEXP '^[0-9]{11}$';
-- SELECT COUNT(*) FROM ods_user_behavior_clean WHERE behavior_time NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$';
