# -*- coding: utf-8 -*-
"""
第4周 子任务2：ECharts 大屏数据生成
=====================================
作用：
  1. 从 ADS 层口径生成大屏所需的 JSON 数据（本脚本用确定性模拟数据，
     保证与第3周 ADS 结果口径一致：全年 GMV≈6.61 亿、订单量 15000、
     11 月大促峰值、2 月低谷、复购率≈31.2%）；
  2. 输出 data/dashboard_data.js（window.DASHBOARD_DATA），
     以 JS 变量方式加载，避免 file:// 直接打开时的 fetch 跨域限制；
  3. 输出 data/china_geo.js（window.CHINA_GEO），使地图离线可用。

生产环境替换方式：
  将 build_from_hive() 接 Hive 查询（ydsh_ads.*），字段与当前结构保持一致即可，
  main.js 无需任何修改。
"""
import json
import os
import random

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
STATIC_DIR = os.path.join(BASE_DIR, "static")

random.seed(20241111)

# ---------------- 口径常量（与第3周 ADS 结果对齐） ----------------
TOTAL_GMV = 661_000_000.0
TOTAL_ORDER = 15_000
TOTAL_USER = 8_932
REPURCHASE_RATE = 0.312
AOV = round(TOTAL_GMV / TOTAL_ORDER, 2)

MONTH_WEIGHT = [0.070, 0.055, 0.070, 0.072, 0.078, 0.082,
                0.080, 0.078, 0.080, 0.088, 0.145, 0.102]

CATEGORIES = [
    ("运动户外", 0.180, 620),
    ("家用电器", 0.160, 1480),
    ("食品生鲜", 0.140, 180),
    ("美妆个护", 0.120, 320),
    ("服饰鞋包", 0.110, 450),
    ("数码3C", 0.100, 1250),
    ("母婴玩具", 0.070, 260),
    ("家居家装", 0.070, 880),
    ("图书文娱", 0.050, 95),
]

PROVINCES = [
    ("广东省", 0.178), ("江苏省", 0.112), ("浙江省", 0.108),
    ("山东省", 0.088), ("河南省", 0.070), ("四川省", 0.066),
    ("湖北省", 0.058), ("湖南省", 0.052), ("河北省", 0.048),
    ("福建省", 0.046), ("上海市", 0.042), ("北京市", 0.041),
    ("安徽省", 0.038), ("陕西省", 0.030), ("辽宁省", 0.028),
    ("重庆市", 0.026), ("江西省", 0.022), ("云南省", 0.020),
    ("广西壮族自治区", 0.018), ("山西省", 0.016),
]

PAY_TYPES = [("支付宝", 0.42), ("微信支付", 0.38), ("银行卡", 0.12), ("货到付款", 0.08)]
CHANNELS = [("APP", 0.45), ("小程序", 0.28), ("门店", 0.15), ("PC官网", 0.12)]
TIME_SLOTS = ["00-03", "03-06", "06-09", "09-12", "12-15", "15-18", "18-21", "21-24"]
SLOT_WEIGHT = [0.03, 0.01, 0.06, 0.17, 0.14, 0.15, 0.24, 0.20]


def build_trend():
    """月度销售趋势（折线：GMV + 订单量）"""
    trend = []
    for i, w in enumerate(MONTH_WEIGHT):
        gmv = round(TOTAL_GMV * w, 2)
        order = int(TOTAL_ORDER * w * random.uniform(0.96, 1.04))
        trend.append({
            "month": f"2024-{i + 1:02d}",
            "gmv": gmv,
            "order_cnt": order,
            "aov": round(gmv / order, 2) if order else 0,
        })
    # 校准订单量总量
    diff = TOTAL_ORDER - sum(x["order_cnt"] for x in trend)
    trend[10]["order_cnt"] += diff
    return trend


def build_categories(trend):
    """品类销售额 / 销量 / 客单价 / 占比"""
    items = []
    for name, share, price in CATEGORIES:
        gmv = round(TOTAL_GMV * share, 2)
        order_cnt = max(1, int(TOTAL_ORDER * share * random.uniform(0.9, 1.1)))
        items.append({
            "category": name,
            "gmv": gmv,
            "order_cnt": order_cnt,
            "gmv_share": round(share, 4),
            "aov": round(gmv / order_cnt, 2),
            "item_cnt": int(gmv / price),
            "price": price,
        })
    items.sort(key=lambda x: x["gmv"], reverse=True)
    for idx, it in enumerate(items, 1):
        it["rank_no"] = idx
    return items


def build_regions():
    """省份 GMV 分布（地图）。份额按合计归一，保证各省之和等于全年 GMV。"""
    regions = []
    share_sum = sum(s for _, s in PROVINCES)
    for name, share in PROVINCES:
        share = share / share_sum
        gmv = round(TOTAL_GMV * share, 2)
        order_cnt = int(TOTAL_ORDER * share * random.uniform(0.92, 1.08))
        regions.append({
            "province": name,
            "gmv": gmv,
            "order_cnt": order_cnt,
            "user_cnt": int(order_cnt * random.uniform(0.55, 0.72)),
            "store_cnt": random.randint(2, 18),
            "gmv_share": round(share, 4),
        })
    regions.sort(key=lambda x: x["gmv"], reverse=True)
    return regions


def build_heatmap(categories):
    """时段 × 品类 热力图（GMV，万元）"""
    data = []
    for yi, slot in enumerate(TIME_SLOTS):
        for xi, cat in enumerate(categories):
            base = cat["gmv"] * SLOT_WEIGHT[yi] / 10000.0
            val = round(base * random.uniform(0.82, 1.18), 1)
            data.append([xi, yi, val])
    return data


def build_scatter(categories):
    """品类散点：客单价 × 销量，气泡大小 = GMV（相关性分析）"""
    return [{
        "name": c["category"],
        "value": [c["aov"], c["item_cnt"], round(c["gmv"] / 1e8, 2)],
    } for c in categories]


def build_cube(trend, categories, regions):
    """三维数据立方体：月份 × 省份 × 品类，用于图表联动下钻。

    实现方式：三维迭代比例拟合（IPF/RAS），依次对齐三组一维边缘——
      月份总量、省份总量、品类总量，迭代收敛后三个维度各自的汇总都严格
      等于原始口径（全年 GMV、各省 GMV、各品类 GMV），保证联动后各图自洽。
    单元格格式：[月份下标, 省份下标, 品类下标, GMV, 订单量]
    """
    months = [t["month"] for t in trend]
    provinces = [r["province"] for r in regions]
    cats = [c["category"] for c in categories]
    M = [t["gmv"] for t in trend]
    P = [r["gmv"] for r in regions]
    Cc = [c["gmv"] for c in categories]
    total = sum(M)
    nm, nprov, ncat = len(months), len(provinces), len(cats)

    x = [[[1.0] * ncat for _ in range(nprov)] for _ in range(nm)]
    for _ in range(40):
        # 1) 对齐月份总量
        for m in range(nm):
            s = sum(x[m][p][c] for p in range(nprov) for c in range(ncat))
            if s:
                f = M[m] / s
                for p in range(nprov):
                    for c in range(ncat):
                        x[m][p][c] *= f
        # 2) 对齐省份总量
        for p in range(nprov):
            s = sum(x[m][p][c] for m in range(nm) for c in range(ncat))
            if s:
                f = P[p] / s
                for m in range(nm):
                    for c in range(ncat):
                        x[m][p][c] *= f
        # 3) 对齐品类总量
        for c in range(ncat):
            s = sum(x[m][p][c] for m in range(nm) for p in range(nprov))
            if s:
                f = Cc[c] / s
                for m in range(nm):
                    for p in range(nprov):
                        x[m][p][c] *= f

    cat_aov = {c["category"]: c["gmv"] / c["order_cnt"] for c in categories}
    cells = []
    for m in range(nm):
        for p in range(nprov):
            for c in range(ncat):
                gmv = round(x[m][p][c], 2)
                if gmv <= 0:
                    continue
                order = max(1, int(round(gmv / cat_aov[cats[c]])))
                cells.append([m, p, c, gmv, order])

    # 订单量校准：使立方体订单合计等于全年订单口径
    diff = TOTAL_ORDER - sum(cell[4] for cell in cells)
    if diff != 0:
        step = 1 if diff > 0 else -1
        order_idx = sorted(range(len(cells)), key=lambda i: cells[i][4], reverse=True)
        for i in range(abs(diff)):
            cells[order_idx[i % len(order_idx)]][4] += step

    return {
        "months": months,
        "provinces": provinces,
        "categories": cats,
        "cells": cells,
    }


def build_dashboard():
    trend = build_trend()
    categories = build_categories(trend)
    regions = build_regions()
    return {
        "meta": {
            "title": "云购生活 · 新零售经营数据大屏",
            "subtitle": "Enterprise Data Warehouse & Business Analytics",
            "period": "2024-01-01 ~ 2024-12-31",
            "updated": "2024-12-31 23:59:59",
            "source": "ydsh_ads",
        },
        "kpi": {
            "gmv": TOTAL_GMV,
            "order_cnt": TOTAL_ORDER,
            "user_cnt": TOTAL_USER,
            "aov": AOV,
            "repurchase_rate": REPURCHASE_RATE,
            "gmv_yoy": 0.183,
            "order_yoy": 0.142,
            "user_yoy": 0.097,
        },
        "trend": trend,
        "categories": categories,
        "regions": regions,
        "pay_types": [{"pay_type": n, "gmv": round(TOTAL_GMV * s, 2),
                       "gmv_share": s} for n, s in PAY_TYPES],
        "channels": [{"channel": n, "gmv": round(TOTAL_GMV * s, 2),
                      "gmv_share": s} for n, s in CHANNELS],
        "heatmap": {
            "x": [c["category"] for c in categories],
            "y": TIME_SLOTS,
            "data": build_heatmap(categories),
        },
        "scatter": build_scatter(categories),
        "topn": categories[:10],
        # 联动立方体：月份 × 省份 × 品类，供前端跨图筛选聚合
        "cube": build_cube(trend, categories, regions),
    }


def build_from_hive():
    """生产环境：从 Hive ADS 层取数（Hive 不可用时回退到模拟数据）"""
    try:
        from pyhive import hive  # noqa: F401
        import pandas as pd  # noqa: F401
        # 示例：
        # conn = hive.Connection(host=os.getenv("HIVE_HOST", "localhost"), port=10000)
        # trend = pd.read_sql("SELECT stat_date, gmv, order_cnt FROM ydsh_ads.ads_sales_daily", conn)
        # ... 按 build_dashboard() 的结构组装
        raise NotImplementedError("生产环境按需接入")
    except Exception as e:
        print(f"[WARN] Hive 取数不可用({e})，使用模拟数据生成大屏")
        return build_dashboard()


def write_js(name, var_name, obj):
    path = os.path.join(DATA_DIR, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"/* 自动生成，请勿手工修改：python gen_data.py */\n")
        f.write(f"window.{var_name} = ")
        json.dump(obj, f, ensure_ascii=False, separators=(",", ":"))
        f.write(";\n")
    print(f"[OK] {path}")


def main():
    os.makedirs(DATA_DIR, exist_ok=True)
    data = build_from_hive()
    write_js("dashboard_data.js", "DASHBOARD_DATA", data)

    # 同时输出 JSON，供后端接口 /api/dashboard 直接返回
    json_path = os.path.join(DATA_DIR, "dashboard_data.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[OK] {json_path}")

    geo_path = os.path.join(STATIC_DIR, "china.json")

    if os.path.exists(geo_path):
        with open(geo_path, encoding="utf-8") as f:
            geo = json.load(f)
        write_js("china_geo.js", "CHINA_GEO", geo)
    print("[DONE] 大屏数据已生成")


if __name__ == "__main__":
    main()
