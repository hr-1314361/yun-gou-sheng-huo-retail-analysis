SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=100;
SET hive.exec.max.dynamic.partitions.pernode=100;
INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-01-01' AND o.order_date < '2024-02-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-02-01' AND o.order_date < '2024-03-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-03-01' AND o.order_date < '2024-04-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-04-01' AND o.order_date < '2024-05-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-05-01' AND o.order_date < '2024-06-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-06-01' AND o.order_date < '2024-07-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-07-01' AND o.order_date < '2024-08-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-08-01' AND o.order_date < '2024-09-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-09-01' AND o.order_date < '2024-10-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-10-01' AND o.order_date < '2024-11-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-11-01' AND o.order_date < '2024-12-01';

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id, i.item_id, o.user_id, o.store_id, i.product_id,
       i.quantity, i.unit_price, i.discount, i.quantity * i.unit_price AS amount,
       o.pay_type, o.order_status, o.channel, o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
      FROM ydsh_ods.ods_order_clean) o
JOIN ydsh_ods.ods_order_item_clean i ON o.order_id = i.order_id
WHERE o.rn = 1
  AND o.order_date >= '2024-12-01' AND o.order_date < '2025-01-01';
