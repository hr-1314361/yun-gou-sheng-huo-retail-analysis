USE ydsh_ods;
SELECT 'order_item_product_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order_item oi
LEFT JOIN ods_product p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
