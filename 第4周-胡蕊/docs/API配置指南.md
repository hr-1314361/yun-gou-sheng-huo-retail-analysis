# API 配置指南

> 适用对象：本项目所有对外/对内 API 与连接配置
> 覆盖：DeepSeek 大模型、Hive、MySQL、ClickHouse、Superset 数据源、Streamlit / Docker 环境变量

---

## 一、配置总览

| 配置项 | 环境变量 | 默认值 | 使用位置 |
|---|---|---|---|
| 大模型 Key | `DEEPSEEK_API_KEY` | 空（演示模式） | `streamlit/nl2sql_engine.py` |
| 大模型地址 | `DEEPSEEK_BASE_URL` | `https://api.deepseek.com` | 同上 |
| 大模型名称 | `LLM_MODEL` | `deepseek-chat` | 同上 |
| Hive 主机 | `HIVE_HOST` | `localhost` | `nl2sql_engine.py`、`stress_test.py` |
| Hive 端口 | `HIVE_PORT` | `10000` | 同上 |
| Hive 用户 | `HIVE_USER` | `hive` | 同上 |
| MySQL 主机 | `MYSQL_HOST` | `mysql`（容器内） | `superset/superset_config.py` |
| MySQL 端口 | `MYSQL_PORT` | `3306` | 同上 |
| MySQL 密码 | `MYSQL_ROOT_PASSWORD` | 无（必填） | Superset、Hive Metastore |
| Superset 密钥 | `SUPERSET_SECRET_KEY` | 无（必填） | Superset |
| Superset 元数据库 | `SUPERSET_DB_NAME` | `superset` | Superset |
| Redis | `REDIS_URL` | `redis://redis:6379/1` | Superset 缓存 |
| ClickHouse 密码 | `CLICKHOUSE_PASSWORD` | 无（必填） | ClickHouse、压测 |
| ECharts 本地路径 | `ECHARTS_JS` | `/opt/echarts/echarts.min.js`（容器） | `streamlit/chart_render.py` |

**优先级**：系统环境变量 > `.env` 文件 > 代码默认值。Docker 部署时由 `docker/.env` 统一注入。

---

## 二、DeepSeek 大模型 API

### 2.1 基本信息

| 项 | 值 |
|---|---|
| Base URL | `https://api.deepseek.com` |
| 协议 | OpenAI 兼容（`/v1/chat/completions`） |
| 模型 | `deepseek-chat` |
| 认证 | `Authorization: Bearer <DEEPSEEK_API_KEY>` |
| 超时建议 | 60s |
| 并发建议 | ≤ 5（个人 Key） |

### 2.2 请求示例

```python
from openai import OpenAI

client = OpenAI(api_key="sk-xxx", base_url="https://api.deepseek.com")
resp = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "把问题转换为 Hive SQL：2024年11月GMV"}],
    temperature=0.0,
    max_tokens=600,
)
print(resp.choices[0].message.content)
```

### 2.3 参数约定（本项目）

| 参数 | 值 | 原因 |
|---|---|---|
| `temperature` | 0.0 | NL2SQL 要求确定性，避免 SQL 抖动 |
| `max_tokens` | 512~600 | SQL 长度有限，控制成本 |
| `stream` | False | 一次性返回便于解析与安全校验 |

### 2.4 错误码与处理

| HTTP | 含义 | 处理 |
|---|---|---|
| 401 | Key 无效 / 过期 | 检查 `.env`，轮换 Key |
| 402 | 余额不足 | 充值或切换备用模型 |
| 429 | 触发限流 | 指数退避重试（1s/2s/4s），降低并发 |
| 500/503 | 服务端异常 | 重试 2 次后进入演示模式 |
| 超时 | 网络问题 | 设置 60s 超时，失败即降级 |

> 本项目在 `NL2SQLEngine.ask()` 中统一捕获异常：任何失败都会回退到演示数据并提示原因，
> 不会让页面白屏。

---

## 三、Hive 连接配置

### 3.1 连接参数

| 项 | 值 |
|---|---|
| Host | `hive-server2`（容器内）/ `localhost`（宿主机） |
| Port | `10000`（HiveServer2 Thrift） |
| Auth | `NOSASL`（内网实训环境） |
| 用户 | `hive` |
| 默认库 | `ydsh_ads` |

### 3.2 PyHive（Python）

```python
from pyhive import hive

conn = hive.Connection(host="localhost", port=10000, username="hive", auth="NOSASL")
cur = conn.cursor()
cur.execute("SELECT * FROM ydsh_ads.ads_sales_daily LIMIT 5")
print(cur.description)
print(cur.fetchall())
conn.close()
```

### 3.3 Beeline / JDBC

```bash
beeline -u "jdbc:hive2://localhost:10000/ydsh_ads;auth=noSasl" -n hive -e "show tables;"
```

JDBC URL 中 `auth=noSasl` 与配置文件的 `hive.server2.authentication=NOSASL` 必须一致，
否则会报 `GSS initiate failed` 或 `TTransportException`。

### 3.4 Superset SQLAlchemy URI

```
hive://hive@hive-server2:10000/ydsh_ads
```

Engine Parameters：

```json
{"connect_args": {"auth": "NOSASL"}}
```

### 3.5 常用会话参数

| 参数 | 值 | 说明 |
|---|---|---|
| `hive.server2.idle.session.timeout` | 1800000 | 会话空闲 30 分钟回收 |
| `hive.server2.idle.operation.timeout` | 600000 | 操作空闲 10 分钟回收 |
| `hive.exec.dynamic.partition.mode` | nonstrict | 允许动态分区 |
| `hive.exec.max.dynamic.partitions` | 1000 | 防止分区爆炸 |

---

## 四、MySQL 连接配置

| 场景 | URI |
|---|---|
| Superset 元数据库 | `mysql+pymysql://root:<密码>@mysql:3306/superset?charset=utf8mb4` |
| Hive Metastore | `jdbc:mysql://mysql:3306/metastore?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true` |
| Superset 业务数据源 | `mysql+pymysql://root:<密码>@mysql:3306/ydsh_ads?charset=utf8mb4` |
| 只读分析账号 | `ydsh_reader / readonly_2024`（仅 `SELECT ydsh_ads.*`） |

连接验证：

```bash
docker exec -it ydsh-mysql mysql -uroot -p -e "show databases;"
```

> 使用 `pymysql` 方言（纯 Python），避免 `mysqlclient` 编译依赖；
> 若使用 `mysqlclient`，URI 改为 `mysql://`。

---

## 五、ClickHouse 连接配置

| 项 | 值 |
|---|---|
| HTTP 端口 | `8123` |
| Native 端口 | `9000` |
| 用户 / 密码 | `default` / `CLICKHOUSE_PASSWORD` |
| 数据库 | `ydsh_ads` |

```bash
# HTTP
curl "http://localhost:8123/?query=SELECT%201"

# Native
docker exec -it ydsh-clickhouse clickhouse-client --password <密码> -q "SELECT version()"
```

Python（`clickhouse-connect`）：

```python
import clickhouse_connect
client = clickhouse_connect.get_client(host="localhost", port=8123,
                                       username="default", password="<密码>")
print(client.query("SELECT count() FROM ydsh_ads.ads_sales_daily").result_rows)
```

---

## 六、Superset 配置

| 配置 | 值 |
|---|---|
| 元数据库 | `mysql+pymysql://root:<密码>@mysql:3306/superset?charset=utf8mb4` |
| `SECRET_KEY` | `SUPERSET_SECRET_KEY`（必须随机且保密） |
| 缓存 | Redis `redis://redis:6379/1`，300s |
| 行数上限 | `ROW_LIMIT=10000`、`SQL_MAX_ROW=50000` |
| 查询超时 | `SQLLAB_TIMEOUT=120` |
| 功能开关 | `DASHBOARD_CROSS_FILTERS`、`DASHBOARD_NATIVE_FILTERS`、`DRILL_TO_DETAIL` |

配置文件挂载：`docker/docker-compose.yml` 将 `superset/superset_config.py`
挂载到容器 `/app/pythonpath/superset_config.py`。

---

## 七、Streamlit 环境变量

```ini
DEEPSEEK_API_KEY=sk-xxxx
DEEPSEEK_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
HIVE_HOST=hive-server2
HIVE_PORT=10000
HIVE_USER=hive
ECHARTS_JS=/opt/echarts/echarts.min.js
```

启动：

```bash
streamlit run app.py --server.port=8501 --server.address=0.0.0.0
```

---

## 八、配置验证清单

```bash
# 1) 大模型
python -c "from openai import OpenAI;print(OpenAI(api_key='<key>',base_url='https://api.deepseek.com').models.list())"

# 2) Hive
docker exec -it ydsh-hive-server2 beeline -u "jdbc:hive2://localhost:10000/default;auth=noSasl" -e "show databases;"

# 3) MySQL
docker exec -it ydsh-mysql mysqladmin -uroot -p status

# 4) ClickHouse
curl http://localhost:8123/ping

# 5) Superset
curl http://localhost:8088/health

# 6) Streamlit
curl http://localhost:8501/_stcore/health

# 7) 编排文件
docker compose config --quiet && echo "compose ok"
```

---

## 九、常见错误速查

| 报错 | 原因 | 解决 |
|---|---|---|
| `Invalid API key` | Key 错误/过期 | 更新 `.env` 并重启 |
| `Insufficient balance` | 额度用尽 | 充值或改用演示模式 |
| `Could not connect to any of ['hive-server2']` | 容器未就绪 | `docker compose ps`，等待 healthy |
| `TTransportException: Could not start SASL` | auth 配置不一致 | 服务端 `NOSASL`，客户端也传 `auth="NOSASL"` |
| `Access denied for user 'root'@'mysql'` | 密码不一致 | 检查 `MYSQL_ROOT_PASSWORD` 是否被修改但未重建卷 |
| `SECRET_KEY` 未设置 | 缺少环境变量 | 在 `.env` 填写 `SUPERSET_SECRET_KEY` |
| `ModuleNotFoundError: pymysql` | 镜像未装驱动 | 重新构建 Superset 镜像 |

---

## 十、安全要求

1. 所有配置值只通过环境变量或 `.env` 注入，**代码中禁止硬编码**；
2. `.env` 不提交 Git，仅提交 `.env.example`；
3. Key 90 天轮换一次，人员变动立即轮换；
4. 详见《密钥安全管理方案》（`docs/密钥安全管理方案.md`）。
