# -*- coding: utf-8 -*-
"""
第4周 子任务3：查询结果 → ECharts 图表渲染
============================================
功能：
  1. 根据查询结果的列类型/列名自动推断图表类型（折线/柱状/饼图）；
  2. 生成自包含 HTML（内联本地 echarts.min.js），通过 streamlit.components.v1.html 渲染，
     离线可用，不依赖 CDN。
"""
import json
import os
import re
from functools import lru_cache

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ECHARTS_CANDIDATES = [
    os.getenv("ECHARTS_JS", ""),
    os.path.join(BASE_DIR, "..", "echarts", "static", "echarts.min.js"),
    os.path.join(BASE_DIR, "static", "echarts.min.js"),
]

DATE_LIKE = re.compile(r"^\d{4}([-/]?\d{2}){0,2}$")


@lru_cache(maxsize=1)
def load_echarts_js() -> str:
    for path in ECHARTS_CANDIDATES:
        if not path:
            continue
        p = os.path.abspath(path)
        if os.path.isfile(p):
            with open(p, encoding="utf-8") as f:
                return f.read()
    return ""


def _is_number(v) -> bool:
    try:
        float(v)
        return True
    except (TypeError, ValueError):
        return False


def infer_option(columns, rows) -> dict:
    """根据结果集推断图表配置；无法推断时返回空 dict"""
    if not columns or not rows:
        return {}

    first = rows[0]
    numeric_idx = [i for i, v in enumerate(first) if _is_number(v)]
    dim_idx = [i for i in range(len(columns)) if i not in numeric_idx]
    if not numeric_idx:
        return {}
    if not dim_idx:
        # 全数值：按行号做 x 轴
        dim_idx = [0]
        x_data = [str(i + 1) for i in range(len(rows))]
    else:
        x_data = [str(r[dim_idx[0]]) for r in rows]

    dim_name = columns[dim_idx[0]] if dim_idx else "序号"
    metric_idx = numeric_idx[0]
    metric_name = columns[metric_idx]

    x_looks_date = bool(DATE_LIKE.match(str(x_data[0]))) or \
        any(k in dim_name.lower() for k in ("date", "month", "day", "week"))

    # 饼图：维度基数小 + 结果中含占比/率类度量
    metric_names = [columns[i] for i in numeric_idx]
    share_flag = any(
        any(k in c.lower() for k in ("share", "rate", "ratio"))
        or any(k in c for k in ("占比", "比例", "率"))
        for c in metric_names
    )
    chart_type = "bar"
    if x_looks_date:
        chart_type = "line"
    elif len(rows) <= 8 and share_flag:
        chart_type = "pie"

    colors = ["#22d3ee", "#3b82f6", "#fbbf24", "#a78bfa", "#34d399",
              "#f472b6", "#fb923c", "#60a5fa", "#2dd4bf"]
    base = {
        "backgroundColor": "transparent",
        "color": colors,
        "tooltip": {"trigger": "axis" if chart_type != "pie" else "item"},
        "grid": {"left": 56, "right": 28, "top": 40, "bottom": 44},
    }
    axis_style = {
        "axisLine": {"lineStyle": {"color": "rgba(120,165,215,.45)"}},
        "axisLabel": {"color": "#9dbbdd", "fontSize": 11},
        "splitLine": {"lineStyle": {"color": "rgba(90,140,200,.12)"}},
    }

    if chart_type == "pie":
        data = [{"name": str(r[dim_idx[0]]),
                 "value": float(r[metric_idx])} for r in rows]
        return {
            "backgroundColor": "transparent",
            "color": colors,
            "tooltip": {"trigger": "item"},
            "legend": {"bottom": 0, "textStyle": {"color": "#9dbbdd"}},
            "series": [{
                "type": "pie", "radius": ["42%", "68%"], "center": ["50%", "44%"],
                "data": data,
                "label": {"color": "#dbeafe", "formatter": "{b}\n{d}%"},
                "itemStyle": {"borderColor": "#061127", "borderWidth": 2},
            }],
        }

    metrics = numeric_idx[:2]
    series = []
    for i, mi in enumerate(metrics):
        series.append({
            "name": columns[mi],
            "type": chart_type,
            "smooth": True if chart_type == "line" else None,
            "symbol": "circle" if chart_type == "line" else None,
            "symbolSize": 6 if chart_type == "line" else None,
            "barMaxWidth": 26 if chart_type == "bar" else None,
            "yAxisIndex": i,
            "data": [float(r[mi]) if _is_number(r[mi]) else 0 for r in rows],
            "areaStyle": ({"opacity": 0.16} if chart_type == "line" and i == 0 else None),
            "lineStyle": {"width": 2.4} if chart_type == "line" else None,
            "itemStyle": {"borderRadius": [4, 4, 0, 0]} if chart_type == "bar" else None,
        })

    # 双度量时需要双 Y 轴，否则 series 的 yAxisIndex 会越界导致图表无法渲染
    y_axis = [{"type": "value", **axis_style}]
    if len(metrics) > 1:
        y_axis.append({"type": "value", **axis_style})

    return {
        **base,
        "legend": {"top": 8, "right": 16, "textStyle": {"color": "#9dbbdd"}},
        "xAxis": {"type": "category", "data": x_data, **axis_style},
        "yAxis": y_axis if len(y_axis) > 1 else y_axis[0],
        "series": series,
    }


def chart_type_name(columns, rows) -> str:
    opt = infer_option(columns, rows)
    if not opt:
        return ""
    t = opt["series"][0]["type"]
    return {"line": "折线图", "bar": "柱状图", "pie": "饼图"}.get(t, t)


def render_html(option: dict, height: int = 360) -> str:
    """生成自包含 HTML；本地 echarts 不存在时回退 CDN"""
    echarts_js = load_echarts_js()
    if echarts_js:
        script = f"<script>{echarts_js}</script>"
    else:
        script = '<script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"></script>'

    option_json = json.dumps(option, ensure_ascii=False)
    return f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<style>
  html,body{{margin:0;padding:0;width:100%;height:100%;overflow:hidden;
    background:transparent;font-family:"Microsoft YaHei",Arial,sans-serif;}}
  #c{{width:100%;height:{height}px;min-width:320px;}}
</style></head>
<body>
<div id="c"></div>
{script}
<script>
  (function(){{
    var el = document.getElementById('c');
    var option = {option_json};
    var chart = null;

    function draw(){{
      if (chart) {{ chart.dispose(); }}
      // iframe 初始宽度可能为 0，显式给一个兜底宽度，避免 ECharts 初始化失败
      var w = el.clientWidth || document.documentElement.clientWidth || 800;
      chart = echarts.init(el, null, {{ width: w, height: {height} }});
      chart.setOption(option);
      window.__chart = chart;
    }}

    function boot(){{
      draw();
      if (window.ResizeObserver) {{
        var ro = new ResizeObserver(function(){{
          if (!chart) return;
          if (el.clientWidth > 0) {{ chart.resize(); }}
        }});
        ro.observe(el);
      }}
      window.addEventListener('resize', function(){{ if (chart) chart.resize(); }});
      // Streamlit iframe 尺寸在挂载后还会变化，延迟再校正两次
      setTimeout(function(){{ if (chart) chart.resize(); }}, 200);
      setTimeout(function(){{ if (chart) chart.resize(); }}, 800);
    }}

    if (document.readyState === 'loading') {{
      document.addEventListener('DOMContentLoaded', boot);
    }} else {{
      boot();
    }}
  }})();
</script>
</body></html>"""
