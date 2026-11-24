# Pull Request 与 Code Review 记录

## PR #3：[DWS/ADS] 汇总层与应用层建设

### 基本信息
- **标题**：[DWS/ADS] 汇总层与应用层建设 + 核心KPI计算
- **分支**：`hurui/feature/dws-ads-layer` → `ydsh-team/main`
- **作者**：胡蕊
- **评审人**：张三、李四
- **状态**：✅ 已合并（Merged）
- **关联 Issue**：#1, #2

### PR 描述
本次 PR 完成第3周子任务1：
1. DWS 汇总层：dws_sales_1d、dws_sales_category_1d、dws_sales_store_1d、dws_sales_channel_1d、dws_sales_1w、dws_sales_1m、dws_user_consume_1d
2. ADS 应用层：ads_sales_daily、ads_category_topn、ads_user_value_segment、ads_core_kpi、ads_repurchase_daily
3. 核心KPI计算：GMV、订单量、客单价、活跃用户数、复购率、品类销售占比

### 变更文件清单
```
sql/dws/01_ddl.sql      (新增, 140行)
sql/dws/02_etl.sql      (新增, 180行)
sql/ads/01_ddl.sql      (新增, 90行)
sql/ads/02_etl.sql      (新增, 120行)
sql/ads/03_kpi_results.sql (新增, 80行)
```

### Code Review 意见与处理

#### Reviewer 张三（2条意见）

| # | 意见 | 严重度 | 处理 |
|---|------|--------|------|
| 1 | `dws_sales_1w` 的 week_key 计算逻辑过于复杂，建议直接用 `date_format(order_date, 'yyyy-Www')` | 建议 | ✅ 已采纳，简化为 date_format |
| 2 | `ads_user_value_segment` 的 RFM 分档阈值（如 recency<=30 得5分）是硬编码的，建议说明数据来源或做成可配置 | 建议 | ✅ 已采纳，在注释中说明阈值基于业务经验，后续可配置化 |

#### Reviewer 李四（3条意见）

| # | 意见 | 严重度 | 处理 |
|---|------|--------|------|
| 1 | `ads_core_kpi` 的复购率计算中，LEFT JOIN 后用 SUM(CASE...) 可能因 dwd_order 多行导致重复计数，建议先用子查询去重 | 🔴 严重 | ✅ 已采纳，改为先按 user_id 聚合再计算 |
| 2 | `dws_sales_category_1d` 的 gmv_share 窗口函数 `SUM(SUM(amount)) OVER()` 在 Hive 中可能不被支持，建议用子查询先算日总GMV再JOIN | 🟡 中等 | ✅ 已采纳，改为子查询方式 |
| 3 | 所有金额字段建议统一加 COMMENT 说明单位（元） | 🟢 轻微 | ✅ 已采纳，补充注释 |

### 评审结论
- 张三：✅ Approve（2条建议已处理）
- 李四：✅ Approve（严重问题已修复）
- 合并方式：Squash Merge（保持 main 分支历史简洁）

---

## PR #4：[预测] 时间序列预测建模脚本

### 基本信息
- **标题**：feat(python): 新增时间序列预测建模脚本与报告
- **分支**：`hurui/feature/timeseries-prediction` → `ydsh-team/main`
- **作者**：胡蕊
- **评审人**：李四
- **状态**：✅ 已合并

### Code Review 意见

| # | 意见 | 严重度 | 处理 |
|---|------|--------|------|
| 1 | 预测脚本中 `_generate_mock_daily_sales` 的模拟数据全年GMV=7.21亿，与实际6.61亿有偏差，建议调整参数 | 🟡 中等 | ✅ 已调整趋势系数使全年GMV接近6.6亿 |
| 2 | XGBoost 递归预测时 lag_6/lag_13/lag_29 字段不存在，应使用已有的 lag_7/lag_14/lag_30 近似 | 🔴 严重 | ✅ 已修复，改为正确的 lag 字段引用 |
| 3 | 缺少模型特征重要性输出，建议补充 XGBoost 的 feature_importances_ 打印 | 🟢 轻微 | ✅ 已补充 |
