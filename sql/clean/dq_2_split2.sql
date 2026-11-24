USE ydsh_ods;
SELECT 'ods_order' AS table_name, 'order_id' AS field_name, COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_count FROM ods_order
UNION ALL
SELECT 'ods_order_item', 'item_id', COUNT(*) - COUNT(DISTINCT item_id) FROM ods_order_item
UNION ALL
SELECT 'ods_user_behavior', 'behavior_id', COUNT(*) - COUNT(DISTINCT behavior_id) FROM ods_user_behavior;
