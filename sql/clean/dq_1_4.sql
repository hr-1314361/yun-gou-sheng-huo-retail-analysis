USE ydsh_ods;
SELECT 'ods_order' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS order_id_null,
    SUM(CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END) AS user_id_null,
    SUM(CASE WHEN store_id IS NULL OR store_id = '' THEN 1 ELSE 0 END) AS store_id_null,
    SUM(CASE WHEN order_date IS NULL OR order_date = '' THEN 1 ELSE 0 END) AS order_date_null,
    SUM(CASE WHEN order_time IS NULL OR order_time = '' THEN 1 ELSE 0 END) AS order_time_null,
    SUM(CASE WHEN pay_amount IS NULL THEN 1 ELSE 0 END) AS pay_amount_null,
    SUM(CASE WHEN discount_amount IS NULL THEN 1 ELSE 0 END) AS discount_amount_null,
    SUM(CASE WHEN pay_type IS NULL OR pay_type = '' THEN 1 ELSE 0 END) AS pay_type_null,
    SUM(CASE WHEN order_status IS NULL OR order_status = '' THEN 1 ELSE 0 END) AS order_status_null,
    SUM(CASE WHEN channel IS NULL OR channel = '' THEN 1 ELSE 0 END) AS channel_null
FROM ods_order;
