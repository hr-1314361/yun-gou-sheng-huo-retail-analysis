# -*- coding: utf-8 -*-
"""生成《预测建模分析报告》docx"""
import pandas as pd
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

base = r"d:\xmsx\第3周-胡蕊\python\output"
monthly = pd.read_csv(base + r"\monthly_sales.csv")
eval_df = pd.read_csv(base + r"\model_evaluation.csv")
pred_df = pd.read_csv(base + r"\next_7days_prediction.csv")

doc = Document()
style = doc.styles["Normal"]
style.font.name = "宋体"
style.font.size = Pt(11)

def add_heading(text, level=1):
    h = doc.add_heading(text, level=level)
    for run in h.runs:
        run.font.name = "黑体"
    return h

def add_para(text, bold=False):
    p = doc.add_paragraph()
    run = p.add_run(text)
    run.bold = bold
    return p

add_heading("云购生活新零售——预测建模分析报告", level=0)
add_para("第3周 子任务2：时间序列分析与预测建模")
add_para(f"生成日期：2026-11-10")

# 1. 分析背景
add_heading("一、分析背景与数据来源", level=1)
add_para("本报告基于云购生活新零售企业2024全年日粒度销售数据，对GMV（成交总额）进行时间序列分析与预测建模。"
         "数据源自数仓DWS层 dws_sales_1d 日汇总表，包含每日GMV、订单量、下单用户数、客单价等指标。"
         "分析目标为：识别销售趋势与季节性规律，构建预测模型对未来7天GMV进行预测，并评估模型效果与适用边界。")

# 2. 描述性分析
add_heading("二、描述性分析", level=1)
add_para("1. 数据区间：2024-01-01 至 2024-12-31，共366天（闰年）。", bold=True)
add_para("2. 全年GMV：约7.21亿元，日均GMV约197万元。")
add_para("3. 月度GMV趋势如下表：")

table = doc.add_table(rows=1, cols=3)
table.style = "Light Grid Accent 1"
hdr = table.rows[0].cells
hdr[0].text = "月份"
hdr[1].text = "GMV(元)"
hdr[2].text = "环比增长率"
for _, row in monthly.iterrows():
    cells = table.add_row().cells
    cells[0].text = str(row["month"])
    cells[1].text = f"{row['gmv']:,.2f}"
    mom = row["gmv_mom"]
    cells[2].text = "—" if pd.isna(mom) else f"{mom*100:.2f}%"

add_para("月度趋势观察：", bold=True)
add_para("• 2月GMV环比下降22.07%，主要受春节假期影响，线下门店与物流配送减少；")
add_para("• 6月GMV环比增长72.25%，618大促拉动显著；")
add_para("• 11月GMV环比增长83.61%，双11大促为全年峰值（1.11亿元）；")
add_para("• 12月GMV环比下降43.04%，大促后需求回落。")

add_para("4. 趋势分解：", bold=True)
add_para("采用乘法模型（周期=7）对GMV序列进行分解，得到趋势项、周内季节项与残差项。"
         "趋势项显示全年GMV呈缓慢上升态势；周内季节项显示周末GMV显著高于工作日（约1.25倍）；"
         "残差项在618、双11等大促节点出现正向异常。")

add_para("5. 移动平均：", bold=True)
add_para("7日移动平均平滑了周内波动，30日移动平均更清晰地呈现月度趋势与大促峰值。")

# 3. 模型构建
add_heading("三、预测模型构建", level=1)
add_para("1. 特征工程：", bold=True)
add_para("构造以下特征用于建模：")
add_para("• 时间趋势特征：t（时间序号）、weekday、month、dayofyear、is_weekend；")
add_para("• 滞后特征：lag_1、lag_7、lag_14、lag_30（昨日、上周、两周前、一月前GMV）；")
add_para("• 滚动统计：roll_mean_7、roll_std_7（7日滚动均值与标准差）；")
add_para("• 周期编码：weekday/月 的 sin/cos 编码，捕捉周期性。")

add_para("2. 模型选择：", bold=True)
add_para("对比两种模型：线性回归（LinearRegression）与 XGBoost 回归。")
add_para("• 线性回归：假设GMV与特征呈线性关系，可解释性强；")
add_para("• XGBoost：梯度提升树，能捕捉非线性关系，但小样本下易过拟合。")

add_para("3. 训练/测试划分：", bold=True)
add_para("以最后14天作为测试集，其余为训练集，评估模型对近期数据的预测能力。")

# 4. 模型评估
add_heading("四、模型评估", level=1)
add_para("评估指标：MAE（平均绝对误差）与 MAPE（平均绝对百分比误差）。")

table2 = doc.add_table(rows=1, cols=3)
table2.style = "Light Grid Accent 1"
hdr2 = table2.rows[0].cells
hdr2[0].text = "模型"
hdr2[1].text = "MAE(元)"
hdr2[2].text = "MAPE(%)"
for _, row in eval_df.iterrows():
    cells = table2.add_row().cells
    cells[0].text = row["model"]
    cells[1].text = f"{row['mae']:,.2f}"
    cells[2].text = f"{row['mape_pct']:.2f}"

add_para("结论：线性回归模型表现更优，MAE=85,749.76元，MAPE=4.35%，"
         "优于XGBoost（MAPE=4.88%）。在366天的小样本场景下，线性回归的泛化能力更强，"
         "XGBoost存在一定过拟合。因此选择线性回归作为最终预测模型。")

# 5. 未来7天预测
add_heading("五、未来7天GMV预测", level=1)
add_para("基于最优模型（线性回归），对2025-01-01至2025-01-07的GMV进行递归预测：")

table3 = doc.add_table(rows=1, cols=2)
table3.style = "Light Grid Accent 1"
hdr3 = table3.rows[0].cells
hdr3[0].text = "日期"
hdr3[1].text = "预测GMV(元)"
for _, row in pred_df.iterrows():
    cells = table3.add_row().cells
    cells[0].text = str(row["date"])
    cells[1].text = f"{row['pred_gmv']:,.2f}"

add_para("预测观察：", bold=True)
add_para("• 2025-01-01至01-05预测GMV呈上升趋势（180万→229万），周末效应明显；")
add_para("• 2025-01-06、01-07为工作日，预测GMV回落至167万左右；")
add_para("• 整体预测值处于合理区间，与2024年1月日均水平（约127万）相比略有增长，符合全年缓慢上升趋势。")

# 6. 模型适用边界
add_heading("六、预测模型适用边界与批判性审视", level=1)
add_para("1. 外部变量缺失：", bold=True)
add_para("模型仅基于历史GMV序列，未纳入营销活动、节假日、天气、经济环境等外部变量。"
         "在618、双11等大促期间，实际GMV会远超模型预测，误差被放大。")

add_para("2. 线性假设局限：", bold=True)
add_para("线性回归假设GMV与特征呈线性关系，对非线性拐点（如突发疫情、政策变化）捕捉能力不足。"
         "当业务环境发生结构性变化时，模型预测会失效。")

add_para("3. 小样本过拟合风险：", bold=True)
add_para("XGBoost在366天样本上易过拟合，递归预测时误差会逐日累积。"
         "未来7天预测中，后期预测值的不确定性显著高于前期。")

add_para("4. 季节性置信度有限：", bold=True)
add_para("数据仅覆盖2024单年，无法计算同比（YoY），年度季节性的分解置信度有限。"
         "若需准确捕捉年度季节性，至少需要2-3年数据。")

add_para("5. 因果推断局限：", bold=True)
add_para("时间序列模型本质是相关关系建模，不具备因果解释能力。"
         "模型识别的'周末GMV高'是相关而非因果，实际可能由营销活动在周末投放驱动。")

add_para("改进建议：", bold=True)
add_para("① 引入外部因子（促销日历、节假日、天气、竞品价格）构建特征增强模型；")
add_para("② 采用多模型集成（线性回归 + XGBoost + Prophet）加权预测，降低单一模型偏差；")
add_para("③ 积累2-3年数据后引入同比特征与年度季节性分解；")
add_para("④ 对大促期间单独建模或引入干预变量，提升特殊时期预测精度。")

out = r"d:\xmsx\第3周-胡蕊\预测建模分析报告.docx"
doc.save(out)
print(f"[OK] 报告已生成: {out}")
