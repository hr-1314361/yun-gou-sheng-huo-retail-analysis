USE ydsh_ods;
TRUNCATE TABLE ods_user;
TRUNCATE TABLE ods_product;
TRUNCATE TABLE ods_store;
TRUNCATE TABLE ods_order;
TRUNCATE TABLE ods_order_item;
TRUNCATE TABLE ods_user_behavior;

LOAD DATA LOCAL INPATH '/data/ods_user.csv' INTO TABLE ods_user;
LOAD DATA LOCAL INPATH '/data/ods_product.csv' INTO TABLE ods_product;
LOAD DATA LOCAL INPATH '/data/ods_store.csv' INTO TABLE ods_store;
LOAD DATA LOCAL INPATH '/data/ods_order.csv' INTO TABLE ods_order;
LOAD DATA LOCAL INPATH '/data/ods_order_item.csv' INTO TABLE ods_order_item;
LOAD DATA LOCAL INPATH '/data/ods_user_behavior.csv' INTO TABLE ods_user_behavior;

SELECT 'ods_user' AS tbl, COUNT(*) AS cnt FROM ods_user
UNION ALL SELECT 'ods_product', COUNT(*) FROM ods_product
UNION ALL SELECT 'ods_store', COUNT(*) FROM ods_store
UNION ALL SELECT 'ods_order', COUNT(*) FROM ods_order
UNION ALL SELECT 'ods_order_item', COUNT(*) FROM ods_order_item
UNION ALL SELECT 'ods_user_behavior', COUNT(*) FROM ods_user_behavior;
