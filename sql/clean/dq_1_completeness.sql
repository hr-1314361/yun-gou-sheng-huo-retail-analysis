-- 数据质量评估 - 维度1: 完整性检查
USE ydsh_ods;

SELECT 'ods_user' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END) AS user_id_null,
    SUM(CASE WHEN user_name IS NULL OR user_name = '' THEN 1 ELSE 0 END) AS user_name_null,
    SUM(CASE WHEN gender IS NULL OR gender = '' THEN 1 ELSE 0 END) AS gender_null,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS age_null,
    SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END) AS city_null,
    SUM(CASE WHEN province IS NULL OR province = '' THEN 1 ELSE 0 END) AS province_null,
    SUM(CASE WHEN register_date IS NULL OR register_date = '' THEN 1 ELSE 0 END) AS register_date_null,
    SUM(CASE WHEN member_level IS NULL OR member_level = '' THEN 1 ELSE 0 END) AS member_level_null,
    SUM(CASE WHEN phone IS NULL OR phone = '' THEN 1 ELSE 0 END) AS phone_null,
    SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) AS email_null
FROM ods_user

UNION ALL

SELECT 'ods_product' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_name IS NULL OR product_name = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN sub_category IS NULL OR sub_category = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN brand IS NULL OR brand = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN stock IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN status IS NULL OR status = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END)
FROM ods_product

UNION ALL

SELECT 'ods_store' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN store_id IS NULL OR store_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN store_name IS NULL OR store_name = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN province IS NULL OR province = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN district IS NULL OR district = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN address IS NULL OR address = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN open_date IS NULL OR open_date = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN area IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN manager IS NULL OR manager = '' THEN 1 ELSE 0 END),
    0
FROM ods_store

UNION ALL

SELECT 'ods_order' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN store_id IS NULL OR store_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_date IS NULL OR order_date = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_time IS NULL OR order_time = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN pay_amount IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN discount_amount IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN pay_type IS NULL OR pay_type = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_status IS NULL OR order_status = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN channel IS NULL OR channel = '' THEN 1 ELSE 0 END)
FROM ods_order

UNION ALL

SELECT 'ods_order_item' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN item_id IS NULL OR item_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END),
    0, 0, 0, 0
FROM ods_order_item

UNION ALL

SELECT 'ods_user_behavior' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN behavior_id IS NULL OR behavior_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN behavior_type IS NULL OR behavior_type = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN behavior_time IS NULL OR behavior_time = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN session_id IS NULL OR session_id = '' THEN 1 ELSE 0 END),
    0, 0, 0, 0
FROM ods_user_behavior;
