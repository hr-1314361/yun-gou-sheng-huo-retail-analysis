# 团队名_第1周_AI协同日志

## 一、使用的工具/模型

| 工具/模型 | 用途 |
|-----------|------|
| TraeCode（AI 编程助手） | 代码生成、SQL 编写、问题排查 |
| Docker Desktop | 容器化运行 MySQL + Hive |
| Apache Hive 4.0.0 | 数据仓库 ODS 层建表与查询 |
| MySQL 8.0 | Hive Metastore 元数据库 |
| Python 3.x | xlsx 评估报告生成 |
| PowerShell | 命令行操作、Docker 管理 |

## 二、协同记录表

| 序号 | 时间 | 任务内容 | AI 协助内容 | 结果 |
|------|------|----------|-------------|------|
| 1 | 2026-10-27 08:30 | Docker 环境搭建 | 编写 docker-compose.yml，解决端口 3306 冲突 | 成功启动 3 个容器 |
| 2 | 2026-10-27 09:00 | ODS 层建表 | 根据真实 CSV 结构生成 6 张表的 CREATE TABLE 语句 | 建表成功，行数与数据字典一致 |
| 3 | 2026-10-27 09:15 | 数据导入 | 编写 LOAD DATA 脚本，导入 6 个 CSV 并校验行数 | user 1000, product 600, store 60, order 15600, order_item 37549, behavior 60000 |
| 4 | 2026-10-27 09:30 | 数据质量评估 | 编写五维度评估 SQL（完整性/唯一性/有效性/一致性/准确性） | 发现600条重复订单、负金额、异常取值等问题 |
| 5 | 2026-10-27 10:00 | 缺失值处理 | 编写缺失值清洗 SQL：age 均值填充、email 保留空值标记 unknown@、launch_date 补全 2024-01-01 | 输出 DWD 目标表 dwd_user、dwd_product |
| 6 | 2026-10-27 10:15 | 重复值去重 | 编写 ROW_NUMBER 窗口函数去重 SQL（PARTITION BY order_id ORDER BY order_date, order_time） | ods_order 15600→dwd_order 15000，行数差异已统计 |
| 7 | 2026-10-27 10:30 | 交付物整理 | 生成 README.md、环境搭建笔记、.gitignore、xlsx 评估表、AI 协同日志，并打包 | 全部完成 |

## 三、产出成果清单

| 序号 | 交付物 | 文件路径 | 状态 |
|------|--------|----------|------|
| 1 | README.md | `README.md` | 已完成 |
| 2 | 环境搭建笔记 | `环境搭建笔记.md` | 已完成 |
| 3 | .gitignore | `.gitignore` | 已完成 |
| 4 | ODS 建表脚本 | `sql/ods/create_ods.sql` | 已完成 |
| 5 | 数据加载脚本 | `sql/ods/load_ods.sql` | 已完成 |
| 6 | 数据质量预评估表 | `数据质量预评估表.xlsx` | 已完成 |
| 7 | 缺失值清洗脚本（输出 dwd_user/dwd_product） | `sql/clean/step8_missing_values.sql` | 已完成 |
| 8 | 重复值去重脚本（输出 dwd_order/dwd_order_item） | `sql/clean/step9_dedup.sql` | 已完成 |
| 9 | AI 协同日志 | `AI协同日志.md` | 已完成 |

- 由 AI 生成的内容（代码 / SQL / 文案 / 图表）：docker-compose.yml 配置文件、6张ODS表建表SQL、数据加载SQL、五维度数据质量评估SQL（完整性/唯一性/有效性/一致性/准确性）、缺失值处理SQL（age均值填充、email标记、launch_date补全）、去重SQL（ROW_NUMBER窗口函数）、数据质量预评估表.xlsx、README.md、环境搭建笔记.md、AI协同日志.md、打包脚本
- 由人工编写的内容：提供真实CSV数据文件（模拟数据目录下6个CSV）、确认数据表结构、指定Docker Desktop路径、提供模拟数据目录路径、确认提交清单与作业要求
- 人机协作完成的内容：端口冲突排查与解决（AI定位原因，人工确认修改方案）、Tez计数器超限问题（AI拆分SQL，人工验证结果）、数据翻倍问题（AI发现并修复，人工确认最终行数）、交付物打包（AI生成脚本，人工确认文件完整性）

---

## 四、问题与解决

- 遇到的问题：
  1. Docker MySQL 端口 3306 被本地 MySQL80 服务占用，容器无法启动
  2. Hive 五维度评估 SQL 使用多个 UNION ALL 时触发 Tez 计数器超限（121 max=120）
  3. docker cp 目录复制未覆盖容器内旧 CSV 文件，导致 Hive 查询结果字段错位
  4. LOAD DATA 前未 TRUNCATE 表，导致数据行数翻倍（如 ods_order 31200 行，应为 15600）
  5. 日期格式混用（`-` 和 `/` 两种格式），影响字符串比较与排序

- AI 是否有效解决：是，所有问题均由 AI 定位原因并给出解决方案

- 最终如何解决：
  1. 将 docker-compose.yml 中 MySQL 端口映射改为 `3307:3306`，容器内部通信不受影响
  2. 将大查询拆分为多个独立 SQL 文件（dq_1_1~dq_1_6、dq_4_1~dq_4_2 等）分别执行
  3. 逐个文件手动 docker cp 覆盖，然后 TRUNCATE TABLE 重新 LOAD DATA
  4. 先 TRUNCATE 6张表再重新 LOAD DATA，校验行数为 1000/600/60/15600/37549/60000
  5. 在评估表中如实记录日期格式混用情况，标注需在 DWD 层统一处理

---

## 五、反思与总结

- AI 协同带来的价值：
  1. 大幅提升效率：SQL 编写、环境配置、问题排查均由 AI 快速完成，原本需要数天的工作量在数小时内完成
  2. 降低学习成本：对 Hive 4.0.0、Docker Compose 等不熟悉的工具，AI 提供了准确的操作指导
  3. 减少错误：AI 在数据翻倍、字段错位等问题上主动发现并修复，避免了交付错误数据

- AI 的局限与风险（准确性 / 合规性 / 依赖）：
  1. 准确性风险：AI 生成的 SQL 在未实际执行前无法保证正确性（如 UNION ALL 列数不对齐、Hive 不支持标量子查询等）
  2. 依赖风险：过度依赖 AI 可能导致对底层原理理解不足，遇到 AI 无法解决的问题时难以独立排查
  3. 合规性风险：AI 生成的代码需要人工审查，特别是涉及生产环境的数据操作（如 TRUNCATE、INSERT OVERWRITE）

- 本次协作中我的能力提升：
  1. 掌握了 Docker Compose 编排多容器服务的方法
  2. 熟悉了 Hive 4.0.0 的建表语法、数据加载方式和 Tez 引擎特性
  3. 理解了数据质量五维度评估（完整性/唯一性/有效性/一致性/准确性）的完整流程
  4. 学会了用 ROW_NUMBER 窗口函数进行去重、用 COALESCE 制定缺失值填充策略
  5. 提升了通过 AI 工具高效完成大数据实训任务的能力

- 对 AI 协同的改进建议：
  1. 建议在后续周次中继续使用 AI 辅助完成 DWD/DWS/ADS 层建模和 Superset 可视化
  2. 对于复杂 SQL，建议 AI 先生成小样本测试版本，验证后再全量执行
  3. 建议在关键操作（如 TRUNCATE、DROP）前增加人工确认环节，避免误操作
