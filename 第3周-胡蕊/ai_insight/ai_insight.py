# -*- coding: utf-8 -*-
"""
第3周 子任务5：AI 智能洞察与报告生成
====================================
功能：
  1. 基于 KPI 数据，调用大模型实现异常归因（如某日 GMV 突降原因分析）
  2. 生成自动化经营分析摘要（自动报告）
  3. 对 AI 生成内容进行审慎验证
依赖：pip install python-dotenv openai pandas
运行：python ai_insight.py
"""
import os
import json
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("DEEPSEEK_API_KEY")
BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_kpi_data() -> dict:
    """加载 KPI 数据（优先从 Hive 查询结果，否则使用内置示例）"""
    # 实际使用时从 ydsh_ads.ads_core_kpi / dws_sales_1d 查询
    # 此处使用基于第2周与预测脚本的代表性数据
    return {
        "core_kpi": {
            "period": "2024全年",
            "gmv": 661000000,        # 6.61亿元
            "order_cnt": 15000,
            "user_cnt": 8900,
            "aov": 4406.67,
            "repurchase_rate": 0.312,
        },
        "daily_anomaly": {
            "date": "2024-07-15",
            "gmv": 520000,
            "ma_7": 1850000,
            "drop_rate": -0.719,
            "context": "7月15日GMV仅52万元，较7日均值185万元下降71.9%",
        },
        "monthly_trend": {
            "peak_month": "2024-11",
            "peak_gmv": 111473916.62,
            "low_month": "2024-02",
            "low_gmv": 30600328.89,
        },
    }


def call_llm(prompt: str) -> str:
    if not API_KEY or "your-" in API_KEY:
        return _mock_llm_response(prompt)
    from openai import OpenAI
    client = OpenAI(api_key=API_KEY, base_url=BASE_URL)
    resp = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.3,
        max_tokens=800,
    )
    return resp.choices[0].message.content


def _mock_llm_response(prompt: str) -> str:
    """无 API Key 时的模拟响应（供演示）"""
    if "归因" in prompt or "突降" in prompt or "异常" in prompt:
        return (
            "【异常归因分析】针对2024-07-15 GMV突降71.9%的可能原因：\n"
            "1. 外部因素：7月中旬为传统消费淡季，且该日为周一，工作日消费力弱于周末；\n"
            "2. 供给因素：部分门店可能进行盘点或系统维护，导致线下渠道订单下降；\n"
            "3. 竞争因素：竞品可能在同期开展促销活动，分流了用户需求；\n"
            "4. 数据因素：需核实该日数据是否完整加载，是否存在ETL延迟或分区缺失。\n"
            "建议：交叉核对门店维度与渠道维度的日销售明细，定位具体下滑来源。"
        )
    if "经营分析" in prompt or "摘要" in prompt:
        return (
            "【2024年度经营分析摘要】\n"
            "全年GMV约6.61亿元，订单量1.5万单，客单价约4407元，复购率31.2%。\n"
            "1. 销售节奏：11月双11为全年峰值（1.11亿元），2月受春节影响为低谷（3060万元）；\n"
            "2. 渠道结构：APP渠道贡献最大，小程序增长迅速；\n"
            "3. 用户运营：复购率31.2%处于行业中等水平，重要价值用户贡献了主要GMV；\n"
            "4. 风险提示：大促集中度高，平日销售仍有提升空间；用户流失率需关注。"
        )
    return "（模拟响应）请配置有效的 API Key 以获取真实 AI 洞察。"


def anomaly_attribution(data: dict) -> str:
    """异常归因：分析 GMV 突降原因"""
    anomaly = data["daily_anomaly"]
    prompt = f"""你是零售行业数据分析师。请对以下销售异常进行归因分析：
异常日期：{anomaly['date']}
当日GMV：{anomaly['gmv']:,}元
7日均值GMV：{anomaly['ma_7']:,}元
降幅：{anomaly['drop_rate']*100:.1f}%
背景：{anomaly['context']}
请从外部环境、供给、竞争、数据质量四个维度分析可能原因，并给出验证建议。"""
    return call_llm(prompt)


def generate_business_summary(data: dict) -> str:
    """生成自动化经营分析摘要"""
    kpi = data["core_kpi"]
    trend = data["monthly_trend"]
    prompt = f"""你是零售行业经营分析师。基于以下KPI数据，生成一份经营分析摘要：
- 统计周期：{kpi['period']}
- GMV：{kpi['gmv']:,}元
- 订单量：{kpi['order_cnt']:,}单
- 客单价：{kpi['aov']}元
- 复购率：{kpi['repurchase_rate']*100:.1f}%
- 峰值月份：{trend['peak_month']}（GMV {trend['peak_gmv']:,.0f}元）
- 低谷月份：{trend['low_month']}（GMV {trend['low_gmv']:,.0f}元）
请从销售节奏、渠道结构、用户运营、风险提示四个维度撰写摘要，控制在400字以内。"""
    return call_llm(prompt)


def main():
    print("=" * 60)
    print("AI 智能洞察与报告生成")
    print("=" * 60)
    data = load_kpi_data()

    print("\n--- 1. 异常归因分析 ---")
    anomaly_result = anomaly_attribution(data)
    print(anomaly_result)

    print("\n--- 2. 经营分析摘要 ---")
    summary_result = generate_business_summary(data)
    print(summary_result)

    print("\n--- 3. AI 内容审慎验证说明 ---")
    print("上述 AI 生成内容需人工验证：")
    print("  - 异常归因需核对门店/渠道明细数据，确认具体下滑来源")
    print("  - 经营摘要的KPI数值需与 ads_core_kpi 表交叉核对")
    print("  - AI 可能产生幻觉（如编造不存在的门店或活动），需事实核查")

    # 保存结果
    os.makedirs("output", exist_ok=True)
    with open("output/ai_insight_result.json", "w", encoding="utf-8") as f:
        json.dump({
            "anomaly_attribution": anomaly_result,
            "business_summary": summary_result,
        }, f, ensure_ascii=False, indent=2)
    print("\n[OK] 洞察结果已保存至 output/ai_insight_result.json")


if __name__ == "__main__":
    main()
