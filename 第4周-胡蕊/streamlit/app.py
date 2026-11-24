# -*- coding: utf-8 -*-
"""
第4周 子任务3：Streamlit 对话式数据问答
=========================================
闭环：用户提问 → 大模型生成 SQL → Hive 执行 → 表格 + ECharts 图表渲染
体验：历史对话、加载状态、错误提示、示例问题、结果下载、后端状态检测

启动：
    streamlit run app.py
"""
import os
import socket
import time

import pandas as pd
import streamlit as st
from streamlit.components.v1 import html as st_html

from chart_render import chart_type_name, infer_option, render_html
from nl2sql_engine import NL2SQLEngine, sample_questions

st.set_page_config(
    page_title="云购生活 · 智能问数",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ---------------- 自定义样式 ----------------
st.markdown(
    """
<style>
  .block-container { padding-top: 1.6rem; max-width: 1180px; }
  .app-header {
    display:flex; align-items:flex-end; justify-content:space-between;
    padding: 18px 22px; margin-bottom: 14px; border-radius: 10px;
    background: linear-gradient(120deg, #0b1f3a 0%, #123a6b 55%, #0e6d8f 100%);
    border: 1px solid rgba(56,189,248,.28);
  }
  .app-header h1 { color:#eaf4ff; font-size: 24px; margin:0; letter-spacing:1px; }
  .app-header p  { color:#9fc4e8; font-size: 12px; margin:6px 0 0; letter-spacing:.5px; }
  .pill {
    display:inline-block; padding:3px 10px; margin-left:8px; border-radius:999px;
    font-size:12px; border:1px solid rgba(125,211,252,.35); color:#7dd3fc;
    background:rgba(14,116,144,.18);
  }
  .pill.ok   { color:#34d399; border-color:rgba(52,211,153,.4); background:rgba(6,78,59,.22); }
  .pill.warn { color:#fbbf24; border-color:rgba(251,191,36,.4); background:rgba(120,53,15,.2); }
  .meta { color:#6b8cb0; font-size:12px; margin: 2px 0 8px; }
  .sql-tag {
    display:inline-block; font-size:11px; padding:1px 8px; border-radius:4px;
    color:#7dd3fc; background:rgba(14,116,144,.25); margin-right:8px;
  }
</style>
""",
    unsafe_allow_html=True,
)


# ---------------- 后端状态 ----------------
@st.cache_resource(show_spinner=False)
def get_engine() -> NL2SQLEngine:
    return NL2SQLEngine()


def probe_hive(host: str, port: int, timeout: float = 1.5) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


engine = get_engine()
if "hive_ok" not in st.session_state:
    st.session_state.hive_ok = probe_hive(
        os.getenv("HIVE_HOST", "localhost"), int(os.getenv("HIVE_PORT", "10000"))
    )
if "messages" not in st.session_state:
    st.session_state.messages = []

# ---------------- 顶部标题 ----------------
llm_cls = "ok" if engine.llm_ready else "warn"
llm_txt = "大模型已连接" if engine.llm_ready else "大模型未配置（演示模式）"
hive_cls = "ok" if st.session_state.hive_ok else "warn"
hive_txt = "Hive 在线" if st.session_state.hive_ok else "Hive 离线（演示数据）"

st.markdown(
    f"""
<div class="app-header">
  <div>
    <h1>云购生活 · 智能问数</h1>
    <p>自然语言 → SQL → Hive 执行 → 图表可视化 · 基于第 3 周 NL2SQL 能力</p>
  </div>
  <div>
    <span class="pill {llm_cls}">{llm_txt}</span>
    <span class="pill {hive_cls}">{hive_txt}</span>
  </div>
</div>
""",
    unsafe_allow_html=True,
)


# ---------------- 侧边栏 ----------------
with st.sidebar:
    st.subheader("示例问题")
    for i, q in enumerate(sample_questions()):
        if st.button(q, key=f"sample_{i}", use_container_width=True):
            st.session_state.pending = q
            st.rerun()

    st.divider()
    st.subheader("查询设置")
    show_chart = st.toggle("结果自动可视化", value=True)
    show_sql = st.toggle("显示生成的 SQL", value=True)

    st.divider()
    col1, col2 = st.columns(2)
    with col1:
        if st.button("清空对话", use_container_width=True):
            st.session_state.messages = []
            st.rerun()
    with col2:
        if st.button("重测连接", use_container_width=True):
            st.session_state.hive_ok = probe_hive(
                os.getenv("HIVE_HOST", "localhost"),
                int(os.getenv("HIVE_PORT", "10000")),
            )
            st.rerun()

    st.divider()
    with st.expander("可查询的数据表"):
        st.markdown(
            "- `ydsh_ads.ads_sales_daily` 销售日报\n"
            "- `ydsh_ads.ads_category_topn` 品类 TopN\n"
            "- `ydsh_ads.ads_region_sales` 区域销售\n"
            "- `ydsh_ads.ads_pay_type_daily` 支付方式\n"
            "- `ydsh_ads.ads_core_kpi` 核心 KPI\n"
            "- `ydsh_dws.dws_sales_1m` 月度汇总"
        )


# ---------------- 消息渲染 ----------------
def render_assistant(msg: dict):
    if msg.get("error"):
        if "演示" in msg["error"] or "未配置" in msg["error"]:
            st.warning(msg["error"])
        else:
            st.error(msg["error"])

    if show_sql and msg.get("sql"):
        st.markdown('<span class="sql-tag">SQL</span>', unsafe_allow_html=True)
        st.code(msg["sql"], language="sql")

    cols, rows = msg.get("columns") or [], msg.get("rows") or []
    source = msg.get("source", "demo")
    source_txt = {
        "llm+hive": "大模型 + Hive 实时查询",
        "llm+demo": "大模型生成 SQL + 演示结果",
        "demo": "本地演示数据",
    }.get(source, source)

    if cols:
        df = pd.DataFrame(rows, columns=cols)
        st.markdown(
            f'<div class="meta">数据来源：{source_txt} · 返回 {len(df)} 行 · '
            f'耗时 {msg.get("elapsed", 0):.2f}s</div>',
            unsafe_allow_html=True,
        )
        st.dataframe(df, use_container_width=True, height=min(320, 38 * (len(df) + 1)))

        if show_chart:
            option = infer_option(cols, rows)
            if option:
                st.markdown(
                    f'<div class="meta">自动图表：{chart_type_name(cols, rows)}</div>',
                    unsafe_allow_html=True,
                )
                st_html(render_html(option, height=360), height=380)

        st.download_button(
            "下载结果 CSV",
            df.to_csv(index=False).encode("utf-8-sig"),
            file_name=f"query_result_{int(time.time())}.csv",
            mime="text/csv",
            key=f"dl_{msg.get('id', time.time())}",
        )
    elif not msg.get("error"):
        st.info("查询成功，但结果为空。请调整问题或时间范围后重试。")


def render_history():
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            if msg["role"] == "user":
                st.markdown(msg["content"])
            else:
                render_assistant(msg)


render_history()

if not st.session_state.messages:
    st.info(
        "直接在下方输入业务问题，例如：**2024 年 11 月的 GMV 和订单量是多少？**\n\n"
        "系统将自动生成 Hive SQL、执行查询，并把结果渲染为表格与图表。"
    )

# ---------------- 输入与处理 ----------------
prompt = st.chat_input("输入你的业务问题，例如：各支付方式的 GMV 占比")
if st.session_state.get("pending"):
    prompt = st.session_state.pop("pending")

if prompt:
    user_msg = {"role": "user", "content": prompt}
    st.session_state.messages.append(user_msg)
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        with st.spinner("正在生成 SQL 并执行查询..."):
            result = engine.ask(prompt)
        assistant_msg = {
            "role": "assistant",
            "id": int(time.time() * 1000),
            **result,
        }
        st.session_state.messages.append(assistant_msg)
        render_assistant(assistant_msg)
