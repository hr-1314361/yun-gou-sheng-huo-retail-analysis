USE ydsh_ods;
SELECT 'order_item_order_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order_item oi
LEFT JOIN ods_order o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
