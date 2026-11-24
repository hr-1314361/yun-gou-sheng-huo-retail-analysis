-- ============================================================
-- 第2周 子任务7：探索性数据分析（基于 DWD 层）
-- 输出：核心KPI、品类/区域/门店分布、用户累计消费窗口分析
-- 注意：各查询独立执行（避免Tez计数器超限）
-- ============================================================

USE ydsh_dwd;
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

-- 1. 核心KPI：总订单量、GMV、客单价
SELECT COUNT(DISTINCT order_id)                                    AS order_cnt,
       ROUND(SUM(amount), 2)                                       AS gmv,
       ROUND(SUM(amount) / COUNT(DISTINCT user_id), 2)             AS avg_per_user
FROM dwd_order;

-- 2. 月度GMV趋势
SELECT substr(order_date, 1, 7) AS month,
       COUNT(DISTINCT order_id) AS order_cnt,
       ROUND(SUM(amount), 2)    AS gmv
FROM dwd_order
GROUP BY substr(order_date, 1, 7)
ORDER BY month;

-- 3. 品类分布（关联商品维度表）
SELECT p.category,
       COUNT(DISTINCT d.order_id) AS order_cnt,
       ROUND(SUM(d.amount), 2)    AS gmv
FROM dwd_order d
JOIN dim_product p ON d.product_id = p.product_id
GROUP BY p.category
ORDER BY gmv DESC;

-- 4. 区域分布（关联门店维度表）
SELECT s.province,
       COUNT(DISTINCT d.order_id) AS order_cnt,
       ROUND(SUM(d.amount), 2)    AS gmv
FROM dwd_order d
JOIN dim_store s ON d.store_id = s.store_id
GROUP BY s.province
ORDER BY gmv DESC
LIMIT 10;

-- 5. 门店销售TOP10
SELECT s.store_name,
       COUNT(DISTINCT d.order_id) AS order_cnt,
       ROUND(SUM(d.amount), 2)    AS gmv
FROM dwd_order d
JOIN dim_store s ON d.store_id = s.store_id
GROUP BY s.store_name
ORDER BY gmv DESC
LIMIT 10;

-- 6. 订单状态分布
SELECT order_status, COUNT(DISTINCT order_id) AS order_cnt
FROM dwd_order
GROUP BY order_status
ORDER BY order_cnt DESC;

-- 7. 支付方式分布
SELECT pay_type, COUNT(DISTINCT order_id) AS order_cnt
FROM dwd_order
GROUP BY pay_type
ORDER BY order_cnt DESC;

-- 8. 用户累计消费（窗口函数，采样前20）
SELECT user_id, order_date, ROUND(amount, 2) AS amount,
       ROUND(SUM(amount) OVER (PARTITION BY user_id ORDER BY order_date), 2) AS cum_amount
FROM dwd_order
LIMIT 20;

-- 9. 用户消费TOP10（累计消费排名）
SELECT user_id, ROUND(SUM(amount), 2) AS total_amount
FROM dwd_order
GROUP BY user_id
ORDER BY total_amount DESC
LIMIT 10;

-- 10. 行为漏斗（浏览→加购/收藏→购买）
SELECT behavior_type, COUNT(*) AS cnt, COUNT(DISTINCT user_id) AS user_cnt
FROM ydsh_ods.ods_user_behavior_clean
GROUP BY behavior_type;
