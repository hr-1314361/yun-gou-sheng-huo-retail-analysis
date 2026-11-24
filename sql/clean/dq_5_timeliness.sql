-- 数据质量评估 - 维度5: 及时性检查
USE ydsh_ods;

-- 检查订单日期范围
SELECT 'order_date_range' AS check_name,
    MIN(order_date) AS min_date,
    MAX(order_date) AS max_date,
    COUNT(*) AS total_count
FROM ods_order

UNION ALL

-- 检查用户注册日期范围
SELECT 'register_date_range' AS check_name,
    MIN(register_date) AS min_date,
    MAX(register_date) AS max_date,
    COUNT(*) AS total_count
FROM ods_user

UNION ALL

-- 检查商品上架日期范围
SELECT 'launch_date_range' AS check_name,
    MIN(launch_date) AS min_date,
    MAX(launch_date) AS max_date,
    COUNT(*) AS total_count
FROM ods_product

UNION ALL

-- 检查门店开店日期范围
SELECT 'open_date_range' AS check_name,
    MIN(open_date) AS min_date,
    MAX(open_date) AS max_date,
    COUNT(*) AS total_count
FROM ods_store

UNION ALL

-- 检查用户行为时间范围
SELECT 'behavior_time_range' AS check_name,
    MIN(behavior_time) AS min_date,
    MAX(behavior_time) AS max_date,
    COUNT(*) AS total_count
FROM ods_user_behavior;
