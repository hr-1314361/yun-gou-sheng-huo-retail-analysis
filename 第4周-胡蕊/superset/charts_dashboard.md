# Superset 图表与仪表板配置手册

> 数据集见 [datasets.sql](./datasets.sql)，数据源连接见 [README.md](./README.md)。
> 图表总数：5 个分析图表 + 4 个 KPI 大数字卡；仪表板名称：`云购生活 · 经营分析看板`。

---

## 一、图表清单总览

| # | 图表名称 | 图表类型 | Dataset | 维度 | 度量 |
|---|---|---|---|---|---|
| 1 | 销售趋势（GMV / 订单量） | Line（双轴） | `ds_sales_daily` | `stat_date`（月粒度） | `SUM(gmv)`、`SUM(order_cnt)` |
| 2 | 品类销售对比 | Bar | `ds_category_sales` | `category` | `SUM(gmv)` |
| 3 | 区域销售分布 | Map（China） | `ds_region_sales` | `province` | `SUM(gmv)` |
| 4 | 支付方式占比 | Pie（环形） | `ds_pay_type_daily` | `pay_type` | `SUM(gmv)` |
| 5 | 品类 Top10 排行 | Table | `ds_category_topn` | `rank_no`、`category` | `gmv`、`gmv_share`、`order_cnt` |
| KPI | GMV / 订单量 / 用户数 / 客单价 / 复购率 | Big Number | `ds_core_kpi`、`ds_sales_daily` | — | 对应度量 |

---

## 二、逐图配置

### 图表 1：销售趋势折线图

`Charts → + Chart → ds_sales_daily → Line Chart`

| 配置项 | 值 |
|---|---|
| Time → Time Column | `stat_date` |
| Time Grain | `Month`（答辩时演示 `Day / Week / Month` 切换） |
| Metrics（左轴） | `SUM(gmv)`，Label：`GMV(元)` |
| Metrics（右轴） | `SUM(order_cnt)`，Label：`订单量` |
| Y Axis 2 | 开启（Order Count 使用右轴） |
| X Axis | 显示时间，格式 `YYYY-MM` |
| Series Style → Line Width | 2.5，Area：开启（渐变面积） |
| Tooltip | 显示 `gmv`、`order_cnt`、`aov` |

**业务含义**：识别全年销售节奏，11 月大促峰值、2 月春节低谷，支撑第 3 周预测结论。

### 图表 2：品类销售柱状图

`Charts → + Chart → ds_category_sales → Bar Chart`

| 配置项 | 值 |
|---|---|
| Dimensions | `category` |
| Metrics | `SUM(gmv)`，Label：`GMV(元)` |
| Row Limit | 20 |
| Sort By | `SUM(gmv)` 降序 |
| Orientation | Vertical |
| Show Values | 开启，格式 `,.0f` |
| Color Scheme | `supersetColors`（或自定义 `#2E7CF6` 单色渐变） |
| Annotation | 在均值处添加横向参考线（可选） |

### 图表 3：区域分布地图

`Charts → + Chart → ds_region_sales → Map`

| 配置项 | 值 |
|---|---|
| Map 类型 | `Country Map` → `China` |
| Country | `China` |
| Province（地图实体） | `province`（必须为「广东省 / 浙江省」等全称） |
| Metric | `SUM(gmv)` |
| Row Limit | 100 |
| Visual Map | 分段：`0-5千万 / 5千万-1亿 / 1-2亿 / 2亿+`，色带由浅蓝到深蓝 |
| Legend / Tooltip | 显示 GMV、订单量、门店数 |

> 若省份名称与内置地图不一致，在 Dataset 的 Calculated Column 中统一：
> `CASE WHEN province LIKE '%省' THEN province ELSE CONCAT(province,'省') END`
> 直辖市保持 `北京市 / 上海市 / 天津市 / 重庆市`。

### 图表 4：支付方式占比饼图

`Charts → + Chart → ds_pay_type_daily → Pie Chart`

| 配置项 | 值 |
|---|---|
| Dimensions | `pay_type` |
| Metric | `SUM(gmv)` |
| Donut | 开启（内径 55%） |
| Label Type | `Percentage` + `Category` |
| Number Format | `,.2%` |
| Row Limit | 10 |
| Legend | 右侧，显示金额 |

### 图表 5：品类 Top10 排行表

`Charts → + Chart → ds_category_topn → Table`

| 配置项 | 值 |
|---|---|
| Query Mode | `Raw Records` |
| Columns | `rank_no`、`category`、`gmv`、`gmv_share`、`order_cnt` |
| Order By | `rank_no` 升序 |
| Row Limit | 10 |
| Conditional Formatting | `gmv` 数据条（Data Bars），`gmv_share` 百分比格式 |
| 表头 | 中文别名：排名 / 品类 / GMV / 占比 / 订单量 |

### KPI 大数字卡（4 个）

`Big Number` 图表，Dataset `ds_core_kpi`（`stat_period = '2024全年'`）：
GMV、订单量、下单用户数、客单价；`ds_sales_daily` 另做一张「复购率」卡。

---

## 三、仪表板布局（12 栅格）

```
┌──────────────────────────────────────────────────────────────────────┐
│  标题：云购生活 · 经营分析看板        筛选器：时间范围 | 品类 | 区域 | 支付方式 │
├──────────────┬──────────────┬──────────────┬──────────────────────────┤
│  GMV 6.61亿  │ 订单量 1.5万 │ 用户数 8,932 │  客单价 440.7 / 复购率 31.2% │  ← KPI 行
├──────────────┴──────────────┴──────────────┴──────────────────────────┤
│  销售趋势折线图（宽 8）                              │ 支付方式饼图（宽 4）     │
├──────────────────────────────────────────────────────┼──────────────────────┤
│  品类销售柱状图（宽 6）                                │ 区域分布地图（宽 6）     │
├──────────────────────────────────────────────────────┴──────────────────────┤
│  品类 Top10 排行表（宽 12）                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

搭建步骤：
1. `Dashboards → + Dashboard`，命名 `云购生活 · 经营分析看板`；
2. `Edit Dashboard → Charts → + Add`，依次加入 8 个图表（4 KPI + 5 分析图），按上图拖拽到对应栅格；
3. 图表行高统一 50，KPI 卡行高 25，页面留白 16px，保证 1920×1080 一屏展示；
4. 保存后设置 `Published`。

---

## 四、筛选器配置

`Dashboard → Edit → Filters → + Add Filter`

| 筛选器 | 类型 | 绑定 Dataset | 字段 | 默认值 | 作用范围 |
|---|---|---|---|---|---|
| 时间范围 | Time Range | `ds_sales_daily` | `stat_date` | `2024-01-01 ~ 2024-12-31` | 全部图表 |
| 品类 | Value（多选） | `ds_category_sales` | `category` | 全部 | 图表 1、2、4、5 |
| 区域 | Value（多选） | `ds_region_sales` | `province` | 全部 | 图表 1、2、3、5 |
| 支付方式 | Value（多选） | `ds_pay_type_daily` | `pay_type` | 全部 | 图表 1、4 |

绑定方式：筛选器 `Settings → Filter Configuration → 勾选需要联动的图表`。
筛选器之间相互独立，避免循环依赖导致查询放大。

---

## 五、图表联动（Cross-filter）

1. 确认 `superset_config.py` 中 `DASHBOARD_CROSS_FILTERS = True`；
2. 图表 `Edit → Interactions → Cross-filter` 打开；
3. 联动关系设计：

| 触发图表 | 被联动图表 | 联动字段 |
|---|---|---|
| 品类柱状图（点击某品类） | 销售趋势、支付方式饼图、TopN 表 | `category` |
| 区域地图（点击某省） | 销售趋势、品类柱状图 | `province` |
| 支付方式饼图（点击某支付方式） | 销售趋势、TopN 表 | `pay_type` |

4. 演示话术：点击「运动户外」→ 趋势图与饼图同步收敛到该品类 → 右上角显示联动筛选条件；
   再次点击或点「×」取消联动。

---

## 六、性能与稳定性设置

| 项 | 值 | 原因 |
|---|---|---|
| Dataset 仅查 ADS 结果表 | — | 数据量小，避免扫 `dwd_order` 分区 |
| 图表缓存 | 300s | 答辩多次刷新不重复扫 Hive |
| `ROW_LIMIT` | 10000 | 防止误查大表拖垮 HiveServer2 |
| `SQLLAB_TIMEOUT` | 120s | 慢查询熔断 |
| 时间筛选 | 默认 2024 全年 | 与数仓分区范围一致，触发分区裁剪 |

---

## 七、验收清单

- [ ] Hive / MySQL 两个数据源连接测试成功（含截图）
- [ ] 6 个 Dataset 创建完成，时间列类型为 DATETIME
- [ ] 5 个图表全部可正常渲染，数据与 ADS 表一致
- [ ] 仪表板含 ≥3 个筛选器，筛选后各图表同步刷新
- [ ] 点击品类/区域可实现跨图表联动
- [ ] `superset export-dashboards` 导出的 zip 已提交 Git
