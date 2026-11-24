USE ydsh_ods;
-- 检查订单表中的user_id是否都在用户表中存在
SELECT 'order_user_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order o
LEFT JOIN ods_user u ON o.user_id = u.user_id
WHERE u.user_id IS NULL;
