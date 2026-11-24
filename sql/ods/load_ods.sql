USE ydsh_ods;

-- 加载用户数据
LOAD DATA LOCAL INPATH '/data/ods_user.csv' INTO TABLE ods_user;

-- 加载商品数据
LOAD DATA LOCAL INPATH '/data/ods_product.csv' INTO TABLE ods_product;

-- 加载门店数据
LOAD DATA LOCAL INPATH '/data/ods_store.csv' INTO TABLE ods_store;

-- 加载订单数据
LOAD DATA LOCAL INPATH '/data/ods_order.csv' INTO TABLE ods_order;

-- 加载订单明细数据
LOAD DATA LOCAL INPATH '/data/ods_order_item.csv' INTO TABLE ods_order_item;

-- 加载用户行为数据
LOAD DATA LOCAL INPATH '/data/ods_user_behavior.csv' INTO TABLE ods_user_behavior;
