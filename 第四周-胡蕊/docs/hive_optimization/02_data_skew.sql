-- ============================================================
-- 优化场景 2：数据倾斜（Data Skew）
-- 场景：头部门店（store_id = S0001）订单量占全量约 30%，
--       GROUP BY store_id 时该 Reduce 任务成为长尾
-- ============================================================

-- ❌ 优化前：直接按 store_id 聚合，热点 key 全部落到同一个 Reduce
EXPLAIN
SELECT
    store_id,
    COUNT(*)        AS order_cnt,
    SUM(amount)     AS gmv
FROM ydsh_dwd.dwd_order
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY store_id;

-- ✅ 方案 A：开启 Hive 倾斜负载均衡（两阶段聚合，优先使用）
SET hive.groupby.skewindata = true;
EXPLAIN
SELECT
    store_id,
    COUNT(*)        AS order_cnt,
    SUM(amount)     AS gmv
FROM ydsh_dwd.dwd_order
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY store_id;

-- ✅ 方案 B：热点 key 加随机盐，打散到多个 Reduce 后再汇总
--    适用于 Map 端聚合无法完全消除倾斜的场景
WITH salted AS (
    SELECT
        store_id,
        CONCAT(store_id, '_', CAST(FLOOR(RAND() * 10) AS INT)) AS salt_key,
        amount
    FROM ydsh_dwd.dwd_order
    WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
),
stage1 AS (
    SELECT
        store_id,
        salt_key,
        COUNT(*)    AS part_cnt,
        SUM(amount) AS part_gmv
    FROM salted
    GROUP BY store_id, salt_key
)
SELECT
    store_id,
    SUM(part_cnt) AS order_cnt,
    SUM(part_gmv) AS gmv
FROM stage1
GROUP BY store_id
ORDER BY gmv DESC;

-- 观察 Reduce 任务耗时分布，确认长尾是否消除
-- 在 YARN / HiveServer2 日志中对比各 Reduce 的 Duration
