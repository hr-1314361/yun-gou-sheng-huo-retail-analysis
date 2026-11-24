-- ============================================================
-- 优化场景 1：分区裁剪（Partition Pruning）
-- 表：ydsh_dwd.dwd_order，分区列 order_date（yyyy-MM-dd，365 个分区）
-- 目标：只扫描 2024-11 的 30 个分区，而不是全年 365 个分区
-- ============================================================

-- ❌ 优化前：对分区列使用函数，分区裁剪失效，全表 365 个分区被扫描
EXPLAIN
SELECT
    COUNT(*)        AS order_cnt,
    SUM(amount)     AS gmv
FROM ydsh_dwd.dwd_order
WHERE substr(order_date, 1, 7) = '2024-11';

-- ✅ 优化后：直接对分区列做范围过滤，触发分区裁剪
EXPLAIN
SELECT
    COUNT(*)        AS order_cnt,
    SUM(amount)     AS gmv
FROM ydsh_dwd.dwd_order
WHERE order_date >= '2024-11-01'
  AND order_date <= '2024-11-30';

-- 查看实际扫描的分区数量（Hive 4 支持）
EXPLAIN FORMATTED
SELECT COUNT(*) FROM ydsh_dwd.dwd_order
WHERE order_date BETWEEN '2024-11-01' AND '2024-11-30';

-- 关闭分区裁剪做对照实验（仅用于验证，不要在线上关闭）
SET hive.optimize.pruner = false;
SELECT COUNT(*) FROM ydsh_dwd.dwd_order
WHERE order_date BETWEEN '2024-11-01' AND '2024-11-30';
SET hive.optimize.pruner = true;
