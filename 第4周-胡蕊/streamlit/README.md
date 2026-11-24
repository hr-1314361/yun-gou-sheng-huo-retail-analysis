# 子任务 3：Streamlit 对话式数据问答

> 把第 3 周完成的 NL2SQL 能力包装成可交互的对话界面，形成
> **提问 → 生成 SQL → 执行 Hive → 表格/图表渲染** 的完整闭环。

## 1. 目录结构

```
streamlit/
├── app.py                  # 主应用（对话界面、历史、加载态、错误提示）
├── nl2sql_engine.py        # NL2SQL 引擎（三级降级：实时 / SQL+演示结果 / 纯演示）
├── chart_render.py         # 结果自动选图 + ECharts 内联渲染
├── prompt_template.txt     # 大模型 Prompt 模板（含 Schema 占位）
├── requirements.txt
├── .env.example
└── .streamlit/config.toml
```

## 2. 启动

```bash
cd 第4周-胡蕊/streamlit

# 1) 安装依赖
pip install -r requirements.txt

# 2) 配置密钥
copy .env.example .env       # Windows
# 编辑 .env，填入 DEEPSEEK_API_KEY

# 3) 启动
streamlit run app.py
# 浏览器打开 http://localhost:8501
```

容器内部署：见 `../docker/docker-compose.yml` 的 `python-app` 服务（端口 8501）。

## 3. 闭环实现

```
用户输入问题
   │
   ├─ ① NL2SQLEngine.generate_sql()   读取 Schema + Prompt → DeepSeek → SQL
   │        └─ clean_sql() 清洗 Markdown / is_safe_sql() 仅允许 SELECT
   ├─ ② NL2SQLEngine.execute()        PyHive 连接 HiveServer2:10000 执行
   ├─ ③ pandas DataFrame              表格展示 + CSV 下载
   └─ ④ chart_render.infer_option()   自动推断折线/柱状/饼图 → ECharts 渲染
```

安全约束：
- 只允许单条 `SELECT`，命中 `INSERT/UPDATE/DELETE/DROP/ALTER/CREATE/TRUNCATE` 直接拦截；
- 默认 `LIMIT 100`，避免把大结果集拉进浏览器；
- 大模型密钥仅从环境变量读取，代码中无硬编码。

## 4. 交互体验

| 能力 | 实现 |
|---|---|
| 历史对话 | `st.session_state.messages` 保存全部问答，刷新页面不丢失（会话级） |
| 加载状态 | 生成与执行阶段显示 `st.spinner("正在生成 SQL 并执行查询...")` |
| 错误提示 | 密钥缺失 / SQL 生成失败 / Hive 连接失败分别用 warning、error 区分展示 |
| 示例问题 | 侧边栏 6 个一键示例，降低演示操作成本 |
| 结果下载 | 每条结果提供 CSV 下载（`utf-8-sig`，Excel 不乱码） |
| 后端状态 | 顶部胶囊实时显示「大模型 / Hive」连接状态，可一键重测 |
| 图表开关 | 侧边栏可关闭自动可视化，只看表格 |

## 5. 三级降级（答辩保险）

| 场景 | 行为 | 页面标识 |
|---|---|---|
| 大模型 + Hive 均可用 | 真实生成并查询，返回真实数据 | 数据来源：大模型 + Hive 实时查询 |
| 大模型可用、Hive 不可用 | 展示真实生成的 SQL，结果用演示数据填充 | 数据来源：大模型生成 SQL + 演示结果 |
| 大模型不可用 | 使用内置示例问答（6 类问题） | 数据来源：本地演示数据 |

降级不会中断演示流程，错误原因以黄色提示条展示，便于教师现场提问时说明。

## 6. 图表自动推断规则

| 条件 | 图表 |
|---|---|
| 维度值形如 `2024-11` / `2024-11-11`，或列名含 date/month/day | 折线图 |
| 行数 ≤ 8 且度量列名含 `share` / `rate` / `占比` / `率` | 饼图 |
| 其他「维度 + 度量」组合 | 柱状图 |
| 结果为全数值列 | 按行号折线 |

ECharts 使用 `../echarts/static/echarts.min.js` 内联注入，**离线可用**；
找不到本地文件时自动回退 CDN。

## 7. 验收清单

- [x] 接入第 3 周 NL2SQL（Schema + Prompt + DeepSeek）后端
- [x] 提问 → SQL → 执行 → 表格 → 图表 完整闭环
- [x] ECharts 图表嵌入 Streamlit
- [x] 历史对话、加载状态、错误提示
- [x] 密钥环境变量注入，无硬编码
