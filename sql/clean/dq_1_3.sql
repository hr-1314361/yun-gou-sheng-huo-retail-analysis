USE ydsh_ods;
SELECT 'ods_store' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN store_id IS NULL OR store_id = '' THEN 1 ELSE 0 END) AS store_id_null,
    SUM(CASE WHEN store_name IS NULL OR store_name = '' THEN 1 ELSE 0 END) AS store_name_null,
    SUM(CASE WHEN province IS NULL OR province = '' THEN 1 ELSE 0 END) AS province_null,
    SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END) AS city_null,
    SUM(CASE WHEN district IS NULL OR district = '' THEN 1 ELSE 0 END) AS district_null,
    SUM(CASE WHEN address IS NULL OR address = '' THEN 1 ELSE 0 END) AS address_null,
    SUM(CASE WHEN open_date IS NULL OR open_date = '' THEN 1 ELSE 0 END) AS open_date_null,
    SUM(CASE WHEN area IS NULL THEN 1 ELSE 0 END) AS area_null,
    SUM(CASE WHEN manager IS NULL OR manager = '' THEN 1 ELSE 0 END) AS manager_null
FROM ods_store;
