# 第2周_AI协同日志

## 一、使用的工具/模型

| 工具/模型 | 用途 |
|-----------|------|
| TraeCode（AI 编程助手） | 清洗 SQL 生成、数仓建模、问题排查、文档撰写 |
| Docker Desktop | 容器化运行 MySQL + Hive |
| Apache Hive 4.0.0（Tez 引擎） | 数据清洗、DWD 建模、探索性分析 |
| MySQL 8.0 | Hive Metastore 元数据库 |
| Python | 分月批量 SQL 生成、docx 交付文档生成 |
| PowerShell | 命令行操作、Docker 管理 |

## 二、协同记录表

| 序号 | 时间 | 任务内容 | AI 协助内容 | 结果 |
|------|------|----------|-------------|------|
| 1 | 2026-11-01 14:00 | 脏数据画像探查 | 生成探查 SQL，逐字段统计各枚举列的非规范取值分布 | 摸清 6 张表脏值全貌：gender 414、order_status 1375、behavior_type 57551 等 |
| 2 | 2026-11-01 15:00 | 枚举标准化 | 编写 01_enum_standardize.sql，CASE WHEN 将英文编码/大小写混写/数字代号统一为标准中文枚举 | 6 张 *_clean 清洗表建成，枚举全部收敛 |
| 3 | 2026-11-01 16:00 | 异常值与格式标准化 | 编写 02_abnormal_format.sql：负值 ABS、超大金额置 NULL、regexp_replace 统一日期/手机号、age 均值填充 | 修复后回查脏数据全部归零，age 均值 40.9 |
| 4 | 2026-11-01 17:00 | 字段拆分合并与编码映射 | 编写 03_split_merge_codedim.sql：concat 生成 region、创建 dim_pay_type/dim_member_level 编码维表 | 编码映射回查残留 0 条 |
| 5 | 2026-11-01 19:00 | DWD 层维度建模 | 设计星型模型并生成 01_ddl.sql（4 维度表 + 分区事实表）+ 02_etl.sql | dim 表全部加载成功，dwd_order 366 分区 |
| 6 | 2026-11-01 20:00 | 动态分区报错排查 | 定位 [Error 20004] 与 Derby MoveTask savepoint 回滚问题，设计按月分批加载方案并用 Python 生成 batch_load.sql | 366 分区全部加载成功 |
| 7 | 2026-11-02 09:00 | 事实表行数修复 | 发现 39017 > 37549，定位为 600 条重复订单 join 膨胀，改用 ROW_NUMBER 去重后重新分月加载 | 行数 37549、15000 订单、无重复 |
| 8 | 2026-11-02 10:00 | 探索性数据分析 | 编写 03_analysis.sql 十条分析查询（KPI/趋势/分布/窗口/漏斗）；发现品类尾部空格导致分组分裂并补清洗 | 8 品类正确分组，GMV 6.61 亿元等 KPI 全部产出 |

## 三、产出成果清单

| 序号 | 交付物 | 文件路径 | 状态 |
|------|--------|----------|------|
| 1 | 枚举标准化脚本 | `sql/clean/01_enum_standardize.sql` | 已完成 |
| 2 | 异常值与格式标准化脚本 | `sql/clean/02_abnormal_format.sql` | 已完成 |
| 3 | 字段拆分合并与编码映射脚本 | `sql/clean/03_split_merge_codedim.sql` | 已完成 |
| 4 | 数据质量对比报告 | `数据质量对比报告.docx` | 已完成 |
| 5 | 数仓架构设计文档 | `数仓架构设计文档.docx` | 已完成 |
| 6 | DWD 建表脚本 | `sql/dwd/01_ddl.sql` | 已完成 |
| 7 | DWD ETL 脚本（含分月批量 batch_load.sql） | `sql/dwd/02_etl.sql` | 已完成 |
| 8 | 探索性分析脚本 | `sql/dwd/03_analysis.sql` | 已完成 |
| 9 | 探索性分析简报 | `探索性分析简报.docx` | 已完成 |
| 10 | AI 协同日志 | `第2周_AI协同日志.md` | 已完成 |

- 由 AI 生成的内容（代码 / SQL / 文案 / 图表）：三组清洗 SQL（枚举标准化、异常值与格式标准化、拆分合并与编码映射）、DWD 星型模型 DDL 与 ETL SQL、分月批量加载生成脚本 gen_batch.py、探索性分析 10 条查询 SQL、
- 由人工编写的内容：数据质量对比报告.docx、数仓架构设计文档.docx、探索性分析简报.docx、第2周_AI协同日志.md确认清洗业务口径（超大金额置 NULL、缺失填充策略）、确认 DWD 事实表粒度与维度设计、验证各步骤执行结果
- 人机协作完成的内容：age 字段 INT 类型陷阱排查（AI 定位根因，人工确认修复口径）、Derby 分区事务限制方案选型（AI 给出分批方案，人工验证 366 分区全部成功）、重复订单行数膨胀修复（AI 发现异常并修复，人工复核最终行数）、品类尾部空格问题（分析阶段发现、补入清洗脚本后复检归零）

## 四、问题与解决

- 遇到的问题：
  1. age 字段清洗后整列变 NULL（age_null=1000）
  2. 窗口函数嵌套在 COALESCE/CAST 内触发 ParseException
  3. 动态分区报 [Error 20004] too many dynamic partitions（上限 100）
  4. 一次性写入 366 个分区触发 Derby MoveTask "Exception rolling back to savepoint"（return code 40000）
  5. dwd_order 行数 39017 超过明细数 37549
  6. 品类分布查询出现 16 组（应为 8 组）

- AI 是否有效解决：是，问题由 AI 定位原因并给出可验证的解决方案

- 最终如何解决：
  1. DESCRIBE 确认 age 为 INT 类型，`age <> ''` 与空串比较恒为 NULL，改用 `age >= 0 AND age <= 100` 判断后重跑，age_null=0
  2. 将窗口均值拆为独立子查询，再通过 CROSS JOIN 标量引用，绕开解析限制
  3. SET hive.exec.max.dynamic.partitions.pernode=2048
  4. 改为按月分批加载：12 条 INSERT 每月约 30 分区，规避 Derby 单事务保存点回滚
  5. JOIN 前用 ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time) 取 rn=1 去重，行数恢复 37549
  6. 排查发现 27 条品类值尾部含空格/全角空格，在清洗脚本补 regexp_replace 去除后重载 dim_product，收敛为 8 组

## 五、反思与总结

- AI 协同带来的价值：
  1. 清洗与建模 SQL 从设计到验证全程加速，三类脏数据（69527 条）一次性修复至归零
  2. 在 Hive 4.0 + Tez + Derby 这类组合的冷门报错上，AI 能快速给出根因假设并设计验证实验（如单分区静态写入测试）

- AI 的局限与风险（准确性 / 合规性 / 依赖）：
  1. 准确性风险：AI 生成的 SQL 仍需实际执行验证，本次窗口函数嵌套、Derby 分区限制等问题都是执行后才暴露
  2. 依赖风险：INSERT OVERWRITE 属破坏性操作，若不理解机制可能误覆写有效数据，需人工确认目标表
  3. 合规性风险：数据修复策略（置 NULL、均值填充、默认日期）属于业务决策，必须由人工确认口径，不能默认采纳 AI 建议

- 本次协作中我的能力提升：
  1. 掌握了枚举标准化、异常值修复、格式标准化、编码映射的完整清洗套路
  2. 理解了星型模型设计（事实表粒度、维度表、分区键、PARQUET 列存）与动态分区 ETL
  3. 学会了分区裁剪验证（EXPLAIN）与行数对账等数仓质量核查方法
  4. 积累了 Hive 元数据（Derby）限制、Tez 引擎特性等工程实践经验

## 六、后续计划

- 第 3 周按规划建设 DWS 汇总层（dws_sales_1d、dws_user_consume_1d）与 ADS 应用层结果表
- 对超大金额置 NULL 的 312 条订单，在 DWS 层尝试按门店/品类均值二次填充并评估影响
- 结合 Superset 制作销售看板，复用本周 DWD 星型模型
