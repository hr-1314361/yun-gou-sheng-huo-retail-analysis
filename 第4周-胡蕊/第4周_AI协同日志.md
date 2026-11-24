# 第4周 AI 协同日志

## 一、使用的工具/模型

| 工具/模型 | 用途 |
|-----------|------|
| TraeCode（AI 编程助手） | Superset 配置与数据集设计、ECharts 大屏代码、Streamlit 应用、Docker 编排、压测脚本、文档撰写与问题排查 |
| Apache Superset 3.1.3 | 基于 ADS 层的 BI 仪表板（折线/柱状/地图/饼图/TopN + 筛选器联动） |
| Apache ECharts 5.5.0 | 数据大屏（折线/柱状/散点/热力图/地图） |
| Streamlit 1.67.0 | 对话式 NL2SQL 查询界面，嵌入 ECharts 图表 |
| Docker Compose v2 | MySQL + Hive Metastore + HiveServer2 + ClickHouse + Redis + Superset + Python App 一键编排 |
| Python（pandas/pyhive/thrift） | 数据接入、压测脚本、数据生成脚本 |
| DeepSeek API | Streamlit 内的 NL2SQL 大模型推理（延续第3周配置） |
| python-docx | 周志等交付文档生成 |

## 二、协同记录表

| 序号 | 时间 | 任务内容 | AI 协助内容 | 结果 |
|------|------|----------|-------------|------|
| 1 | 11-13 09:00 | ADS 层主题补齐 | 第3周 ADS 缺支付方式/区域主题，设计 `ads_pay_type_daily`、`ads_region_sales` 两张扩展表及 ETL | 2 张 ADS 表 + ETL 完成 |
| 2 | 11-13 10:30 | Superset 连接 Hive | 生成 SQLAlchemy URI `hive://hive@hive-server2:10000/ydsh_ads`，补充 NOSASL 连接参数说明 | 连接配置定稿 |
| 3 | 11-13 11:30 | Superset 数据集 | 设计 DS-1~DS-6 六个 Virtual Dataset SQL（日销售/品类TopN/区域/支付/KPI） | 6 个数据集 SQL |
| 4 | 11-13 14:00 | Superset 图表与仪表板 | 输出 5 个图表的字段映射表、12 栅格布局、4 个筛选器与联动关系 | 图表/仪表板设计文档完成 |
| 5 | 11-13 16:00 | Superset 元数据库方言修复 | 排查 `mysql://` 方言在镜像内缺 mysqlclient 的问题，改为 `mysql+pymysql://` | Issue #1 解决 |
| 6 | 11-14 09:00 | ECharts 数据准备 | 编写 `gen_data.py`，以固定随机种子生成与 ADS 同口径的模拟数据（GMV 6.61亿/15000单/8932用户） | 数据 JS/JSON 生成 |
| 7 | 11-14 10:30 | ECharts 离线资源 | CDN 下载失败后改用 npmmirror 下载 echarts.min.js，地图改用 DataV 全国 GeoJSON 并本地化 | 离线可用 |
| 8 | 11-14 13:30 | ECharts 五类图表 | 双轴折线（含峰值 markPoint）、横向柱状、气泡散点、时段×品类热力图、中国地图轮播高亮 | 5 图表完成 |
| 9 | 11-14 15:30 | ECharts 大屏自适应 | 采用 1920×1080 等比 scale（translate+scale），监听 resize 并防抖调用 chart.resize() | 自适应完成 |
| 10 | 11-14 17:00 | ECharts 后端 JSON 接口 | 标准库 ThreadingHTTPServer 实现 `/api/health`、`/api/dashboard`，前端 `?api=1` 读取并可回退本地数据 | 接口验证 200 |
| 11 | 11-15 09:00 | Streamlit NL2SQL 引擎 | 封装 `NL2SQLEngine`，三级降级（llm+hive / llm+demo / demo），SQL 安全校验仅允许 SELECT | 引擎完成 |
| 12 | 11-15 11:00 | Streamlit 图表渲染 | 自动图表类型推断（折线/柱状/饼图/散点），生成自包含 HTML 并内联 ECharts | 渲染模块完成 |
| 13 | 11-15 14:00 | 图表 PermissionError 排查 | 定位 `os.getenv("ECHARTS_JS","")` 空串使 `abspath("")` 指向目录，改为跳过空路径 + `os.path.isfile` | Issue #2 解决 |
| 14 | 11-15 15:30 | 图表空白排查 | 定位双度量时 series `yAxisIndex=1` 但只给 1 个 yAxis，ECharts 静默失败；修复为按度量数生成双 yAxis | Issue #3 解决 |
| 15 | 11-15 16:30 | Streamlit 交互完善 | 历史对话、spinner 加载状态、错误提示分级、示例问题、CSV 下载、连接重测 | 浏览器验证 PASS |
| 16 | 11-16 09:00 | Docker 编排 | 编写 7 服务 compose（健康检查、依赖顺序、命名卷、网络），并做 `docker compose config` 校验 | 编排校验通过 |
| 17 | 11-16 11:00 | Hive 容器镜像 | Hive 4.0 镜像内 COPY MySQL JDBC 驱动到 /opt/hive/lib，解决 Metastore 连 MySQL 缺驱动 | 镜像方案完成 |
| 18 | 11-16 14:00 | 密钥安全方案 | 输出 .env 管理、轮换、权限最小化、泄露处置规范与自查命令 | 方案文档完成 |
| 19 | 11-16 16:00 | Hive 查询优化 | 分区裁剪、数据倾斜（skewindata + 加盐）、分桶 Map Join 三类优化 SQL 与说明 | 优化报告 + 3 个 SQL |
| 20 | 11-17 09:00 | 压力测试 | 编写多并发压测脚本（P50/P90/P95/P99、QPS、成功率），本地基准实跑 1/5/10/20 并发 | 压测报告 + CSV 产出 |
| 21 | 11-17 11:00 | 部署与配置文档 | 撰写《部署手册》《API配置指南》，含架构图、验证命令、故障排查、错误速查 | 2 份文档完成 |

## 三、产出成果清单

| 序号 | 交付物 | 文件路径 | 状态 |
|------|--------|----------|------|
| 1 | ADS 扩展表与 ETL | `superset/sql/00_ads_extend.sql` | ✅ |
| 2 | Superset 数据集 SQL | `superset/datasets.sql` | ✅ |
| 3 | Superset 配置 | `superset/superset_config.py` | ✅ |
| 4 | Superset 图表与仪表板设计 | `superset/charts_dashboard.md`、`superset/README.md` | ✅ |
| 5 | ECharts 大屏 | `echarts/index.html`、`css/screen.css`、`js/main.js` | ✅ |
| 6 | ECharts 数据与接口 | `echarts/gen_data.py`、`data/*`、`api_server.py` | ✅ |
| 7 | Streamlit 应用 | `streamlit/app.py`、`nl2sql_engine.py`、`chart_render.py` | ✅ |
| 8 | Docker 编排 | `docker/docker-compose.yml`、`hive/`、`superset/`、`app/`、`mysql/`、`clickhouse/` | ✅（配置校验通过） |
| 9 | 密钥安全与查询优化 | `docs/密钥安全管理方案.md`、`docs/Hive查询优化报告.md`、`docs/hive_optimization/*.sql` | ✅ |
| 10 | 压力测试 | `stress_test/stress_test.py`、`results/*.csv`、`results/stress_test_report.md` | ✅ |
| 11 | 交付文档 | `docs/部署手册.md`、`docs/API配置指南.md` | ✅ |

- 由 AI 生成的内容：Superset 数据集 SQL 与配置、ECharts 全栈代码、Streamlit 应用与图表渲染、Dockerfile 与 compose、压测脚本、优化 SQL、全部文档初稿
- 由人工编写的内容：图表与指标口径确认、大屏视觉方向把关、示例问题挑选、压测并发档位设定、密钥安全规范落地
- 人机协作完成的内容：Superset 图表字段映射（AI 给方案，人工核对 AD 字段）、Streamlit 图表空白问题（AI 定位双 Y 轴，人工浏览器验证）、Docker 服务依赖顺序（AI 给配置，人工确认 Hive 启动特性）

## 四、问题与解决

- 遇到的问题：
  1. Superset 元数据库 URI 使用 `mysql://`，镜像内只有 pymysql 无 mysqlclient，会启动失败
  2. ECharts 官方 CDN（jsdelivr）下载中断，地图 JSON 编码格式不兼容
  3. Streamlit 渲染图表报 `PermissionError: [Errno 13] Permission denied`（目录路径）
  4. Streamlit 中 ECharts 画布为空，`getOption().series` 为空数组
  5. 饼图未生效，被判定为柱状图
  6. Docker Desktop 未运行，无法执行真实 `docker compose up`
  7. 系统 Python 位于沙箱外不可写，Streamlit 安装失败

- AI 是否有效解决：是，均为可复现的配置/代码问题，AI 定位到根因并给出最小修复

- 最终如何解决：
  1. 改为 `mysql+pymysql://`，与镜像内驱动一致
  2. echarts 改用 npmmirror 下载并本地化；地图改用 DataV `100000_full.json`（35 features，全称省份）
  3. `ECHARTS_CANDIDATES` 跳过空字符串，并用 `os.path.isfile` 判断
  4. 按度量数量生成双 yAxis，解决 `yAxisIndex=1` 越界导致的静默失败；同时为 iframe 初始宽度 0 增加显式宽度与 ResizeObserver
  5. `share_flag` 改为遍历所有数值列名判断“占比/率/ratio”
  6. 用 `docker compose config --quiet` 校验编排合法性，真实拉起需在有 Docker daemon 的机器执行
  7. 在 `streamlit/.venv` 建本地虚拟环境安装 streamlit 1.67.0

## 五、反思与总结

- AI 协同带来的价值：
  1. 五个子任务的技术骨架（Superset/ECharts/Streamlit/Docker/压测）由 AI 快速搭建，人工聚焦口径确认与验收
  2. 大屏视觉与交互（等比缩放、地图轮播、KPI 数字滚动）实现效率显著提升
  3. 排障效率高：PermissionError、双 Y 轴越界、饼图判定三个问题均在数轮内定位到根因
  4. 文档体系（部署手册/API 指南/优化报告/密钥方案）一次成型，内容与代码一致

- AI 的局限与风险：
  1. 环境依赖风险：AI 生成的配置未必匹配实际镜像/版本，如 `mysql://` 方言、Hive JDBC 驱动缺失
  2. 静默失败风险：ECharts 配置越界不报错、只画空白，必须用浏览器实际验证而不是“看代码像对的”
  3. 数据真实性：ECharts 大屏与压测本地基准使用模拟数据，需在文档中明确标注，避免误当真实生产指标
  4. 未验证交付：Docker 编排只做了语法校验，Superset 仪表板截图依赖真实环境补拍

- 本次协作中我的能力提升：
  1. 掌握了 BI 工具（Superset）从数据源、数据集到仪表板与筛选器联动的完整配置链路
  2. 理解了 ECharts 大屏的适配方案（scale 等比缩放）与常见配置陷阱
  3. 完成了“提问→生成SQL→执行→图表”的对话式分析闭环，学会处理 iframe 内图表尺寸问题
  4. 掌握了 Docker Compose 的健康检查、依赖顺序与密钥环境变量注入
  5. 建立了“先分区裁剪、再治理倾斜、最后分桶 Join”的 Hive 优化方法论与量化压测意识

## 六、后续计划

- 在有 Docker 环境的机器上执行 `docker compose up -d --build`，补拍 Superset 仪表板截图与联动 GIF
- 执行 `stress_test.py --engine hive`，用 Hive 实测数据替换本地 SQLite 基准
- ECharts 大屏数据源由模拟数据切换为 `/api/dashboard` 直连 Hive（通过 Python 服务查询 ADS）
- 补充 Superset 告警报表与定时刷新，形成自动化日报
- 准备 8 分钟答辩脚本与现场一键部署演示流程
