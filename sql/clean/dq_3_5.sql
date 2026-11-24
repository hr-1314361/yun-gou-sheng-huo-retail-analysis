USE ydsh_ods;
SELECT 'behavior_user_consistency' AS check_name,
    COUNT(*) AS orphan_count
FROM ods_user_behavior b
LEFT JOIN ods_user u ON b.user_id = u.user_id
WHERE u.user_id IS NULL;
