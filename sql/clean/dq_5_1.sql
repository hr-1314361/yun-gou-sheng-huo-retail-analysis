USE ydsh_ods;
SELECT 'order_date_range' AS check_name, MIN(order_date) AS min_date, MAX(order_date) AS max_date, COUNT(*) AS total_count FROM ods_order
UNION ALL
SELECT 'register_date_range', MIN(register_date), MAX(register_date), COUNT(*) FROM ods_user
UNION ALL
SELECT 'launch_date_range', MIN(launch_date), MAX(launch_date), COUNT(*) FROM ods_product;
