USE ydsh_ods;
SELECT 'ods_user_behavior' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN behavior_id IS NULL OR behavior_id = '' THEN 1 ELSE 0 END) AS behavior_id_null,
    SUM(CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END) AS user_id_null,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS product_id_null,
    SUM(CASE WHEN behavior_type IS NULL OR behavior_type = '' THEN 1 ELSE 0 END) AS behavior_type_null,
    SUM(CASE WHEN behavior_time IS NULL OR behavior_time = '' THEN 1 ELSE 0 END) AS behavior_time_null,
    SUM(CASE WHEN session_id IS NULL OR session_id = '' THEN 1 ELSE 0 END) AS session_id_null
FROM ods_user_behavior;
