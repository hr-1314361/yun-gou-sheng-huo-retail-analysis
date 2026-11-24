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
FROM ods_user;
