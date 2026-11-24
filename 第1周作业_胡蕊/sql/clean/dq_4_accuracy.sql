-- 数据质量评估 - 维度4: 准确性检查
USE ydsh_ods;

-- 检查年龄是否在合理范围内 (0-150)
SELECT 'age_range' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_user
WHERE age < 0 OR age > 150

UNION ALL

-- 检查价格是否为负数
SELECT 'negative_price' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_product
WHERE price < 0

UNION ALL

-- 检查成本是否为负数
SELECT 'negative_cost' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_product
WHERE cost < 0

UNION ALL

-- 检查支付金额是否为负数
SELECT 'negative_pay_amount' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_order
WHERE pay_amount < 0

UNION ALL

-- 检查折扣金额是否为负数
SELECT 'negative_discount' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_order
WHERE discount_amount < 0

UNION ALL

-- 检查订单明细中的数量是否为负数或零
SELECT 'invalid_quantity' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_order_item
WHERE quantity <= 0

UNION ALL

-- 检查订单明细中的单价是否为负数
SELECT 'negative_unit_price' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_order_item
WHERE unit_price < 0

UNION ALL

-- 检查门店面积是否为负数
SELECT 'negative_area' AS check_name,
    COUNT(*) AS invalid_count
FROM ods_store
WHERE area < 0;
