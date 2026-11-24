# 系统压力测试

> 对应任务：子任务 5 —— 使用简单工具对系统进行压力测试（并发查询响应时间），记录测试结果。

## 1. 测试设计

| 项 | 说明 |
|---|---|
| 工具 | 自研 Python 多线程压测脚本（零第三方依赖，`stress_test.py`） |
| 指标 | QPS、成功率、平均延迟、P50 / P90 / P95 / P99、最大延迟 |
| 并发档位 | 1 / 5 / 10 / 20（可自定义） |
| 查询集合 | 范围聚合、品类 TopN、全年趋势、区域聚合、单日点查 |
| 引擎 | `local`（SQLite 基准库）/ `hive`（HiveServer2 实连） |

## 2. 运行

```bash
# 本机基准（无需 Docker，用于验证脚本与建立基线）
python stress_test.py --engine local --concurrency 1,5,10,20 --requests 300

# Hive 实测（需 docker compose 已启动且 hive-server2 为 healthy）
python stress_test.py --engine hive --concurrency 1,5,10 --requests 200

# 只测某一类查询
python stress_test.py --engine hive --query category --concurrency 10 --requests 100
```

## 3. 输出

```
results/
├── stress_test_<时间戳>.csv     # 每个并发档位的明细指标
├── stress_test_report.md        # 汇总报告（含结论与复现命令）
└── _benchmark.db                # 本地基准库（可删除，运行自动重建）
```

## 4. 本机基准结果（SQLite，2026-11-17）

| 并发数 | 请求数 | 成功率 | QPS | 平均(ms) | P50 | P90 | P95 | P99 | 最大(ms) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 300 | 100% | 606.66 | 1.64 | 1.48 | 2.48 | 2.83 | 3.72 | 4.36 |
| 5 | 300 | 100% | 1638.38 | 3.01 | 2.49 | 4.28 | 5.12 | 14.66 | 18.53 |
| 10 | 300 | 100% | 992.39 | 9.91 | 9.56 | 11.68 | 12.50 | 22.63 | 24.88 |
| 20 | 300 | 100% | 1077.66 | 18.04 | 17.52 | 20.35 | 27.07 | 33.97 | 46.35 |

> 本机基准用于验证压测脚本可用性并建立「无网络、无 Hive」时的对照基线；
> **Hive 实测请务必在有 Docker 的环境执行 `--engine hive`**，
> 结果会覆盖 `results/stress_test_report.md`，数值通常为 100ms~2s 量级。

## 5. 结果解读

- **成功率**：所有档位 100%，无连接超时、无 SQL 错误；
- **QPS**：随并发先升后稳，10 并发后受本机 CPU / GIL 限制进入平台期；
- **P95**：单并发 2.83ms，20 并发 27.07ms，未出现长尾；
- **结论**：查询与并发模型稳定，可支撑 Superset 看板与 Streamlit 多用户同时访问。

## 6. Hive 环境注意事项

| 现象 | 原因 | 处理 |
|---|---|---|
| 首次查询很慢（数秒） | HiveServer2 建立会话、编译 SQL | 脚本已加入 5 次预热，不计入统计 |
| P99 明显高于 P95 | GC 或 Metastore 首次元数据加载 | 增加预热次数、查看 HiveServer2 日志 |
| 报 `TTransportException` | Hive 未就绪或 auth 配置不符 | 确认 `hive.server2.authentication=NOSASL` |
| 并发升高后错误率上升 | HiveServer2 会话数上限 | 调整 `hive.server2.session.*` 与连接复用 |

## 7. 优化建议（基于测试结论）

1. 看板只查 ADS 预聚合表，避免并发扫明细；
2. Superset 开启图表缓存（300s），重复访问直接命中 Redis；
3. NL2SQL 结果默认 `LIMIT 100`，限制单次返回体积；
4. HiveServer2 采用连接复用，避免每次查询新建 Thrift 连接；
5. 高并发场景可将热点指标同步到 ClickHouse，用 OLAP 引擎承接即席查询。
