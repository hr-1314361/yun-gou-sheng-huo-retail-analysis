# -*- coding: utf-8 -*-
"""
第3周 子任务2：时间序列分析与预测建模
========================================
功能：
  1. 从 Hive 读取每日 GMV / 订单量时间序列
  2. 趋势分解（statsmodels seasonal_decompose）、移动平均
  3. 同比/环比分析
  4. 使用 scikit-learn（线性回归 / XGBoost）构建时间序列预测模型，预测未来 7 天 GMV
  5. 评估模型效果（MAE / MAPE），输出预测建模分析报告

依赖安装：
  pip install pyhive pandas numpy scikit-learn statsmodels xgboost matplotlib python-dotenv

运行：
  python time_series_prediction.py
"""

import os
import sys
import warnings
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

# ------------------------------------------------------------
# 1. 从 Hive 读取每日 GMV / 订单量时间序列
# ------------------------------------------------------------
HIVE_HOST = os.getenv("HIVE_HOST", "localhost")
HIVE_PORT = int(os.getenv("HIVE_PORT", "10000"))
HIVE_USER = os.getenv("HIVE_USER", "root")


def load_daily_sales_from_hive():
    """从 Hive DWS 层读取每日销售时间序列"""
    try:
        from pyhive import hive
        conn = hive.Connection(host=HIVE_HOST, port=HIVE_PORT, username=HIVE_USER)
        sql = """
            SELECT stat_date, gmv, order_cnt, user_cnt, aov
            FROM ydsh_dws.dws_sales_1d
            ORDER BY stat_date
        """
        df = pd.read_sql(sql, conn)
        conn.close()
        df["stat_date"] = pd.to_datetime(df["stat_date"])
        df = df.sort_values("stat_date").reset_index(drop=True)
        print(f"[INFO] 从 Hive 读取 {len(df)} 条日销售数据，区间 {df['stat_date'].min().date()} ~ {df['stat_date'].max().date()}")
        return df
    except Exception as e:
        print(f"[WARN] Hive 连接失败({e})，使用基于历史特征的模拟数据演示预测流程")
        return _generate_mock_daily_sales()


def _generate_mock_daily_sales():
    """基于第2周已知特征（2024全年、GMV约6.61亿、15000订单）生成模拟日序列，
    含趋势、周内季节性、节假日波动与随机噪声，用于演示预测建模全流程。"""
    dates = pd.date_range("2024-01-01", "2024-12-31", freq="D")
    n = len(dates)
    t = np.arange(n)
    # 基础趋势：缓慢增长
    trend = 1_400_000 + t * 1500
    # 周内季节性：周末高
    weekday = dates.weekday
    weekly_season = np.where(weekday >= 5, 1.25, 1.0)
    # 月度季节性：6月/11月大促高
    month = dates.month
    monthly_season = np.where(month.isin([6, 11]), 1.4,
                              np.where(month.isin([1, 2]), 0.85, 1.0))
    # 节假日效应：春节(2月10日前后)、618、双11
    holiday = np.ones(n)
    for i, d in enumerate(dates):
        if abs((d - datetime(2024, 2, 10)).days) <= 7:
            holiday[i] = 0.6  # 春节低谷
        elif abs((d - datetime(2024, 6, 18)).days) <= 3:
            holiday[i] = 1.8
        elif abs((d - datetime(2024, 11, 11)).days) <= 3:
            holiday[i] = 2.2
    # 随机噪声
    np.random.seed(42)
    noise = np.random.normal(1.0, 0.08, n)
    gmv = trend * weekly_season * monthly_season * holiday * noise
    order_cnt = (gmv / 450).astype(int)  # 客单价约450元
    df = pd.DataFrame({
        "stat_date": dates,
        "gmv": np.round(gmv, 2),
        "order_cnt": order_cnt,
        "user_cnt": (order_cnt * 0.7).astype(int),
        "aov": np.round(gmv / order_cnt, 2),
    })
    print(f"[INFO] 生成模拟日销售数据 {len(df)} 条，全年GMV={df['gmv'].sum()/1e8:.2f}亿元")
    return df


# ------------------------------------------------------------
# 2. 趋势分解、移动平均、同比/环比
# ------------------------------------------------------------
def analyze_trend(df):
    """趋势分解 + 移动平均 + 环比分析"""
    from statsmodels.tsa.seasonal import seasonal_decompose

    ts = df.set_index("stat_date")["gmv"]
    # 移动平均（7天、30天）
    df["ma_7"] = ts.rolling(window=7, min_periods=1).mean().values
    df["ma_30"] = ts.rolling(window=30, min_periods=1).mean().values
    # 环比增长率
    df["gmv_mom"] = ts.pct_change(1).values
    # 月度环比
    df["month"] = df["stat_date"].dt.to_period("M").astype(str)
    monthly = df.groupby("month")["gmv"].sum().reset_index()
    monthly["gmv_mom"] = monthly["gmv"].pct_change(1)
    # 趋势分解（周期=7，周内季节性）
    try:
        decomp = seasonal_decompose(ts, model="multiplicative", period=7)
        df["trend"] = decomp.trend.values
        df["seasonal"] = decomp.seasonal.values
        df["resid"] = decomp.resid.values
    except Exception as e:
        print(f"[WARN] 趋势分解失败: {e}")
        df["trend"] = df["ma_30"]
        df["seasonal"] = 1.0
        df["resid"] = ts / df["ma_30"]
    return df, monthly


# ------------------------------------------------------------
# 3. 特征工程：构造时间序列滞后特征与日历特征
# ------------------------------------------------------------
def build_features(df):
    df = df.copy()
    df["t"] = np.arange(len(df))
    df["weekday"] = df["stat_date"].dt.weekday
    df["month"] = df["stat_date"].dt.month
    df["dayofyear"] = df["stat_date"].dt.dayofyear
    df["is_weekend"] = (df["weekday"] >= 5).astype(int)
    # 滞后特征
    for lag in [1, 7, 14, 30]:
        df[f"lag_{lag}"] = df["gmv"].shift(lag)
    # 滚动统计
    df["roll_mean_7"] = df["gmv"].rolling(7).mean()
    df["roll_std_7"] = df["gmv"].rolling(7).std()
    # 周内季节性编码（sin/cos）
    df["weekday_sin"] = np.sin(2 * np.pi * df["weekday"] / 7)
    df["weekday_cos"] = np.cos(2 * np.pi * df["weekday"] / 7)
    df["month_sin"] = np.sin(2 * np.pi * df["month"] / 12)
    df["month_cos"] = np.cos(2 * np.pi * df["month"] / 12)
    return df


# ------------------------------------------------------------
# 4. 模型训练与评估（线性回归 / XGBoost）
# ------------------------------------------------------------
FEATURE_COLS = [
    "t", "weekday", "month", "dayofyear", "is_weekend",
    "lag_1", "lag_7", "lag_14", "lag_30",
    "roll_mean_7", "roll_std_7",
    "weekday_sin", "weekday_cos", "month_sin", "month_cos",
]


def train_and_evaluate(df):
    from sklearn.linear_model import LinearRegression
    from sklearn.metrics import mean_absolute_error

    data = build_features(df).dropna(subset=FEATURE_COLS + ["gmv"]).reset_index(drop=True)
    # 训练/测试划分：最后 14 天作为测试集
    split_idx = len(data) - 14
    train = data.iloc[:split_idx]
    test = data.iloc[split_idx:]

    results = {}

    # --- 线性回归 ---
    lr = LinearRegression()
    lr.fit(train[FEATURE_COLS], train["gmv"])
    pred_lr = lr.predict(test[FEATURE_COLS])
    mae_lr = mean_absolute_error(test["gmv"], pred_lr)
    mape_lr = np.mean(np.abs((test["gmv"].values - pred_lr) / test["gmv"].values)) * 100
    results["linear_regression"] = {
        "mae": round(mae_lr, 2),
        "mape": round(mape_lr, 2),
        "pred": pred_lr,
        "actual": test["gmv"].values,
        "dates": test["stat_date"].values,
        "model": lr,
    }

    # --- XGBoost（若可用） ---
    try:
        import xgboost as xgb
        xgb_model = xgb.XGBRegressor(
            n_estimators=200, max_depth=5, learning_rate=0.05,
            subsample=0.8, colsample_bytree=0.8, random_state=42,
        )
        xgb_model.fit(train[FEATURE_COLS], train["gmv"])
        pred_xgb = xgb_model.predict(test[FEATURE_COLS])
        mae_xgb = mean_absolute_error(test["gmv"], pred_xgb)
        mape_xgb = np.mean(np.abs((test["gmv"].values - pred_xgb) / test["gmv"].values)) * 100
        results["xgboost"] = {
            "mae": round(mae_xgb, 2),
            "mape": round(mape_xgb, 2),
            "pred": pred_xgb,
            "actual": test["gmv"].values,
            "dates": test["stat_date"].values,
            "model": xgb_model,
        }
    except ImportError:
        print("[WARN] xgboost 未安装，跳过 XGBoost 模型")

    # 选择最优模型（MAPE 最小）
    best_name = min(results, key=lambda k: results[k]["mape"])
    results["best"] = best_name
    print(f"[INFO] 模型评估完成，最优模型: {best_name} (MAPE={results[best_name]['mape']}%)")
    return results, data


# ------------------------------------------------------------
# 5. 预测未来 7 天 GMV
# ------------------------------------------------------------
def predict_next_7_days(data, results):
    """使用最优模型递归预测未来 7 天 GMV"""
    best_name = results["best"]
    model = results[best_name]["model"]
    last_date = data["stat_date"].max()
    last_row = data.iloc[-1].copy()
    preds = []
    cur = last_row.copy()
    for i in range(1, 8):
        next_date = last_date + timedelta(days=i)
        feat = cur.copy()
        feat["t"] = cur["t"] + 1
        feat["weekday"] = next_date.weekday()
        feat["month"] = next_date.month
        feat["dayofyear"] = next_date.timetuple().tm_yday
        feat["is_weekend"] = int(next_date.weekday() >= 5)
        feat["lag_1"] = cur["gmv"]
        feat["lag_7"] = cur["lag_6"] if "lag_6" in feat else cur["gmv"]
        feat["lag_14"] = cur["lag_13"] if "lag_13" in feat else cur["gmv"]
        feat["lag_30"] = cur["lag_29"] if "lag_29" in feat else cur["gmv"]
        feat["weekday_sin"] = np.sin(2 * np.pi * feat["weekday"] / 7)
        feat["weekday_cos"] = np.cos(2 * np.pi * feat["weekday"] / 7)
        feat["month_sin"] = np.sin(2 * np.pi * feat["month"] / 12)
        feat["month_cos"] = np.cos(2 * np.pi * feat["month"] / 12)
        # 滚动统计近似用上一窗口
        feat["roll_mean_7"] = cur["roll_mean_7"]
        feat["roll_std_7"] = cur["roll_std_7"]
        X = pd.DataFrame([feat[FEATURE_COLS].values], columns=FEATURE_COLS)
        pred_gmv = float(model.predict(X)[0])
        preds.append({"date": next_date.strftime("%Y-%m-%d"), "pred_gmv": round(pred_gmv, 2)})
        cur["gmv"] = pred_gmv
        cur["t"] = feat["t"]
        cur["weekday"] = feat["weekday"]
        cur["month"] = feat["month"]
        cur["dayofyear"] = feat["dayofyear"]
    return preds


# ------------------------------------------------------------
# 6. 输出报告数据
# ------------------------------------------------------------
def save_report_data(df, monthly, results, preds):
    os.makedirs("output", exist_ok=True)
    # 原始日序列
    df.to_csv("output/daily_sales.csv", index=False, encoding="utf-8-sig")
    # 月度汇总
    monthly.to_csv("output/monthly_sales.csv", index=False, encoding="utf-8-sig")
    # 模型评估结果
    eval_rows = []
    for name in ["linear_regression", "xgboost"]:
        if name in results:
            r = results[name]
            eval_rows.append({
                "model": name,
                "mae": r["mae"],
                "mape_pct": r["mape"],
            })
    pd.DataFrame(eval_rows).to_csv("output/model_evaluation.csv", index=False, encoding="utf-8-sig")
    # 未来 7 天预测
    pd.DataFrame(preds).to_csv("output/next_7days_prediction.csv", index=False, encoding="utf-8-sig")
    print("[INFO] 报告数据已保存至 output/ 目录")


def main():
    print("=" * 60)
    print("第3周 子任务2：时间序列分析与预测建模")
    print("=" * 60)
    df = load_daily_sales_from_hive()
    df, monthly = analyze_trend(df)
    results, data = train_and_evaluate(df)
    preds = predict_next_7_days(data, results)
    save_report_data(df, monthly, results, preds)

    print("\n=== 模型评估 ===")
    for name in ["linear_regression", "xgboost"]:
        if name in results:
            print(f"  {name}: MAE={results[name]['mae']:.2f}, MAPE={results[name]['mape']:.2f}%")
    print(f"\n=== 未来 7 天 GMV 预测（模型: {results['best']}） ===")
    for p in preds:
        print(f"  {p['date']}: {p['pred_gmv']:,.2f} 元")

    # 预测模型适用边界说明（写入日志，供报告引用）
    print("\n=== 预测模型适用边界 ===")
    print("  1. 仅基于历史GMV序列，未纳入营销活动、节假日外部变量，大促期间误差放大")
    print("  2. 线性回归假设趋势线性，对非线性拐点捕捉不足")
    print("  3. XGBoost 在小样本(366天)上易过拟合，递归预测误差会逐日累积")
    print("  4. 数据仅覆盖2024单年，无法计算同比，季节性分解置信度有限")
    print("  5. 建议结合外部因子(促销日历、天气、经济指标)与多模型集成提升稳健性")


if __name__ == "__main__":
    main()
