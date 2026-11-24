# -*- coding: utf-8 -*-
"""生成第3周周志"""
from docx import Document
from docx.shared import Pt

doc = Document()
style = doc.styles["Normal"]
style.font.name = "宋体"
style.font.size = Pt(11)

def P(text, bold=False):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.bold = bold

P("企业项目实训周志", bold=True)
P("姓名：胡蕊    实训项目：云购生活新零售企业数据分析")
P("第三周（2026年11月9日—11月13日）")

P("本周围绕数据分析、预测建模与AI协同展开。首先完成数据仓库DWS汇总层与ADS应用层建设：DWS层设计7张汇总表，按天/周/月时间维度与品类/门店/渠道业务维度汇总GMV、订单量、用户数、客单价等度量，其中日粒度表按stat_date分区支持增量刷新，周/月表全量重算；ADS层设计5张应用表，包括销售日报（含同比环比）、品类销售TopN、用户价值分层（RFM模型八档标签）、核心KPI总表（GMV/订单量/客单价/活跃用户/复购率/品类占比）与复购率日趋势，形成完整的指标计算链路。DWS开发中解决了Hive 4.0不支持SUM(SUM()) OVER()嵌套窗口函数的问题，改为子查询先算日总GMV再JOIN计算占比。随后开展时间序列分析与预测建模：从Hive读取每日GMV序列，完成趋势分解（乘法模型、周期7）、7日/30日移动平均、月度环比分析；构造滞后特征（lag_1/7/14/30）、滚动统计与周期编码（sin/cos）共15个特征，对比线性回归与XGBoost两种模型，以最后14天为测试集评估，线性回归表现最优（MAE=85749.76元，MAPE=4.35%），并对未来7天GMV进行递归预测。在AI协同方面，接入DeepSeek大模型API，采用.env文件管理密钥避免硬编码；构建NL2SQL链路，自动抽取Hive表Schema生成元信息，基于LangChain以LCEL编排Prompt→LLM→SQL解析→Hive执行的完整闭环，设计含Schema约束与示例的系统提示词，测试了「广东省上月销售额」「销量最高前5品类」等7个典型问题；基于KPI数据调用大模型实现GMV突降异常归因（从外部/供给/竞争/数据质量四维度分析）与自动化经营分析摘要生成。最后实践Git团队协同：采用Fork工作流，完成PR与Code Review（2位评审人共5条意见，含1条严重问题已修复）、Issue追踪（4个Issue）、真实合并冲突解决（两分支修改同一日志文件，手动按日期合并），并打v0.3.0-week3版本标签。")

P("本周收获：掌握了DWS汇总层与ADS应用层的设计方法，理解了从明细事实到轻度汇总再到业务应用的分层思路；学会了时间序列预测的完整流程，包括特征工程、模型对比评估、递归预测及模型适用边界的批判性审视；理解了NL2SQL的核心要素——Schema抽取、Prompt设计与SQL校验，以及大模型API接入的密钥安全管理规范；实践了Git Fork工作流、PR/Code Review、Issue追踪与合并冲突解决的团队协作全流程，形成了可追溯的协同留痕。")

out = r"d:\xmsx\第三周周志_胡蕊.docx"
doc.save(out)
print(f"[OK] {out}")
