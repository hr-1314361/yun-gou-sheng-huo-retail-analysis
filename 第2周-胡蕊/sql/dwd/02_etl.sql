-- ============================================================
-- 第2周 子任务6（下）：DWD 层数据加载 ETL
-- 从 ydsh_ods 清洗表（子任务1-3产出）加载到 ydsh_dwd 星型模型
-- 动态分区：dwd_order 按 order_date 自动分区
-- ============================================================

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 2048;
SET hive.exec.max.dynamic.partitions.pernode = 2048;

-- 1. 加载用户维度表
INSERT OVERWRITE TABLE ydsh_dwd.dim_user
SELECT user_id, user_name, gender, age, province, city, region,
       register_date, member_level, phone, email
FROM ydsh_ods.ods_user_clean;

-- 2. 加载商品维度表
INSERT OVERWRITE TABLE ydsh_dwd.dim_product
SELECT product_id, product_name, category, sub_category, brand,
       price, cost, CAST(stock AS INT), status, launch_date
FROM ydsh_ods.ods_product_clean;

-- 3. 加载门店维度表
INSERT OVERWRITE TABLE ydsh_dwd.dim_store
SELECT store_id, store_name, province, city, district, address, region,
       open_date, area, manager
FROM ydsh_ods.ods_store_clean;

-- 4. 生成日期维度表（源自订单日期全集）
INSERT OVERWRITE TABLE ydsh_dwd.dim_date
SELECT DISTINCT
       order_date AS date_key,
       CAST(substr(order_date, 1, 4)  AS INT) AS year,
       CAST(substr(order_date, 6, 2)  AS INT) AS month,
       CAST(substr(order_date, 9, 2)  AS INT) AS day,
       CAST(CEIL(CAST(substr(order_date, 6, 2) AS INT) / 3.0) AS INT) AS quarter,
       CAST(pmod(datediff(order_date, '1900-01-01'), 7) + 1 AS INT) AS weekday
FROM ydsh_ods.ods_order_clean;

-- 5. 加载订单事实表（订单去重后与明细join成明细粒度，动态分区写入）
--    注意：ods_order_clean 继承自原始 ods_order（含600条重复订单），
--    join 前按 order_id 去重（保留最早一条），避免明细行翻倍
INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT o.order_id,
       i.item_id,
       o.user_id,
       o.store_id,
       i.product_id,
       i.quantity,
       i.unit_price,
       i.discount,
       i.quantity * i.unit_price AS amount,
       o.pay_type,
       o.order_status,
       o.channel,
       o.order_date
FROM (SELECT order_id, user_id, store_id, order_date, order_time, pay_type, order_status, channel
      FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) AS rn
            FROM ydsh_ods.ods_order_clean) t
      WHERE rn = 1) o
JOIN ydsh_ods.ods_order_item_clean i
  ON o.order_id = i.order_id;

-- 6. 验证：分区裁剪生效（执行计划应出现 partition pruning）
-- EXPLAIN SELECT COUNT(*) FROM ydsh_dwd.dwd_order WHERE order_date = '2024-06-01';
-- 7. 验证：行数（明细粒度应为 37549）
-- SELECT COUNT(*) FROM ydsh_dwd.dwd_order;
-- SELECT COUNT(DISTINCT order_date) FROM ydsh_dwd.dwd_order;
