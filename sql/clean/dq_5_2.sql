USE ydsh_ods;
SELECT 'open_date_range' AS check_name, MIN(open_date) AS min_date, MAX(open_date) AS max_date, COUNT(*) AS total_count FROM ods_store
UNION ALL
SELECT 'behavior_time_range', MIN(behavior_time), MAX(behavior_time), COUNT(*) FROM ods_user_behavior;
