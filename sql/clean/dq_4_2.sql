USE ydsh_ods;
SELECT 'negative_discount' AS check_name, COUNT(*) AS invalid_count FROM ods_order WHERE discount_amount < 0
UNION ALL
SELECT 'invalid_quantity', COUNT(*) FROM ods_order_item WHERE quantity <= 0
UNION ALL
SELECT 'negative_unit_price', COUNT(*) FROM ods_order_item WHERE unit_price < 0
UNION ALL
SELECT 'negative_area', COUNT(*) FROM ods_store WHERE area < 0;
