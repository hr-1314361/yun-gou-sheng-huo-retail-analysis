-- 数据质量评估 - 维度3: 一致性检查
USE ydsh_ods;

-- 检查订单表中的user_id是否都在用户表中存在
SELECT 'order_user_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order o
LEFT JOIN ods_user u ON o.user_id = u.user_id
WHERE u.user_id IS NULL

UNION ALL

-- 检查订单表中的store_id是否都在门店表中存在
SELECT 'order_store_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order o
LEFT JOIN ods_store s ON o.store_id = s.store_id
WHERE s.store_id IS NULL

UNION ALL

-- 检查订单明细表中的order_id是否都在订单表中存在
SELECT 'order_item_order_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order_item oi
LEFT JOIN ods_order o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

-- 检查订单明细表中的product_id是否都在商品表中存在
SELECT 'order_item_product_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_order_item oi
LEFT JOIN ods_product p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

-- 检查用户行为表中的user_id是否都在用户表中存在
SELECT 'behavior_user_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_user_behavior b
LEFT JOIN ods_user u ON b.user_id = u.user_id
WHERE u.user_id IS NULL;
