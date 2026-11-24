# Hive 查询优化报告

> 对应任务：子任务 5 —— 分区裁剪、避免数据倾斜、合理使用分桶
> 配套 SQL：`docs/hive_optimization/01_partition_pruning.sql`、`02_data_skew.sql`、`03_bucket_join.sql`
> 复现脚本：`stress_test/stress_test.py --engine hive`

## 一、测试对象与环境

| 项 | 说明 |
|---|---|
| 数仓 | `ydsh_ods / ydsh_dwd / ydsh_dws / ydsh_ads`（第 1~3 周构建） |
| 事实表 | `ydsh_dwd.dwd_order`：15,000 单，按 `order_date` 分区，365 个分区 |
| 维度表 | `dim_user` / `dim_product` / `dim_store` / `dim_date` |
| 引擎 | Apache Hive 4.0.0（Docker，单机，MySQL Metastore） |
| 客户端 | Beeline / PyHive（NOSASL，端口 10000） |

优化方法：**EXPLAIN 执行计划分析 + 同条件计时对比**，每组查询重复 3 次取中位数。

---

## 二、优化点 1：分区裁剪

### 问题

```sql
-- ❌ 对分区列使用函数，分区裁剪失效
SELECT COUNT(*), SUM(amount) FROM ydsh_dwd.dwd_order
WHERE substr(order_date, 1, 7) = '2024-11';
```

Hive 的分区裁剪依赖对分区列的**直接常量比较**。`substr(order_date,1,7)` 使优化器无法在编译期推导分区范围，
执行计划退化为扫描全部 365 个分区。

### 优化

```sql
-- ✅ 直接对分区列做范围过滤
SELECT COUNT(*), SUM(amount) FROM ydsh_dwd.dwd_order
WHERE order_date >= '2024-11-01' AND order_date <= '2024-11-30';
```

### 效果（结构指标）

| 指标 | 优化前 | 优化后 | 变化 |
|---|---|---|---|
| 扫描分区数 | 365 | 30 | **-91.8%** |
| 扫描行数（按日均 41 单估算） | 15,000 | ≈1,230 | **-91.8%** |
| 执行计划 `PartitionCount` | 365 | 30 | 可在 `EXPLAIN FORMATTED` 中核对 |
| I/O 与 CPU | 全量 | 仅 11 月 | 线性下降 |

### 落地情况

- `sql/dws/02_etl.sql`、`sql/ads/02_etl.sql` 的增量刷新均使用 `WHERE dt = '${bizdate}'` 形式，
  保证每日 ETL 只扫当天分区；
- Superset 仪表板默认时间筛选 2024 全年，并按月聚合，命中分区裁剪；
- Streamlit NL2SQL 的 Prompt 明确要求「按月筛选使用 `substr(stat_date,1,7)`」——
  该字段是 ADS 非分区表的普通列，不影响裁剪；查明细时才提示按 `order_date` 范围过滤。

---

## 三、优化点 2：数据倾斜

### 问题

门店维度分布不均：`S0001`（旗舰店）订单量约占全量 30%。
按 `store_id` 聚合时，30% 的数据落到同一个 Reduce 任务，形成长尾。

### 优化 A：开启倾斜负载均衡（首选）

```sql
SET hive.groupby.skewindata = true;
```

Hive 会生成两个 MR 作业：第一个作业按随机 key 打散做部分聚合，第二个作业按真实 key 汇总，
以多一轮 Shuffle 换取 Reduce 负载均衡。

### 优化 B：热点 key 加盐（Map 端聚合无法消除时）

```sql
WITH salted AS (
    SELECT store_id,
           CONCAT(store_id, '_', CAST(FLOOR(RAND() * 10) AS INT)) AS salt_key,
           amount
    FROM ydsh_dwd.dwd_order
),
stage1 AS (
    SELECT store_id, salt_key, COUNT(*) AS part_cnt, SUM(amount) AS part_gmv
    FROM salted GROUP BY store_id, salt_key
)
SELECT store_id, SUM(part_cnt) AS order_cnt, SUM(part_gmv) AS gmv
FROM stage1 GROUP BY store_id;
```

### 效果（结构指标）

| 指标 | 优化前 | 优化后 |
|---|---|---|
| 最大 Reduce 输入占比 | ≈30%（热点单 key） | ≈3%（10 份盐打散） |
| Reduce 任务耗时离散度 | 高（长尾明显） | 显著收敛 |
| 代价 | — | 多一次聚合 / 一轮 Shuffle |

---

## 四、优化点 3：分桶 + Map Join

### 问题

`dwd_order`（事实表，持续增长）JOIN `dim_product`（约 500 行小表）时，
默认 Common Join 需要把**事实表全量参与 Shuffle**，网络与磁盘开销大。

### 优化

1. 维度表与事实表均按 `product_id` 分桶（16 桶，见 `03_bucket_join.sql`）；
2. 开启 Map Join，把小表广播到每个 Map 任务，Reduce 端零 Shuffle：

```sql
SET hive.auto.convert.join = true;
SET hive.auto.convert.join.noconditionaltask.size = 20971520; -- 20MB
SET hive.optimize.bucketmapjoin = true;

SELECT /*+ MAPJOIN(p) */ p.category, SUM(o.amount) AS gmv
FROM ydsh_dwd.dwd_order_bucket o
JOIN ydsh_dwd.dim_product_bucket p ON o.product_id = p.product_id
WHERE o.order_date BETWEEN '2024-11-01' AND '2024-11-30'
GROUP BY p.category;
```

### 效果（结构指标）

| 指标 | 普通 Join | 分桶 + Map Join |
|---|---|---|
| Shuffle 数据量 | 事实表全量（≈15,000 行 × 列数） | **0**（仅广播小表） |
| Reduce 阶段 | 有 | 无（Map 端完成关联） |
| 适用条件 | 任意 | 小表可放入内存（<20MB），两表同键同桶数 |

### 附加优化

- **列裁剪**：禁止 `SELECT *`，只取参与计算与输出的列，Parquet 按列读取；
- **谓词下推**：`hive.optimize.ppd=true`（默认开启），过滤条件下推到扫描阶段；
- **小文件合并**：`hive.merge.mapfiles/mapredfiles=true`，`merge.size.per.task=128MB`，
  避免 ADS 层产生大量 KB 级文件拖慢后续查询；
- **存储格式**：全层使用 Parquet，列式压缩，扫描量较 TextFile 下降明显。

---

## 五、实测复现方法

在 Docker 环境启动后执行：

```powershell
cd 第4周-胡蕊\stress_test

# 压测 + 记录（自动生成 results/stress_test_report.md 与 csv）
python stress_test.py --engine hive --concurrency 1,5,10,20 --requests 200

# 对比某一 SQL 优化前后的执行耗时
python stress_test.py --engine hive --concurrency 10 --requests 100 --query partition
```

生成的报告包含：总请求数、成功率、QPS、平均/P50/P90/P95/P99 延迟，
可直接作为《部署手册》附录与答辩材料。

> 说明：本文中的「结构指标」（扫描分区数、Shuffle 次数、最大 Reduce 占比）
> 由执行计划与数据分布决定，可在任意环境复现；
> 具体毫秒级耗时与机器配置、数据量强相关，请以本地脚本输出为准，不要照抄。

---

## 六、优化措施在项目中的体现

| 层 | 措施 | 位置 |
|---|---|---|
| DWD | 按 `order_date` 分区，按 `product_id` 分桶 | `docs/hive_optimization/03_bucket_join.sql` |
| DWS | 按天增量刷新，仅扫当天分区 | `第3周-胡蕊/sql/dws/02_etl.sql` |
| ADS | 预聚合结果表，看板不扫明细 | `第3周-胡蕊/sql/ads/02_etl.sql` |
| Superset | Dataset 只查 ADS；`ROW_LIMIT=10000`；图表缓存 300s | `superset/superset_config.py` |
| Streamlit | SQL 仅 SELECT + 默认 `LIMIT 100` | `streamlit/nl2sql_engine.py` |
| 大屏 | 静态 JSON / 预聚合接口，不实时扫 Hive | `echarts/api_server.py` |

---

## 七、结论

1. **分区裁剪是收益最高的优化**：把 365 个分区降到 30 个，I/O 与扫描行数下降约 92%，
   且不改业务语义，应作为开发规范强制执行（禁止对分区列套函数）；
2. **数据倾斜优先用 `skewindata`**，加盐方案作为兜底，避免过度设计；
3. **小表 JOIN 一律走 Map Join**，分桶保证桶内关联，消除 Reduce 端 Shuffle；
4. **看板只查 ADS 预聚合结果**，是保障交互体验的关键架构决策；
5. 优化效果必须用 `EXPLAIN` + 计时双重验证，避免「看起来优化了」。
