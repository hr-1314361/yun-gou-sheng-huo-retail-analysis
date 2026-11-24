USE ydsh_ods;
SELECT 'ods_product' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS product_id_null,
    SUM(CASE WHEN product_name IS NULL OR product_name = '' THEN 1 ELSE 0 END) AS product_name_null,
    SUM(CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END) AS category_null,
    SUM(CASE WHEN sub_category IS NULL OR sub_category = '' THEN 1 ELSE 0 END) AS sub_category_null,
    SUM(CASE WHEN brand IS NULL OR brand = '' THEN 1 ELSE 0 END) AS brand_null,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price_null,
    SUM(CASE WHEN cost IS NULL THEN 1 ELSE 0 END) AS cost_null,
    SUM(CASE WHEN stock IS NULL THEN 1 ELSE 0 END) AS stock_null,
    SUM(CASE WHEN status IS NULL OR status = '' THEN 1 ELSE 0 END) AS status_null,
    SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END) AS launch_date_null
FROM ods_product;
