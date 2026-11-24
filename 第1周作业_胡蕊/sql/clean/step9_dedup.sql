-- 步骤9: 数据清洗（一）——重复值检测与去重
-- 定位并去重 ods_order 中的重复订单（主键 order_id 重复），窗口函数保留每组第一条
-- 输出 DWD 目标表：dwd_order、dwd_order_item
USE ydsh_ods;

-- 1. 检测订单表中的重复 order_id（主键重复）
SELECT order_id, COUNT(*) AS cnt
FROM ods_order
GROUP BY order_id
HAVING cnt > 1
ORDER BY cnt DESC
LIMIT 10;

-- 2. 去重：ROW_NUMBER 窗口函数，按 order_date, order_time 排序保留第一条
--    输出去重后订单表 dwd_order
DROP TABLE IF EXISTS dwd_order;
CREATE TABLE dwd_order LIKE ods_order;
INSERT OVERWRITE TABLE dwd_order
SELECT order_id, user_id, store_id, order_date, order_time,
       pay_amount, discount_amount, pay_type, order_status, channel
FROM (
    SELECT *, ROW_NUMBER() OVER(
        PARTITION BY order_id ORDER BY order_date, order_time
    ) AS rn
    FROM ods_order
) t
WHERE rn = 1;

-- 3. 订单明细表：按 item_id 去重，输出 dwd_order_item
DROP TABLE IF EXISTS dwd_order_item;
CREATE TABLE dwd_order_item LIKE ods_order_item;
INSERT OVERWRITE TABLE dwd_order_item
SELECT item_id, order_id, product_id, quantity, unit_price, discount
FROM (
    SELECT *, ROW_NUMBER() OVER(
        PARTITION BY item_id ORDER BY order_id
    ) AS rn
    FROM ods_order_item
) t
WHERE rn = 1;

-- 4. 统计去重前后行数差异
SELECT 'ods_order' AS table_name, COUNT(*) AS row_count FROM ods_order
UNION ALL
SELECT 'dwd_order' AS table_name, COUNT(*) AS row_count FROM dwd_order
UNION ALL
SELECT 'ods_order_item' AS table_name, COUNT(*) AS row_count FROM ods_order_item
UNION ALL
SELECT 'dwd_order_item' AS table_name, COUNT(*) AS row_count FROM dwd_order_item;
