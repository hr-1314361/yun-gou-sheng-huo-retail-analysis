# 云购生活数据仓库项目

## 团队信息

- 队名：云购先锋
- 成员：胡蕊（学号 2786247380）
- 口号：数据驱动生活，云购连接你我

## 角色分工

- 项目经理：胡蕊
- 数据工程师：胡蕊
- 数据分析师：胡蕊
- 可视化工程师：胡蕊
（说明：按实训要求一人多岗，全部角色由本人承担）

## 项目目标

- 构建 ODS→DWD→DWS→ADS 四层数仓 + 可视化系统

## 阶段计划

- 第 1 周：环境/数据导入/清洗（一）
- 第 2 周：清洗进阶/数仓建模/探索分析
- 第 3 周：分析/预测/AI 协同
- 第 4 周：可视化/部署
- 第 5 周：整合文档/答辩

## 技术栈

| 类别 | 技术 |
|------|------|
| 容器化 | Docker Desktop + docker-compose（WSL2 后端） |
| 元数据库 | MySQL 8.0（Hive Metastore） |
| 数据仓库 | Apache Hive 4.0.0（HiveServer2 + Tez 引擎） |
| 数据处理 | Hive SQL（窗口函数、COALESCE、ROW_NUMBER） |
| 报表生成 | Python 3.x（openpyxl） |
| 版本管理 | Git |
| 可视化（后续） | Superset |

## 第 1 周完成内容

1. 环境搭建：Docker Compose 编排 MySQL + Hive Metastore + HiveServer2，beeline 连接验证通过
2. Git 仓库初始化：.gitignore 忽略数据/密钥/日志文件，提交信息遵循 feat/fix/docs 规范
3. ODS 层构建：ydsh_ods 库 + 6 张表建表与数据导入（真实模拟数据，行数与数据字典一致）
4. 数据质量预评估：五维度（完整性/唯一性/有效性/一致性/准确性）扫描 6 张表
5. 缺失值处理：age 均值填充、email 保留空值标记 unknown@、launch_date 按规则补全，输出 DWD 目标表 dwd_user、dwd_product
6. 重复值去重：ROW_NUMBER 窗口函数对 ods_order 按 order_id 去重，输出 dwd_order，并统计去重前后行数差异

## ODS 表结构（行数与数据字典一致）

| 表名 | 字段 | 行数 |
|------|------|------|
| ods_user | user_id, user_name, gender, age, city, province, register_date, member_level, phone, email | 1000 |
| ods_product | product_id, product_name, category, sub_category, brand, price, cost, stock, status, launch_date | 600 |
| ods_store | store_id, store_name, province, city, district, address, open_date, area, manager | 60 |
| ods_order | order_id, user_id, store_id, order_date, order_time, pay_amount, discount_amount, pay_type, order_status, channel | 15600 |
| ods_order_item | item_id, order_id, product_id, quantity, unit_price, discount | 37549 |
| ods_user_behavior | behavior_id, user_id, product_id, behavior_type, behavior_time, session_id | 60000 |

## 数据质量评估结果摘要

| 维度 | 主要发现 |
|------|----------|
| 完整性 | ods_user 的 gender、age、member_level、email 存在空值；ods_product 的 launch_date 存在空值；其余 4 表无空值 |
| 唯一性 | ods_order.order_id 存在 600 条主键重复（15600 行 → 去重后 15000 条）；其余 5 表主键无重复 |
| 有效性 | 存在负价格（price<0）、负金额（pay_amount/discount_amount<0）、数量非正（quantity<=0）、单价为负（unit_price<0）、age 越界等异常取值 |
| 一致性 | 5 条外键关系（order→user、order→store、order_item→order、order_item→product、behavior→user）全部通过，0 孤儿记录 |
| 准确性 | 日期格式混用（- 与 /），存在业务逻辑待核实的记录；详细量化结果见《数据质量预评估表.xlsx》 |

## 清洗策略记录

| 表 | 字段 | 缺失/重复情况 | 处理策略 | 输出表 |
|----|------|--------------|----------|--------|
| ods_user | age | 空值 | 用全体用户年龄均值填充 | dwd_user |
| ods_user | email | 空值 | 保留空值标记 unknown@ | dwd_user |
| ods_product | launch_date | 空值 | 按规则补全默认日期 2024-01-01 | dwd_product |
| ods_order | order_id | 600 条主键重复 | ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_date, order_time) 保留第一条 | dwd_order（15600→15000） |
| ods_order_item | item_id | 检测后按需去重 | ROW_NUMBER() OVER(PARTITION BY item_id ORDER BY order_id) 保留第一条 | dwd_order_item |

## 项目结构

```
xmsx/
├── docker-compose.yml          # Docker 编排文件
├── README.md                   # 项目说明
├── 环境搭建笔记.md              # 环境搭建问题与解决记录
├── .gitignore                  # Git 忽略配置
├── AI协同日志.md                # AI 协同工作日志
├── 数据质量预评估表.xlsx         # 五维度评估结果
├── sql/
│   ├── ods/
│   │   ├── create_ods.sql      # ODS 建表脚本（6 张表）
│   │   └── load_ods.sql        # 数据加载脚本
│   └── clean/
│       ├── dq_1_completeness.sql   # 完整性评估（空值统计）
│       ├── dq_2_uniqueness.sql     # 唯一性评估（重复统计）
│       ├── dq_3_consistency.sql    # 一致性评估（外键孤儿检查）
│       ├── dq_3_1~3_5.sql          # 一致性分表检查脚本
│       ├── dq_4_accuracy.sql       # 有效性评估（异常取值）
│       ├── dq_6_accuracy.sql       # 准确性评估（业务逻辑校验）
│       ├── step8_missing_values.sql  # 缺失值清洗（输出 dwd_user/dwd_product）
│       └── step9_dedup.sql           # 重复值去重（输出 dwd_order/dwd_order_item）
└── 模拟数据/                   # CSV 数据文件（gitignore 忽略）
    ├── ods_user.csv
    ├── ods_product.csv
    ├── ods_store.csv
    ├── ods_order.csv
    ├── ods_order_item.csv
    └── ods_user_behavior.csv
```
