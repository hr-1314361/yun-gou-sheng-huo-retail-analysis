-- 数据质量评估 - 维度2: 唯一性检查
USE ydsh_ods;

SELECT 'ods_user' AS table_name,
    'user_id' AS field_name,
    COUNT(*) - COUNT(DISTINCT user_id) AS duplicate_count
FROM ods_user

UNION ALL

SELECT 'ods_product' AS table_name,
    'product_id' AS field_name,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_count
FROM ods_product

UNION ALL

SELECT 'ods_store' AS table_name,
    'store_id' AS field_name,
    COUNT(*) - COUNT(DISTINCT store_id) AS duplicate_count
FROM ods_store

UNION ALL

SELECT 'ods_order' AS table_name,
    'order_id' AS field_name,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_count
FROM ods_order

UNION ALL

SELECT 'ods_order_item' AS table_name,
    'item_id' AS field_name,
    COUNT(*) - COUNT(DISTINCT item_id) AS duplicate_count
FROM ods_order_item

UNION ALL

SELECT 'ods_user_behavior' AS table_name,
    'behavior_id' AS field_name,
    COUNT(*) - COUNT(DISTINCT behavior_id) AS duplicate_count
FROM ods_user_behavior;
