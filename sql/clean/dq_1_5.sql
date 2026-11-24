USE ydsh_ods;
SELECT 'ods_order_item' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN item_id IS NULL OR item_id = '' THEN 1 ELSE 0 END) AS item_id_null,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS order_id_null,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS product_id_null,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS quantity_null,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS unit_price_null,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS discount_null
FROM ods_order_item;
