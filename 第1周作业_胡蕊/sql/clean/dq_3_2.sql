USE ydsh_ods;
SELECT 'order_store_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order o
LEFT JOIN ods_store s ON o.store_id = s.store_id
WHERE s.store_id IS NULL;
