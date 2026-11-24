USE ydsh_ods;
SELECT 'ods_user' AS table_name, 'user_id' AS field_name, COUNT(*) - COUNT(DISTINCT user_id) AS duplicate_count FROM ods_user
UNION ALL
SELECT 'ods_product', 'product_id', COUNT(*) - COUNT(DISTINCT product_id) FROM ods_product
UNION ALL
SELECT 'ods_store', 'store_id', COUNT(*) - COUNT(DISTINCT store_id) FROM ods_store;
