USE ydsh_ods;
SELECT 'age_range' AS check_name, COUNT(*) AS invalid_count FROM ods_user WHERE age < 0 OR age > 150
UNION ALL
SELECT 'negative_price', COUNT(*) FROM ods_product WHERE price < 0
UNION ALL
SELECT 'negative_cost', COUNT(*) FROM ods_product WHERE cost < 0
UNION ALL
SELECT 'negative_pay_amount', COUNT(*) FROM ods_order WHERE pay_amount < 0;
