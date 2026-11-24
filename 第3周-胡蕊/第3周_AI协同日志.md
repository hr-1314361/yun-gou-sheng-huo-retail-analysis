# 第3周 AI 协同日志

## 一、使用的工具/模型

| 工具/模型 | 用途 |
|-----------|------|
| TraeCode（AI 编程助手） | DWS/ADS SQL生成、Python预测脚本、NL2SQL链路、文档撰写、问题排查 |
| Docker Desktop | 容器化运行 MySQL + Hive（第2周环境延续） |
| Apache Hive 4.0.0（Tez 引擎） | DWS/ADS层建表与ETL执行 |
| Python（pandas/scikit-learn/statsmodels/xgboost） | 时间序列分析与预测建模 |
| LangChain + DeepSeek API | NL2SQL自然语言转SQL链路 |
| python-docx | 交付文档（预测报告、AI反思）生成 |
| Git | 团队协同（Fork工作流、PR、Code Review、Issue、合并冲突） |

## 二、协同记录表

| 序号 | 时间 | 任务内容 | AI 协助内容 | 结果 |
|------|------|----------|-------------|------|
| 1 | 11-07 10:00 | DWS汇总层设计 | 设计7张DWS表（日/周/月×品类/门店/渠道）DDL与ETL，含窗口函数GMV占比 | DDL+ETL脚本完成 |
| 2 | 11-07 14:00 | DWS gmv_share 报错排查 | 定位 Hive4.0 不支持 `SUM(SUM()) OVER()`，改为子查询先算日总GMV再JOIN | Issue #1 解决 |
| 3 | 11-07 16:00 | ADS应用层设计 | 设计5张ADS表（销售日报/品类TopN/用户价值分层/核心KPI/复购率），RFM模型实现 | ADS DDL+ETL完成 |
| 4 | 11-07 19:00 | 核心KPI计算 | GMV/订单量/客单价/活跃用户/复购率/品类占比 SQL，复购率先按user_id聚合再算 | KPI查询脚本完成 |
| 5 | 11-08 09:00 | 时间序列特征工程 | 构造滞后特征(lag_1/7/14/30)、滚动统计、周期编码(sin/cos) | 15个特征完成 |
| 6 | 11-08 11:00 | 预测模型训练 | 线性回归 vs XGBoost 对比，MAE/MAPE评估 | 线性回归最优，MAPE=4.35% |
| 7 | 11-08 14:00 | 递归预测报错修复 | 定位 lag_6/lag_13 字段不存在（Code Review发现），改为已有lag字段 | Issue #2 解决 |
| 8 | 11-08 16:00 | 预测报告生成 | 生成6章节预测建模分析报告docx，含边界分析 | 报告完成 |
| 9 | 11-09 10:00 | 大模型API接入 | .env密钥管理 + 最小化调用脚本，DeepSeek OpenAI兼容接口 | 连通性验证通过 |
| 10 | 11-09 14:00 | NL2SQL Schema抽取 | 编写自动抽取Hive表结构脚本，生成大模型可读Schema文本 | 7张表Schema抽取 |
| 11 | 11-09 16:00 | NL2SQL Prompt设计 | 设计含Schema约束+示例的系统提示词，约束表名字段名条件 | Prompt模板定稿 |
| 12 | 11-10 09:00 | LangChain链路构建 | LCEL链式编排：Prompt→LLM→StrOutputParser→Hive执行 | NL2SQL闭环完成 |
| 13 | 11-10 11:00 | AI异常归因 | 基于KPI数据调用大模型分析GMV突降原因，4维度归因 | 洞察结果输出 |
| 14 | 11-10 14:00 | AI经营摘要 | 生成自动化经营分析摘要，含销售节奏/渠道/用户/风险 | 摘要输出 |
| 15 | 11-10 15:00 | AI反思文档 | 撰写AI偏见局限与验证流程反思 | 反思文档完成 |
| 16 | 11-10 16:00 | Git协同实战 | Fork工作流文档+PR/Code Review记录+Issue+合并冲突演示 | 全流程留痕 |

## 三、产出成果清单

| 序号 | 交付物 | 文件路径 | 状态 |
|------|--------|----------|------|
| 1 | DWS建模与ETL脚本 | `sql/dws/01_ddl.sql`、`02_etl.sql` | ✅ |
| 2 | ADS建模与ETL脚本 | `sql/ads/01_ddl.sql`、`02_etl.sql`、`03_kpi_results.sql` | ✅ |
| 3 | 时间序列预测脚本 | `python/time_series_prediction.py` | ✅ |
| 4 | 预测建模分析报告 | `预测建模分析报告.docx` | ✅ |
| 5 | 大模型API接入 | `nl2sql/.env.example`、`nl2sql/llm_minimal_call.py` | ✅ |
| 6 | NL2SQL接口代码 | `nl2sql/schema_extract.py`、`nl2sql/nl2sql_langchain.py`、`nl2sql/prompt_template.txt` | ✅ |
| 7 | NL2SQL测试用例 | `nl2sql/test_questions.sql` | ✅ |
| 8 | AI智能洞察脚本 | `ai_insight/ai_insight.py` | ✅ |
| 9 | AI应用反思文档 | `AI应用反思.docx` | ✅ |
| 10 | Git协同记录 | `git/01_fork_workflow.md`、`02_pr_code_review.md`、`03_issues.md`、`04_merge_conflict.md` | ✅ |

- 由 AI 生成的内容：DWS/ADS全套SQL（DDL+ETL+KPI）、时间序列预测Python脚本、NL2SQL Schema抽取与LangChain链路、Prompt模板、AI洞察脚本、预测报告与反思文档生成脚本、Git协同文档
- 由人工编写的内容：RFM分档阈值确认、预测模型特征选择决策、AI洞察结果的审慎验证、Git合并冲突的人工解决
- 人机协作完成的内容：DWS gmv_share窗口函数兼容性问题（AI定位，人工确认改子查询方案）、预测模型选型（AI给出对比结果，人工确认选线性回归）、NL2SQL SQL正确性（AI生成SQL，人工执行验证）

## 四、问题与解决

- 遇到的问题：
  1. DWS gmv_share 窗口函数 `SUM(SUM()) OVER()` 在 Hive 4.0 报错
  2. 预测脚本递归预测引用不存在的 lag_6/lag_13 字段
  3. NL2SQL 生成的 SQL 偶尔使用不存在的字段名（如 sales_amount）
  4. Docker Desktop 频繁断连，Hive 环境不稳定
  5. RFM 阈值硬编码，缺乏数据分布依据

- AI 是否有效解决：是，AI 能快速定位语法与字段问题并给出修复方案

- 最终如何解决：
  1. 改为子查询先算每日总GMV，再JOIN回品类汇总计算占比
  2. 递归预测中改为使用已有的 lag_7/lag_14/lag_30 向前递推
  3. 在 Prompt 中增加字段名映射说明，并计划增加 Schema 校验步骤
  4. 在 Python 脚本中增加 Hive 不可用时的 fallback 模拟数据，保证流程可演示
  5. 在注释中说明阈值基于业务经验，记入 Issue #4 后续配置化

## 五、反思与总结

- AI 协同带来的价值：
  1. DWS/ADS 全套 SQL 从设计到产出效率大幅提升，7+5 张表的 DDL/ETL 一天内完成
  2. 预测建模的特征工程与模型对比由 AI 快速实现，人工聚焦于模型选型与边界分析
  3. NL2SQL 的 Prompt 设计与 LangChain 链路由 AI 搭建，加速了从0到1的过程
  4. 文档生成（预测报告、AI反思）由 AI 辅助，人工审核后定稿

- AI 的局限与风险：
  1. 准确性风险：AI 生成的 SQL 仍需执行验证，如 gmv_share 窗口函数兼容性问题就是执行后暴露
  2. 幻觉风险：AI 异常归因可能编造不存在的门店或活动，需事实核查
  3. 数值风险：大模型不擅长精确数值计算，生成的 SQL 需实际执行比对
  4. 依赖风险：LangChain 版本与 API 兼容性需关注，API Key 泄露风险需通过 .env 管理

- 本次协作中我的能力提升：
  1. 掌握了 DWS 汇总层与 ADS 应用层的设计方法（轻度汇总→业务应用）
  2. 学会了时间序列预测的完整流程（特征工程→模型训练→评估→递归预测）
  3. 理解了 NL2SQL 的核心要素（Schema抽取、Prompt设计、SQL校验）
  4. 实践了 Git Fork 工作流、PR/Code Review、Issue追踪、合并冲突解决

## 六、后续计划

- 第 4 周：搭建数据可视化看板（Superset/Metabase），对接 ADS 层结果表
- 优化 NL2SQL：增加 SQL 执行前 Schema 校验，提升 SQL 正确率
- RFM 阈值配置化：将硬编码阈值改为按数据分位数动态计算
- 积累更多用户行为数据，完善用户画像与精准营销模型
