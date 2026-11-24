-- ============================================================
-- 第3周 子任务4：NL2SQL 典型问题测试
-- 每条记录：自然语言问题 → 期望生成的 SQL
-- 用于验证大模型生成 SQL 的正确性
-- ============================================================

-- 问题1：广东省上月销售额是多少？
-- 期望SQL：
SELECT ROUND(SUM(d.amount), 2) AS gmv
FROM ydsh_dwd.dwd_order d
JOIN ydsh_dwd.dim_store s ON d.store_id = s.store_id
WHERE s.province = '广东省'
  AND substr(d.order_date, 1, 7) = substr(date_sub(current_date, 30), 1, 7);

-- 问题2：销量最高的前5个品类
-- 期望SQL：
SELECT category, ROUND(SUM(gmv), 2) AS gmv, SUM(order_cnt) AS order_cnt
FROM ydsh_dws.dws_sales_category_1d
GROUP BY category
ORDER BY gmv DESC
LIMIT 5;

-- 问题3：2024年11月的GMV和订单量是多少？
-- 期望SQL：
SELECT ROUND(SUM(gmv), 2) AS gmv, SUM(order_cnt) AS order_cnt
FROM ydsh_dws.dws_sales_1d
WHERE substr(stat_date, 1, 7) = '2024-11';

-- 问题4：全年客单价最高的门店是哪家？
-- 期望SQL：
SELECT s.store_name, ROUND(SUM(d.amount), 2) AS gmv,
       COUNT(DISTINCT d.order_id) AS order_cnt,
       ROUND(SUM(d.amount) / COUNT(DISTINCT d.order_id), 2) AS aov
FROM ydsh_dwd.dwd_order d
JOIN ydsh_dwd.dim_store s ON d.store_id = s.store_id
GROUP BY s.store_name
ORDER BY aov DESC
LIMIT 1;

-- 问题5：APP渠道的GMV占比是多少？
-- 期望SQL：
SELECT channel, ROUND(SUM(gmv), 2) AS gmv,
       ROUND(SUM(gmv) / SUM(SUM(gmv)) OVER (), 4) AS gmv_share
FROM ydsh_dws.dws_sales_channel_1d
GROUP BY channel
ORDER BY gmv DESC;

-- 问题6：2024年Q3的复购率是多少？
-- 期望SQL：
SELECT ROUND(
    SUM(CASE WHEN order_cnt >= 2 THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4
) AS repurchase_rate
FROM (
    SELECT user_id, COUNT(DISTINCT order_id) AS order_cnt
    FROM ydsh_dwd.dwd_order
    WHERE order_date >= '2024-07-01' AND order_date < '2024-10-01'
    GROUP BY user_id
) t;

-- 问题7：哪个品类的用户数最多？
-- 期望SQL：
SELECT category, SUM(user_cnt) AS user_cnt
FROM ydsh_dws.dws_sales_category_1d
GROUP BY category
ORDER BY user_cnt DESC
LIMIT 1;
