USE ydsh_ods;
SELECT 'ods_user' AS tbl, COUNT(*) AS cnt FROM ods_user
UNION ALL SELECT 'ods_product', COUNT(*) FROM ods_product
UNION ALL SELECT 'ods_store', COUNT(*) FROM ods_store
UNION ALL SELECT 'ods_order', COUNT(*) FROM ods_order
UNION ALL SELECT 'ods_order_item', COUNT(*) FROM ods_order_item
UNION ALL SELECT 'ods_user_behavior', COUNT(*) FROM ods_user_behavior;
