# 子任务 1：Superset 连接数据源与经营分析仪表板

> 目标：Superset 通过 SQLAlchemy（底层 PyHive/Thrift，等价 JDBC 连接）连接 Hive，同时连接 MySQL；
> 基于 **ADS 层** 结果表创建 Dataset，制作 5 个图表并组合为带筛选器与联动的经营分析仪表板。

## 1. 目录说明

```
superset/
├── sql/
│   └── 00_ads_extend.sql     # 补充 ADS 层「支付方式」「区域」两张汇总表 + ETL
├── datasets.sql              # 6 个 Dataset 的 SQL 定义（SQL Lab 另存为 Dataset）
├── superset_config.py        # Superset 配置（密钥/元数据库/联动/缓存）
├── charts_dashboard.md       # 5 个图表 + 仪表板配置手册（本文件之外单独成文）
└── README.md                 # 连接数据源与构建流程
```

## 2. 前置：安装 Hive 与 MySQL 驱动

Superset 官方镜像内置 PyHive 相关依赖，若使用社区镜像或需连接 MySQL，进入容器安装：

```bash
docker exec -it superset bash -c "
  pip install --no-cache-dir \
    'apache-superset[hive]' \
    pyhive thrift thrift-sasl 'sasl>=0.3.1' \
    mysqlclient pymysql
"
```

> 说明：Superset 对 Hive 使用 SQLAlchemy 方言 `hive://`（底层 Thrift 协议，与 JDBC 的 HiveServer2 服务同一端口 10000）。
> 若课程要求纯 JDBC，可在 `Database → Advanced → Other → Engine Parameters` 中保持默认，
> 并在 `SQLAlchemy URI` 使用 `hive://`，两者访问的是同一个 HiveServer2 服务。

## 3. 连接 Hive（主数据源）

`Settings → Database Connections → + Database → Other`

| 配置项 | 值 |
|---|---|
| Display Name | `Hive-数仓(ydsh)` |
| SQLAlchemy URI | `hive://hive@hive-server2:10000/ydsh_ads` |
| 暴露数据库 | 勾选 `ydsh_ads`、`ydsh_dws`、`ydsh_dwd` |
| Engine Parameters | `{"connect_args": {"auth": "NOSASL"}}`（Hive 4 默认关闭认证） |

连接测试通过后保存。

> 若容器内 Hive 开启了 SASL，URI 改为 `hive://hive@hive-server2:10000/ydsh_ads?auth=LDAP`；
> 本次实训使用 `NOSASL`，与 `docker/hive/conf/hive-site.xml` 保持一致。

## 4. 连接 MySQL（辅助数据源）

`Settings → Database Connections → + Database → MySQL`

| 配置项 | 值 |
|---|---|
| Display Name | `MySQL-业务库(ydsh)` |
| SQLAlchemy URI | `mysql://root:${MYSQL_ROOT_PASSWORD}@mysql:3306/ydsh_ads?charset=utf8mb4` |

用途：
1. 存放 Superset 自身元数据（`superset` 库）；
2. 作为 Hive 查询结果的落地库，做「热数据快查」对照（可选）；
3. 演示 Superset 同时连接异构数据源。

## 5. 创建 Dataset（基于 ADS 层）

1. 执行 `sql/00_ads_extend.sql`，补齐 `ads_pay_type_daily`、`ads_region_sales` 两张 ADS 表；
2. 打开 `SQL Lab → SQL Editor`，数据库选 `Hive-数仓(ydsh)`，Schema 选 `ydsh_ads`；
3. 依次粘贴 `datasets.sql` 中的 6 段 SQL，执行后点击 `Save → Save dataset`，命名如下：

| Dataset 名称 | 来源表 | 用途 | 时间列 |
|---|---|---|---|
| `ds_sales_daily` | `ads_sales_daily` | 销售趋势折线图、KPI 卡 | `stat_date` |
| `ds_category_sales` | `ads_category_topn` | 品类销售柱状图 | `stat_date` |
| `ds_region_sales` | `ads_region_sales` | 区域分布地图 | `stat_date` |
| `ds_pay_type_daily` | `ads_pay_type_daily` | 支付方式占比饼图 | `stat_date` |
| `ds_category_topn` | `ads_category_topn` (rank_no ≤ 10) | TopN 排行表 | `stat_date` |
| `ds_core_kpi` | `ads_core_kpi` | 大数字 KPI 卡 | — |

4. 为每个 Dataset 在 `Columns` 页签确认：
   - `stat_date` → 类型 `DATETIME`，勾选 `Is temporal`；
   - `gmv` / `aov` / `gmv_share` → 数值类型；
   - `province` / `category` / `pay_type` → 维度（字符串）。

## 6. 图表与仪表板

5 个图表的字段映射、样式、筛选器与联动配置见 [charts_dashboard.md](./charts_dashboard.md)。

## 7. 导出与提交（Git）

仪表板完成后导出配置，随代码一起提交：

```bash
# 容器内导出（导出 zip 内含 dashboard/chart/dataset 元数据）
docker exec -it superset superset export-dashboards -f /tmp/dashboard_export.zip

# 复制到宿主机
docker cp superset:/tmp/dashboard_export.zip ./superset/dashboard_export.zip
```

导入（换机/答辩现场）：

```bash
docker cp ./superset/dashboard_export.zip superset:/tmp/
docker exec -it superset superset import-dashboards -p /tmp/dashboard_export.zip
```

> 截图清单（放入 `docs/screenshots/`）：
> ① 数据源连接测试成功；② 6 个 Dataset 列表；③ 5 个图表；④ 仪表板全貌；
> ⑤ 筛选器生效前后对比；⑥ 点击柱状图联动其他图表。
