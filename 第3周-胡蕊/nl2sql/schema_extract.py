# -*- coding: utf-8 -*-
"""
第3周 子任务4（上）：自动抽取 Hive 表 Schema
============================================
功能：自动抽取 Hive 表（表名、字段名、字段类型、字段注释），生成供大模型理解的数据库元信息。
依赖：pip install pyhive pandas
运行：python schema_extract.py
输出：schema_info.json + schema_info.txt（供 NL2SQL Prompt 使用）
"""
import json
import os
from dotenv import load_dotenv

load_dotenv()

HIVE_HOST = os.getenv("HIVE_HOST", "localhost")
HIVE_PORT = int(os.getenv("HIVE_PORT", "10000"))
HIVE_USER = os.getenv("HIVE_USER", "root")

# 需要抽取的表清单（DWD + DWS + ADS 核心表）
TARGET_TABLES = {
    "ydsh_dwd": ["dwd_order", "dim_user", "dim_product", "dim_store", "dim_date"],
    "ydsh_dws": ["dws_sales_1d", "dws_sales_category_1d", "dws_sales_store_1d",
                 "dws_sales_channel_1d", "dws_sales_1m", "dws_user_consume_1d"],
    "ydsh_ads": ["ads_sales_daily", "ads_category_topn", "ads_user_value_segment",
                 "ads_core_kpi", "ads_repurchase_daily"],
}


def extract_table_schema(cursor, db: str, table: str) -> dict:
    """抽取单张表的字段名、类型、注释"""
    cursor.execute(f"DESCRIBE {db}.{table}")
    rows = cursor.fetchall()
    columns = []
    for r in rows:
        col_name = r[0].strip() if r[0] else ""
        col_type = r[1].strip() if len(r) > 1 and r[1] else ""
        col_comment = r[2].strip() if len(r) > 2 and r[2] else ""
        if col_name and not col_name.startswith("#"):
            columns.append({"name": col_name, "type": col_type, "comment": col_comment})
    # 表注释
    try:
        cursor.execute(f"DESCRIBE FORMATTED {db}.{table}")
        table_comment = ""
        for r in cursor.fetchall():
            if r and len(r) > 1 and r[0] and "comment" in str(r[0]).lower():
                table_comment = str(r[1]).strip()
                break
    except Exception:
        table_comment = ""
    return {"database": db, "table": table, "comment": table_comment, "columns": columns}


def extract_from_hive() -> dict:
    """从 Hive 抽取所有目标表 Schema"""
    from pyhive import hive
    conn = hive.Connection(host=HIVE_HOST, port=HIVE_PORT, username=HIVE_USER)
    cursor = conn.cursor()
    schemas = []
    for db, tables in TARGET_TABLES.items():
        for tbl in tables:
            try:
                schemas.append(extract_table_schema(cursor, db, tbl))
                print(f"[OK] {db}.{tbl}")
            except Exception as e:
                print(f"[WARN] {db}.{tbl} 抽取失败: {e}")
    conn.close()
    return {"tables": schemas}


def generate_fallback_schema() -> dict:
    """当 Hive 不可用时，使用基于已知表结构的静态 Schema（供演示）"""
    return {
        "tables": [
            {"database": "ydsh_dwd", "table": "dwd_order",
             "comment": "订单明细事实表，按order_date分区",
             "columns": [
                 {"name": "order_id", "type": "string", "comment": "订单ID"},
                 {"name": "user_id", "type": "string", "comment": "用户ID"},
                 {"name": "store_id", "type": "string", "comment": "门店ID"},
                 {"name": "product_id", "type": "string", "comment": "商品ID"},
                 {"name": "quantity", "type": "int", "comment": "数量"},
                 {"name": "unit_price", "type": "double", "comment": "成交单价"},
                 {"name": "amount", "type": "double", "comment": "明细金额=数量*单价"},
                 {"name": "pay_type", "type": "string", "comment": "支付方式(支付宝/微信支付/货到付款/银行卡)"},
                 {"name": "order_status", "type": "string", "comment": "订单状态(待支付/已支付/已完成/已取消/退款中)"},
                 {"name": "channel", "type": "string", "comment": "下单渠道(APP/小程序/PC官网/门店)"},
                 {"name": "order_date", "type": "string", "comment": "订单日期(yyyy-MM-dd, 分区列)"},
             ]},
            {"database": "ydsh_dwd", "table": "dim_product",
             "comment": "商品维度表",
             "columns": [
                 {"name": "product_id", "type": "string", "comment": "商品ID"},
                 {"name": "product_name", "type": "string", "comment": "商品名"},
                 {"name": "category", "type": "string", "comment": "品类"},
                 {"name": "sub_category", "type": "string", "comment": "子类目"},
                 {"name": "brand", "type": "string", "comment": "品牌"},
                 {"name": "price", "type": "double", "comment": "售价"},
             ]},
            {"database": "ydsh_dwd", "table": "dim_store",
             "comment": "门店维度表",
             "columns": [
                 {"name": "store_id", "type": "string", "comment": "门店ID"},
                 {"name": "store_name", "type": "string", "comment": "门店名"},
                 {"name": "province", "type": "string", "comment": "省"},
                 {"name": "city", "type": "string", "comment": "市"},
             ]},
            {"database": "ydsh_dws", "table": "dws_sales_1d",
             "comment": "销售日汇总表",
             "columns": [
                 {"name": "stat_date", "type": "string", "comment": "统计日期"},
                 {"name": "gmv", "type": "double", "comment": "成交总额(元)"},
                 {"name": "order_cnt", "type": "bigint", "comment": "订单量"},
                 {"name": "user_cnt", "type": "bigint", "comment": "下单用户数"},
                 {"name": "aov", "type": "double", "comment": "客单价"},
             ]},
            {"database": "ydsh_dws", "table": "dws_sales_category_1d",
             "comment": "销售-品类日汇总表",
             "columns": [
                 {"name": "stat_date", "type": "string", "comment": "统计日期"},
                 {"name": "category", "type": "string", "comment": "品类"},
                 {"name": "gmv", "type": "double", "comment": "品类成交总额"},
                 {"name": "order_cnt", "type": "bigint", "comment": "品类订单量"},
                 {"name": "gmv_share", "type": "double", "comment": "品类GMV占比"},
             ]},
            {"database": "ydsh_ads", "table": "ads_category_topn",
             "comment": "品类销售TopN表",
             "columns": [
                 {"name": "stat_date", "type": "string", "comment": "统计日期"},
                 {"name": "category", "type": "string", "comment": "品类"},
                 {"name": "gmv", "type": "double", "comment": "品类GMV"},
                 {"name": "gmv_share", "type": "double", "comment": "品类GMV占比"},
                 {"name": "rank_no", "type": "int", "comment": "品类GMV排名"},
             ]},
            {"database": "ydsh_ads", "table": "ads_core_kpi",
             "comment": "核心KPI总表",
             "columns": [
                 {"name": "stat_period", "type": "string", "comment": "统计周期"},
                 {"name": "gmv", "type": "double", "comment": "成交总额"},
                 {"name": "order_cnt", "type": "bigint", "comment": "订单量"},
                 {"name": "user_cnt", "type": "bigint", "comment": "下单用户数"},
                 {"name": "aov", "type": "double", "comment": "客单价"},
                 {"name": "repurchase_rate", "type": "double", "comment": "复购率"},
             ]},
        ]
    }


def schema_to_text(schema: dict) -> str:
    """将 Schema 转为大模型易读的文本格式"""
    lines = ["# 数据库表结构（Schema）", ""]
    for tbl in schema["tables"]:
        lines.append(f"## 表：{tbl['database']}.{tbl['name'] if 'name' in tbl else tbl['table']}")
        lines.append(f"注释：{tbl.get('comment', '')}")
        lines.append("| 字段名 | 类型 | 注释 |")
        lines.append("|--------|------|------|")
        for col in tbl["columns"]:
            lines.append(f"| {col['name']} | {col['type']} | {col['comment']} |")
        lines.append("")
    return "\n".join(lines)


def main():
    print("=" * 50)
    print("Hive Schema 自动抽取")
    print("=" * 50)
    try:
        schema = extract_from_hive()
    except Exception as e:
        print(f"[WARN] Hive 连接失败({e})，使用内置静态 Schema")
        schema = generate_fallback_schema()

    os.makedirs("output", exist_ok=True)
    with open("output/schema_info.json", "w", encoding="utf-8") as f:
        json.dump(schema, f, ensure_ascii=False, indent=2)
    with open("output/schema_info.txt", "w", encoding="utf-8") as f:
        f.write(schema_to_text(schema))
    print(f"[OK] Schema 已保存：output/schema_info.json / .txt")
    print(f"[OK] 共抽取 {len(schema['tables'])} 张表")


if __name__ == "__main__":
    main()
