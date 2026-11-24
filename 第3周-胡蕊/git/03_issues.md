# Issue 追踪记录

## Issue #1：DWS 层 gmv_share 窗口函数在 Hive 4.0 中报错

- **标题**：DWS层 gmv_share 计算报错 `UnsupportedSubqueryException`
- **状态**：✅ Closed
- **优先级**：高
- **标签**：bug, dws, hive
- **报告人**：胡蕊
- **报告时间**：2026-11-08

### 问题描述
执行 `dws_sales_category_1d` 的 ETL 时，以下窗口函数报错：
```sql
SUM(SUM(d.amount)) OVER (PARTITION BY d.order_date)
```
Hive 4.0 不支持聚合函数嵌套在窗口函数中。

### 解决过程
1. 确认 Hive 4.0 不支持 `SUM(SUM(...)) OVER()` 语法
2. 改为子查询先计算每日总GMV，再JOIN回品类汇总表
3. 重新执行 ETL 成功

### 最终方案
```sql
WITH daily_total AS (
    SELECT order_date, SUM(amount) AS total_gmv
    FROM ydsh_dwd.dwd_order GROUP BY order_date
)
SELECT c.order_date, c.category, c.gmv, c.gmv / t.total_gmv AS gmv_share
FROM (SELECT order_date, category, SUM(amount) AS gmv FROM ... GROUP BY order_date, category) c
JOIN daily_total t ON c.order_date = t.order_date;
```

---

## Issue #2：预测模型递归预测时 lag 字段不存在

- **标题**：预测脚本递归预测报错 KeyError: 'lag_6'
- **状态**：✅ Closed
- **优先级**：高
- **标签**：bug, python, prediction
- **报告人**：李四（Code Review 发现）
- **报告时间**：2026-11-09

### 问题描述
`predict_next_7_days` 函数中引用了 `cur["lag_6"]`，但特征工程只构造了 lag_1/7/14/30，
导致递归预测第2天时抛出 KeyError。

### 解决过程
1. 定位到 `predict_next_7_days` 中的错误字段引用
2. 改为使用已有的 lag_7/lag_14/lag_30 作为近似（向前递推）
3. 重新运行脚本，7天预测正常输出

---

## Issue #3：NL2SQL 生成的 SQL 字段名与实际表不一致

- **标题**：NL2SQL 生成 SQL 使用了不存在的字段 `sales_amount`
- **状态**：🔄 Open
- **优先级**：中
- **标签**：bug, nl2sql
- **报告人**：胡蕊
- **报告时间**：2026-11-10

### 问题描述
测试问题"广东省上月销售额"时，大模型生成的SQL使用了 `sales_amount` 字段，
但实际表中字段名为 `amount` 或 `gmv`。

### 改进计划
1. 在 Prompt 中增加字段名映射说明（销售额→gmv/amount）
2. 增加 SQL 执行前的 Schema 校验步骤
3. 收集失败案例，迭代优化 Prompt

---

## Issue #4：ADS 用户价值分层 RFM 阈值硬编码

- **标题**：ads_user_value_segment 的 RFM 分档阈值需配置化
- **状态**：🔄 Open
- **优先级**：低
- **标签**：enhancement, ads
- **报告人**：张三
- **报告时间**：2026-11-09

### 改进建议
当前 RFM 得分阈值（如 recency<=30得5分）是硬编码的，建议：
1. 将阈值存入配置表或参数文件
2. 根据数据分布动态计算分位数作为阈值
3. 支持按业务线配置不同阈值
