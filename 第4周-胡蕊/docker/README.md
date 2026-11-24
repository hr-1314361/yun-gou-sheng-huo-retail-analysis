# 子任务 4：Docker Compose 一键部署

> 一条命令拉起 7 个服务：MySQL、Hive Metastore、HiveServer2、ClickHouse、Redis、Superset、Streamlit App。

## 1. 服务拓扑

```
                      ┌──────────────┐
                      │   浏览器      │
                      └───┬──────┬───┘
                 :8088    │      │   :8501
                ┌─────────▼──┐ ┌─▼─────────────┐
                │  Superset  │ │ Streamlit App │
                └──┬──────┬──┘ └───┬───────────┘
                   │      │        │ PyHive
        ┌──────────▼─┐ ┌──▼────┐   │
        │   Redis    │ │ MySQL │◄──┘（元数据：metastore / superset）
        │  (缓存)     │ │ :3306 │
        └────────────┘ └──▲────┘
                          │ JDBC
                   ┌──────┴────────┐
                   │ Hive Metastore│ :9083
                   └──────▲────────┘
                          │ thrift
                   ┌──────┴────────┐        ┌────────────┐
                   │  HiveServer2  │ :10000 │ ClickHouse │ :8123
                   └───────────────┘        └────────────┘
```

## 2. 启动顺序与健康检查

| 顺序 | 服务 | 健康检查 | 依赖条件 |
|---|---|---|---|
| 1 | `mysql` | `mysqladmin ping` | — |
| 2 | `hive-metastore` | TCP 9083 可连接 | mysql healthy |
| 3 | `hive-server2` | TCP 10000 可连接 | metastore healthy |
| 4 | `redis` | `redis-cli ping` | — |
| 5 | `clickhouse` | `SELECT 1` | — |
| 6 | `superset` | `GET /health` | mysql + redis healthy |
| 7 | `python-app` | `GET /_stcore/health` | hiveserver2 started |

> `python-app` 只要求 Hive `service_started` 而非 `healthy`：
> Hive 首次启动需要初始化 Metastore（1~3 分钟），Streamlit 不应被阻塞；
> 应用内置三级降级，Hive 未就绪时自动使用演示数据，就绪后刷新即走真实查询。

## 3. 一键部署

```powershell
cd 第4周-胡蕊\docker

# 1) 准备环境变量（首次）
copy .env.example .env
# 编辑 .env，把所有 change_me 改成强密码，并填入 DEEPSEEK_API_KEY

# 2) 一键启动（首次会构建 Hive / Superset / App 镜像，耗时较长）
docker compose up -d --build

# 3) 查看状态（等待 STATUS 全部为 healthy）
docker compose ps

# 4) 查看启动日志
docker compose logs -f hive-metastore
```

或直接执行脚本：`.\start.ps1`。

## 4. 服务地址

| 服务 | 地址 | 账号 |
|---|---|---|
| Superset | http://localhost:8088 | admin / `.env` 中的 `SUPERSET_ADMIN_PASSWORD` |
| Streamlit 智能问数 | http://localhost:8501 | — |
| HiveServer2 | `localhost:10000`（NOSASL） | 用户 `hive` |
| Hive Metastore | `localhost:9083` | — |
| MySQL | `localhost:3307` | root / `MYSQL_ROOT_PASSWORD` |
| ClickHouse HTTP | http://localhost:8123 | default / `CLICKHOUSE_PASSWORD` |
| ClickHouse Native | `localhost:9000` | 同上 |

## 5. 验证部署

```powershell
# 服务状态
docker compose ps

# Hive 连通性（进入容器执行）
docker exec -it ydsh-hive-server2 beeline -u "jdbc:hive2://localhost:10000/default;auth=noSasl" -e "show databases;"

# ClickHouse
docker exec -it ydsh-clickhouse clickhouse-client --password $env:CLICKHOUSE_PASSWORD -q "SELECT 1"

# Superset 健康检查
curl http://localhost:8088/health

# Streamlit 健康检查
curl http://localhost:8501/_stcore/health
```

## 6. 敏感信息注入

- 所有密码、密钥集中在 `docker/.env`，通过 `environment` 注入容器；
- `docker-compose.yml` 中 **没有硬编码任何密码**；
- Hive 元数据库密码通过 `hive-site.xml` 的 `${env.MYSQL_ROOT_PASSWORD}` 变量替换；
- `.env` 已加入 `.gitignore`，仓库只提交 `.env.example`。

## 7. 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| `hive-metastore` 反复 Restarting | MySQL 未就绪或 JDBC 驱动缺失 | `docker compose logs hive-metastore`；确认 `hive/lib/*.jar` 存在并重新 `--build` |
| Superset 启动报 `No module named pymysql` | 镜像未重新构建 | `docker compose build --no-cache superset` |
| 8501 页面提示「演示模式」 | 未配置 API Key 或 Hive 未就绪 | 检查 `.env` 与 `docker compose ps`，就绪后点侧边栏「重测连接」 |
| 3307 / 8088 端口被占用 | 本机已有 MySQL / Superset | 修改 compose 端口映射 |
| 首次启动很慢 | 需要初始化 Metastore schema | 正常现象，等待 `start_period`（90~120s） |

## 8. 停止与清理

```powershell
docker compose down          # 停止并删除容器（保留数据卷）
docker compose down -v       # 同时删除数据卷（慎用，会清空数据）
```
