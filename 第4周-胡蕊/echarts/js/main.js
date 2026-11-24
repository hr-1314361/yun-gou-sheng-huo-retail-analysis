/* ============================================================
   云购生活数据大屏 · 交互脚本
   图表：折线(趋势) / 地图(区域) / 柱状(品类) / 热力(时段×品类) / 散点(相关性)
   联动：点击地图省份 / 品类柱 / 月份点 / 散点气泡，其余图表按同一过滤条件重算
   数据：DATA.cube 三维立方体（月份 × 省份 × 品类），由 gen_data.py 用 IPF 生成
   自适应：1920×1080 设计稿 + transform: scale 等比缩放
   ============================================================ */
(function () {
  "use strict";

  /**
   * 数据加载策略：
   *   默认：读取 data/dashboard_data.js（window.DASHBOARD_DATA），file:// 直接双击即可演示；
   *   接口模式：地址加 ?api=1，则请求后端 JSON 接口 GET /api/dashboard，
   *             失败时自动回退到本地数据文件。
   */
  function boot(DATA) {
  /* ---------------- 主题色 ---------------- */
  var C = {
    cyan: "#22d3ee",
    blue: "#3b82f6",
    sky: "#38bdf8",
    gold: "#fbbf24",
    green: "#34d399",
    purple: "#a78bfa",
    axis: "rgba(140, 180, 230, 0.42)",
    label: "#9dbbdd",
    split: "rgba(90, 140, 200, 0.12)"
  };
  var FONT = "Microsoft YaHei, PingFang SC, Arial";
  var charts = [];

  /* ---------------- 维度与联动状态 ---------------- */
  var CUBE = DATA.cube || null;
  var MONTHS = CUBE ? CUBE.months : DATA.trend.map(function (d) { return d.month; });
  var PROVS = CUBE ? CUBE.provinces : DATA.regions.map(function (d) { return d.province; });
  var CATS = CUBE ? CUBE.categories : DATA.categories.map(function (d) { return d.category; });
  var HEAT_X = DATA.heatmap.x;
  var HEAT_Y = DATA.heatmap.y;
  var HEAT_BASE = DATA.heatmap.data;
  var PRICE = {};
  DATA.categories.forEach(function (c) { PRICE[c.category] = c.price; });

  // F：当前筛选条件；null / 空数组表示该维度不筛选
  var F = { months: [], province: null, category: null };
  var touched = false; // 用户一旦交互，停止地图轮播

  /* ---------------- 工具函数 ---------------- */
  function fmtNum(v, digits) {
    return Number(v).toLocaleString("zh-CN", {
      minimumFractionDigits: digits || 0,
      maximumFractionDigits: digits || 0
    });
  }
  function toYi(v) { return +(v / 1e8).toFixed(2); }
  function zeros(n) { var a = []; for (var i = 0; i < n; i++) a.push(0); return a; }

  function baseTooltip(extra) {
    var t = {
      backgroundColor: "rgba(6, 20, 42, 0.94)",
      borderColor: "rgba(56, 189, 248, 0.45)",
      borderWidth: 1,
      padding: [10, 14],
      textStyle: { color: "#dbeafe", fontSize: 12, fontFamily: FONT },
      extraCssText: "box-shadow:0 6px 24px rgba(0,0,0,.45);border-radius:4px;"
    };
    for (var k in extra) { t[k] = extra[k]; }
    return t;
  }

  /* ---------------- 聚合：按当前筛选条件汇总立方体 ---------------- */
  // useMonth/useProv/useCat 控制是否应用该维度筛选；
  // 例如柱状图按品类分组，就应用月份+省份筛选、忽略品类筛选。
  function agg(useMonth, useProv, useCat) {
    var o = {
      gmv: 0, order: 0,
      byMonth: zeros(MONTHS.length), byMonthOrder: zeros(MONTHS.length),
      byProv: zeros(PROVS.length), byProvOrder: zeros(PROVS.length),
      byCat: zeros(CATS.length), byCatOrder: zeros(CATS.length)
    };

    if (!CUBE) {
      // 兜底：无立方体（旧数据文件）时退回原始汇总，图表仍可展示，但不支持联动
      o.gmv = DATA.kpi.gmv;
      o.order = DATA.kpi.order_cnt;
      DATA.trend.forEach(function (t, i) { o.byMonth[i] = t.gmv; o.byMonthOrder[i] = t.order_cnt; });
      DATA.regions.forEach(function (r) {
        var i = PROVS.indexOf(r.province);
        if (i >= 0) { o.byProv[i] = r.gmv; o.byProvOrder[i] = r.order_cnt; }
      });
      DATA.categories.forEach(function (c) {
        var i = CATS.indexOf(c.category);
        if (i >= 0) { o.byCat[i] = c.gmv; o.byCatOrder[i] = c.order_cnt; }
      });
      return o;
    }

    var ms = useMonth ? F.months : [];
    var cells = CUBE.cells;
    for (var k = 0; k < cells.length; k++) {
      var c = cells[k];
      if (ms.length && ms.indexOf(c[0]) < 0) continue;
      if (useProv && F.province !== null && c[1] !== F.province) continue;
      if (useCat && F.category !== null && c[2] !== F.category) continue;
      o.gmv += c[3];
      o.order += c[4];
      o.byMonth[c[0]] += c[3]; o.byMonthOrder[c[0]] += c[4];
      o.byProv[c[1]] += c[3]; o.byProvOrder[c[1]] += c[4];
      o.byCat[c[2]] += c[3]; o.byCatOrder[c[2]] += c[4];
    }
    return o;
  }

  function scopeText() {
    var parts = [];
    if (F.months.length) {
      parts.push(F.months.slice().sort(function (a, b) { return a - b; })
        .map(function (i) { return MONTHS[i].slice(5) + "月"; }).join("、"));
    }
    if (F.province !== null) parts.push(PROVS[F.province]);
    if (F.category !== null) parts.push(CATS[F.category]);
    return parts.length ? parts.join(" · ") : "全量";
  }

  /* ---------------- 1. KPI 卡片 ---------------- */
  var kpiDefs = [
    { label: "成交总额 GMV", value: DATA.kpi.gmv, unit: "亿元", div: 1e8, digits: 2, sub: "同比 <span class='up'>+" + (DATA.kpi.gmv_yoy * 100).toFixed(1) + "%</span>" },
    { label: "订单量", value: DATA.kpi.order_cnt, unit: "单", div: 1, digits: 0, sub: "同比 <span class='up'>+" + (DATA.kpi.order_yoy * 100).toFixed(1) + "%</span>" },
    { label: "下单用户数", value: DATA.kpi.user_cnt, unit: "人", div: 1, digits: 0, sub: "同比 <span class='up'>+" + (DATA.kpi.user_yoy * 100).toFixed(1) + "%</span>" },
    { label: "客单价", value: DATA.kpi.aov, unit: "元", div: 1, digits: 2, sub: "GMV / 订单量" },
    { label: "复购率", value: DATA.kpi.repurchase_rate * 100, unit: "%", div: 1, digits: 1, sub: "复购用户 / 下单用户" },
    { label: "在售品类", value: DATA.categories.length, unit: "类", div: 1, digits: 0, sub: "Top10 贡献 <span class='up'>" + (DATA.topn.reduce(function (s, x) { return s + x.gmv_share; }, 0) * 100).toFixed(1) + "%</span>" }
  ];

  var kpiRow = document.getElementById("kpiRow");
  var kpiCards = [];
  kpiDefs.forEach(function (d) {
    var el = document.createElement("div");
    el.className = "kpi-card";
    el.innerHTML =
      '<div class="kpi-label">' + d.label + "</div>" +
      '<div class="kpi-value"><span class="num" data-cur="0">0</span><span class="unit">' + d.unit + "</span></div>" +
      '<div class="kpi-sub">' + d.sub + "</div>";
    kpiRow.appendChild(el);
    kpiCards.push({
      valueEl: el.querySelector(".num"),
      subEl: el.querySelector(".kpi-sub"),
      digits: d.digits,
      origSub: d.sub
    });
  });

  function animateNum(node, to, digits) {
    var from = parseFloat(node.getAttribute("data-cur") || "0");
    node.setAttribute("data-cur", to);
    if (!isFinite(from)) from = 0;
    var start = null, dur = 700;
    function step(ts) {
      if (!start) start = ts;
      var p = Math.min((ts - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      node.textContent = fmtNum(from + (to - from) * eased, digits);
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  function updateKpi(scope, ca) {
    var active = F.months.length > 0 || F.province !== null || F.category !== null;
    var pct = DATA.kpi.gmv ? (scope.gmv / DATA.kpi.gmv * 100) : 0;

    animateNum(kpiCards[0].valueEl, scope.gmv / 1e8, 2);
    animateNum(kpiCards[1].valueEl, scope.order, 0);
    animateNum(kpiCards[2].valueEl, DATA.kpi.user_cnt, 0);          // 用户数仅全量口径
    animateNum(kpiCards[3].valueEl, scope.order ? scope.gmv / scope.order : 0, 2);
    animateNum(kpiCards[4].valueEl, DATA.kpi.repurchase_rate * 100, 1); // 复购率仅全量口径

    var catCount = 0;
    for (var i = 0; i < ca.byCat.length; i++) if (ca.byCat[i] > 0) catCount++;
    if (F.category !== null) catCount = 1;
    animateNum(kpiCards[5].valueEl, catCount, 0);

    kpiCards[0].subEl.innerHTML = active
      ? "占全量 <span class='up'>" + pct.toFixed(1) + "%</span>" : kpiCards[0].origSub;
    kpiCards[1].subEl.innerHTML = active
      ? "占全量 <span class='up'>" + pct.toFixed(1) + "%</span>" : kpiCards[1].origSub;
    kpiCards[2].subEl.innerHTML = active ? "全量口径 · 不随筛选" : kpiCards[2].origSub;
    kpiCards[3].subEl.innerHTML = kpiCards[3].origSub;
    kpiCards[4].subEl.innerHTML = active ? "全量口径 · 不随筛选" : kpiCards[4].origSub;
    kpiCards[5].subEl.innerHTML = active ? "当前筛选范围" : kpiCards[5].origSub;
  }

  /* ---------------- 2. 舞台等比缩放 ---------------- */
  var stage = document.getElementById("stage");
  function resizeStage() {
    var w = window.innerWidth;
    var h = window.innerHeight;
    var scale = Math.min(w / 1920, h / 1080);
    stage.style.transform = "translate(-50%, -50%) scale(" + scale + ")";
    charts.forEach(function (c) { c.resize(); });
  }
  window.addEventListener("resize", function () {
    clearTimeout(window.__rz);
    window.__rz = setTimeout(resizeStage, 120);
  });

  /* ---------------- 3. 时钟 ---------------- */
  function tickClock() {
    var now = new Date();
    var pad = function (n) { return n < 10 ? "0" + n : "" + n; };
    document.getElementById("clock").textContent =
      pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":" + pad(now.getSeconds());
  }
  setInterval(tickClock, 1000);
  tickClock();
  document.getElementById("updated").textContent = "更新时间：" + DATA.meta.updated;

  /* ---------------- 4. 注册地图 ---------------- */
  if (window.CHINA_GEO) {
    echarts.registerMap("china", window.CHINA_GEO);
  }

  /* ---------------- 5. 销售趋势折线（12 个月，受省份/品类筛选影响） ---------------- */
  var trendChart = echarts.init(document.getElementById("chartTrend"));
  charts.push(trendChart);

  function trendOption(ta) {
    var sel = F.months;
    var gmvData = [], ordData = [];
    for (var i = 0; i < MONTHS.length; i++) {
      var on = sel.length === 0 || sel.indexOf(i) >= 0;
      gmvData.push({
        value: toYi(ta.byMonth[i]),
        symbolSize: on ? 7 : 4,
        itemStyle: {
          color: sel.length && !on ? "rgba(34,211,238,.55)" : (sel.indexOf(i) >= 0 ? C.gold : C.cyan),
          borderColor: "#0b2038", borderWidth: 1,
          opacity: on ? 1 : 0.4
        }
      });
      ordData.push({ value: ta.byMonthOrder[i], itemStyle: { opacity: on ? 0.9 : 0.3 } });
    }

    return {
      grid: { left: 58, right: 58, top: 46, bottom: 34 },
      tooltip: baseTooltip({
        trigger: "axis",
        axisPointer: { type: "line", lineStyle: { color: "rgba(34,211,238,.6)" } },
        formatter: function (ps) {
          var i = ps[0].dataIndex;
          var g = ta.byMonth[i], o = ta.byMonthOrder[i];
          return "<b style='color:#7dd3fc'>" + MONTHS[i] + "</b><br/>" +
            "GMV：<b style='color:#fbbf24'>" + toYi(g) + " 亿元</b><br/>" +
            "订单量：<b>" + fmtNum(o) + " 单</b><br/>" +
            "客单价：<b>" + fmtNum(g / (o || 1), 2) + " 元</b>";
        }
      }),
      legend: {
        top: 8, right: 24, itemWidth: 14, itemHeight: 8,
        textStyle: { color: C.label, fontSize: 12, fontFamily: FONT },
        data: ["GMV", "订单量"]
      },
      xAxis: {
        type: "category",
        boundaryGap: false,
        data: MONTHS.map(function (m) { return m.slice(5) + "月"; }),
        axisLine: { lineStyle: { color: C.axis } },
        axisTick: { show: false },
        axisLabel: { color: C.label, fontSize: 12, fontFamily: FONT }
      },
      yAxis: [
        {
          type: "value", name: "亿元", nameTextStyle: { color: C.label, fontSize: 11 },
          axisLabel: { color: C.label, fontSize: 11 },
          splitLine: { lineStyle: { color: C.split } },
          axisLine: { show: false }
        },
        {
          type: "value", name: "单", nameTextStyle: { color: C.label, fontSize: 11 },
          axisLabel: { color: C.label, fontSize: 11 },
          splitLine: { show: false },
          axisLine: { show: false }
        }
      ],
      series: [
        {
          name: "GMV", type: "line", smooth: true, symbol: "circle", yAxisIndex: 0,
          triggerLineEvent: true, // 整条折线可点击，避免只能点中 7px 的圆点
          data: gmvData,
          lineStyle: { width: 2.6, color: C.cyan, shadowColor: "rgba(34,211,238,.6)", shadowBlur: 12 },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: "rgba(34,211,238,.42)" },
              { offset: 1, color: "rgba(34,211,238,0)" }
            ])
          },
          markPoint: {
            symbolSize: 44,
            label: { color: "#04121f", fontSize: 10, fontWeight: "bold" },
            itemStyle: { color: C.gold },
            data: [{ type: "max", name: "峰值" }]
          }
        },
        {
          name: "订单量", type: "line", smooth: true, symbol: "none", yAxisIndex: 1,
          data: ordData,
          lineStyle: { width: 1.6, color: C.gold, type: "dashed", opacity: 0.9 },
          itemStyle: { color: C.gold }
        }
      ]
    };
  }

  /* ---------------- 6. 区域地图（受月份/品类筛选影响，点击省份联动） ---------------- */
  var mapChart = echarts.init(document.getElementById("chartMap"));
  charts.push(mapChart);

  function mapOption(pa) {
    var maxRegion = 0;
    pa.byProv.forEach(function (v) { if (v > maxRegion) maxRegion = v; });
    var data = PROVS.map(function (name, i) {
      return {
        name: name,
        value: +pa.byProv[i].toFixed(2),
        order_cnt: pa.byProvOrder[i]
      };
    });

    return {
      tooltip: baseTooltip({
        formatter: function (p) {
          if (!p.data) return p.name + "<br/>暂无成交";
          var r = p.data;
          return "<b style='color:#7dd3fc'>" + r.name + "</b><br/>" +
            "GMV：<b style='color:#fbbf24'>" + toYi(r.value) + " 亿元</b><br/>" +
            "订单量：<b>" + fmtNum(r.order_cnt) + " 单</b>" +
            (F.province === null ? "<br/><span style='color:#7f9cc4'>点击可筛选该省</span>" : "");
        }
      }),
      visualMap: {
        type: "continuous", min: 0, max: maxRegion || 1,
        left: 14, bottom: 12, itemWidth: 10, itemHeight: 74,
        calculable: false,
        text: ["高", "低"],
        textStyle: { color: C.label, fontSize: 10 },
        inRange: { color: ["#0d2a52", "#17538f", "#1e88c7", "#22d3ee", "#fbbf24"] }
      },
      series: [{
        type: "map", map: "china", roam: false, zoom: 1.18,
        layoutCenter: ["54%", "52%"], layoutSize: "108%",
        selectedMode: "single",
        label: { show: false },
        itemStyle: {
          areaColor: "#0f2b4f",
          borderColor: "rgba(90,170,240,.55)",
          borderWidth: 0.8,
          shadowColor: "rgba(15,80,150,.55)",
          shadowBlur: 12
        },
        emphasis: {
          label: { show: true, color: "#ffffff", fontSize: 11 },
          itemStyle: { areaColor: "#2f9fe0", borderColor: "#eaf6ff" }
        },
        select: {
          label: { show: true, color: "#3a2a00", fontSize: 11 },
          itemStyle: { areaColor: "#fbbf24", borderColor: "#fff7e0", borderWidth: 1.6 }
        },
        data: data
      }]
    };
  }

  /* ---------------- 7. 品类柱状（受月份/省份筛选影响，点击品类联动） ---------------- */
  var barChart = echarts.init(document.getElementById("chartBar"));
  charts.push(barChart);

  function barOption(ca) {
    var arr = CATS.map(function (name, i) {
      return { ci: i, name: name, gmv: ca.byCat[i], order: ca.byCatOrder[i] };
    }).filter(function (x) { return x.gmv > 0; })
      .sort(function (a, b) { return a.gmv - b.gmv; });

    var sel = F.category;
    return {
      grid: { left: 12, right: 46, top: 18, bottom: 26, containLabel: true },
      tooltip: baseTooltip({
        trigger: "axis",
        axisPointer: { type: "shadow", shadowStyle: { color: "rgba(56,189,248,.08)" } },
        formatter: function (ps) {
          var d = ps[0].data.__raw;
          return "<b style='color:#7dd3fc'>" + d.name + "</b><br/>" +
            "GMV：<b style='color:#fbbf24'>" + toYi(d.gmv) + " 亿元</b><br/>" +
            "订单量：<b>" + fmtNum(d.order) + " 单</b><br/>" +
            (sel === null ? "<span style='color:#7f9cc4'>点击可筛选该品类</span>" : "");
        }
      }),
      xAxis: {
        type: "value",
        axisLabel: { color: C.label, fontSize: 10 },
        splitLine: { lineStyle: { color: C.split } },
        axisLine: { show: false }
      },
      yAxis: {
        type: "category",
        data: arr.map(function (d) { return d.name; }),
        axisLabel: { color: C.label, fontSize: 11 },
        axisLine: { lineStyle: { color: C.axis } },
        axisTick: { show: false }
      },
      series: [{
        type: "bar",
        barWidth: 11,
        data: arr.map(function (d) {
          var on = sel === null || sel === d.ci;
          return {
            value: toYi(d.gmv),
            __raw: d,
            itemStyle: {
              borderRadius: [0, 6, 6, 0],
              opacity: on ? 1 : 0.28,
              color: sel === d.ci
                ? new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                    { offset: 0, color: "rgba(251,191,36,.45)" },
                    { offset: 1, color: "#fbbf24" }
                  ])
                : new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                    { offset: 0, color: "rgba(59,130,246,.35)" },
                    { offset: 1, color: "#22d3ee" }
                  ])
            }
          };
        }),
        label: {
          show: true, position: "right",
          color: "#cfe8ff", fontSize: 10,
          formatter: function (p) { return p.value.toFixed(2); }
        }
      }]
    };
  }

  /* ---------------- 8. 时段 × 品类热力图（受全部筛选影响） ---------------- */
  var heatChart = echarts.init(document.getElementById("chartHeat"));
  charts.push(heatChart);

  function heatOption(scope) {
    // 以筛选范围 GMV 占全量的比例缩放热力值（时段分布按稳定处理）
    var factor = DATA.kpi.gmv ? scope.gmv / DATA.kpi.gmv : 1;
    var xiSel = F.category !== null ? HEAT_X.indexOf(CATS[F.category]) : -1;

    var data = [];
    HEAT_BASE.forEach(function (d) {
      if (xiSel >= 0 && d[0] !== xiSel) return;
      data.push([d[0], d[1], +(d[2] * factor).toFixed(2)]);
    });

    var vals = data.map(function (d) { return d[2]; });
    var minV = vals.length ? Math.min.apply(null, vals) : 0;
    var maxV = vals.length ? Math.max.apply(null, vals) : 1;

    return {
      grid: { left: 62, right: 18, top: 14, bottom: 64 },
      tooltip: baseTooltip({
        formatter: function (p) {
          return "<b style='color:#7dd3fc'>" + HEAT_Y[p.value[1]] + " 时</b><br/>" +
            HEAT_X[p.value[0]] + "：<b style='color:#fbbf24'>" + p.value[2] + " 万元</b>";
        }
      }),
      xAxis: {
        type: "category",
        data: HEAT_X,
        splitArea: { show: false },
        axisLabel: { color: C.label, fontSize: 10, interval: 0, rotate: 28 },
        axisLine: { lineStyle: { color: C.axis } },
        axisTick: { show: false }
      },
      yAxis: {
        type: "category",
        data: HEAT_Y,
        axisLabel: { color: C.label, fontSize: 10 },
        axisLine: { lineStyle: { color: C.axis } },
        axisTick: { show: false }
      },
      visualMap: {
        min: minV, max: maxV,
        orient: "horizontal", left: "center", bottom: 4,
        itemWidth: 10, itemHeight: 70,
        textStyle: { color: C.label, fontSize: 10 },
        inRange: { color: ["#0b2340", "#124a7a", "#1789c4", "#22d3ee", "#fbbf24"] }
      },
      series: [{
        type: "heatmap",
        data: data,
        label: { show: false },
        itemStyle: { borderColor: "rgba(4,12,26,.85)", borderWidth: 1 },
        emphasis: {
          itemStyle: { shadowBlur: 10, shadowColor: "rgba(34,211,238,.7)" }
        }
      }]
    };
  }

  /* ---------------- 9. 客单价 × 销量散点（受月份/省份筛选影响，点击气泡联动） ---------------- */
  var scatterChart = echarts.init(document.getElementById("chartScatter"));
  charts.push(scatterChart);

  function scatterOption(ca) {
    var sel = F.category;
    var data = CATS.map(function (name, i) {
      var g = ca.byCat[i], o = ca.byCatOrder[i] || 1;
      return {
        name: name,
        ci: i,
        gmv: g,
        value: [+(g / o).toFixed(0), Math.round(g / (PRICE[name] || 100)), +(g / 1e8).toFixed(2)]
      };
    }).filter(function (d) { return d.gmv > 0; })
      .map(function (d) {
        var on = sel === null || sel === d.ci;
        return {
          name: d.name,
          ci: d.ci,
          gmv: d.gmv,
          value: d.value,
          symbolSize: sel === d.ci ? 34 : Math.max(13, Math.min(30, Math.sqrt(d.value[2]) * 26)),
          itemStyle: sel === d.ci
            ? { color: C.gold, shadowBlur: 20, shadowColor: "rgba(251,191,36,.8)", opacity: 1 }
            : {
                color: new echarts.graphic.RadialGradient(0.4, 0.35, 0.9, [
                  { offset: 0, color: "rgba(251,191,36,.95)" },
                  { offset: 0.6, color: "rgba(34,211,238,.75)" },
                  { offset: 1, color: "rgba(59,130,246,.25)" }
                ]),
                shadowBlur: 14,
                shadowColor: "rgba(34,211,238,.45)",
                opacity: on ? 1 : 0.3
              }
        };
      });

    return {
      grid: { left: 52, right: 16, top: 30, bottom: 42 },
      tooltip: baseTooltip({
        formatter: function (p) {
          return "<b style='color:#7dd3fc'>" + p.data.name + "</b><br/>" +
            "客单价：<b>" + fmtNum(p.value[0], 0) + " 元</b><br/>" +
            "销量：<b>" + fmtNum(p.value[1]) + " 件</b><br/>" +
            "GMV：<b style='color:#fbbf24'>" + p.value[2] + " 亿元</b>" +
            (sel === null ? "<br/><span style='color:#7f9cc4'>点击可筛选该品类</span>" : "");
        }
      }),
      xAxis: {
        type: "value", name: "客单价(元)", nameLocation: "middle", nameGap: 26,
        nameTextStyle: { color: C.label, fontSize: 10 },
        axisLabel: { color: C.label, fontSize: 10 },
        splitLine: { lineStyle: { color: C.split } },
        axisLine: { lineStyle: { color: C.axis } }
      },
      yAxis: {
        type: "value", name: "销量(件)", nameTextStyle: { color: C.label, fontSize: 10 },
        axisLabel: { color: C.label, fontSize: 10 },
        splitLine: { lineStyle: { color: C.split } },
        axisLine: { show: false }
      },
      series: [{
        type: "scatter",
        data: data,
        label: {
          show: true, position: "top", color: "#a9c8e8", fontSize: 10,
          formatter: function (p) { return p.data.name; }
        },
        emphasis: { scale: 1.15 }
      }]
    };
  }

  /* ---------------- 10. 筛选栏与联动 ---------------- */
  var filterBar = document.getElementById("filterBar");

  function renderFilterBar() {
    if (!filterBar) return;
    var html = '<span class="hd-chip">ENTERPRISE DW</span>';
    var active = false;

    if (F.months.length) {
      active = true;
      var label = F.months.length > 2
        ? F.months.length + " 个月"
        : F.months.slice().sort(function (a, b) { return a - b; })
            .map(function (i) { return MONTHS[i].slice(5) + "月"; }).join("、");
      html += '<span class="filter-chip" data-k="month">' + label + "<i>×</i></span>";
    }
    if (F.province !== null) {
      active = true;
      html += '<span class="filter-chip" data-k="province">' + PROVS[F.province] + "<i>×</i></span>";
    }
    if (F.category !== null) {
      active = true;
      html += '<span class="filter-chip" data-k="category">' + CATS[F.category] + "<i>×</i></span>";
    }

    html += active
      ? '<button class="filter-reset" id="resetFilter">重置</button>'
      : '<span class="filter-hint">点击地图 / 柱状 / 月度点 / 气泡联动</span>';

    filterBar.innerHTML = html;
  }

  if (filterBar) {
    filterBar.addEventListener("click", function (e) {
      var node = e.target;
      while (node && node !== filterBar && !(node.className && String(node.className).indexOf("filter-chip") >= 0)) {
        node = node.parentNode;
      }
      if (node && node !== filterBar && node.getAttribute) {
        var k = node.getAttribute("data-k");
        if (k === "month") F.months = [];
        else if (k === "province") F.province = null;
        else if (k === "category") F.category = null;
        touched = true;
        applyFilter();
        return;
      }
      if (e.target && e.target.id === "resetFilter") resetFilter();
    });
  }

  function resetFilter() {
    F.months = [];
    F.province = null;
    F.category = null;
    touched = true;
    applyFilter();
  }

  function updateFooter(scope) {
    var el = document.getElementById("period");
    if (!el) return;
    if (scopeText() === "全量") {
      el.textContent = "统计周期：" + DATA.meta.period;
    } else {
      el.textContent = "筛选：" + scopeText() +
        "｜GMV " + toYi(scope.gmv) + " 亿 · 订单 " + fmtNum(scope.order) + " 单";
    }
  }

  function applyFilter() {
    var scope = agg(1, 1, 1); // 全部筛选，用于 KPI / 热力 / 页脚
    var ta = agg(0, 1, 1);    // 折线：按月份分组，应用省份+品类筛选
    var pa = agg(1, 0, 1);    // 地图：按省份分组，应用月份+品类筛选
    var ca = agg(1, 1, 0);    // 柱/散点：按品类分组，应用月份+省份筛选

    trendChart.setOption(trendOption(ta), true);
    mapChart.setOption(mapOption(pa), true);
    barChart.setOption(barOption(ca), true);
    heatChart.setOption(heatOption(scope), true);
    scatterChart.setOption(scatterOption(ca), true);

    // 地图选中态与筛选同步
    mapChart.dispatchAction({ type: "unselect", seriesIndex: 0 });
    if (F.province !== null) {
      mapChart.dispatchAction({ type: "select", seriesIndex: 0, name: PROVS[F.province] });
    }

    updateKpi(scope, ca);
    renderFilterBar();
    updateFooter(scope);
  }

  // 点击交互：再次点击同一项取消筛选
  trendChart.on("click", function (p) {
    if (p.componentType !== "series") return;
    touched = true;
    var i = p.dataIndex, k = F.months.indexOf(i);
    if (k >= 0) F.months.splice(k, 1); else F.months.push(i);
    applyFilter();
  });

  mapChart.on("click", function (p) {
    var i = PROVS.indexOf(p.name);
    if (i < 0) return;
    touched = true;
    F.province = F.province === i ? null : i;
    applyFilter();
  });

  barChart.on("click", function (p) {
    if (!p.data || !p.data.__raw) return;
    touched = true;
    var ci = p.data.__raw.ci;
    F.category = F.category === ci ? null : ci;
    applyFilter();
  });

  scatterChart.on("click", function (p) {
    if (!p.data || p.data.ci === undefined) return;
    touched = true;
    F.category = F.category === p.data.ci ? null : p.data.ci;
    applyFilter();
  });

  heatChart.on("click", function (p) {
    if (!p.value) return;
    var ci = CATS.indexOf(HEAT_X[p.value[0]]);
    if (ci < 0) return;
    touched = true;
    F.category = F.category === ci ? null : ci;
    applyFilter();
  });

  /* ---------------- 11. 启动 ---------------- */
  resizeStage();
  applyFilter();

  // 演示模式：未交互时每 5 秒轮播高亮地图省份，便于答辩讲解
  var mapIdx = 0;
  setInterval(function () {
    if (touched || !PROVS.length) return;
    mapIdx = (mapIdx + 1) % PROVS.length;
    mapChart.dispatchAction({ type: "downplay", seriesIndex: 0 });
    mapChart.dispatchAction({
      type: "highlight", seriesIndex: 0,
      name: PROVS[mapIdx]
    });
  }, 5000);

  window.__SCREEN__ = {
    charts: charts,
    data: DATA,
    filter: F,
    applyFilter: applyFilter,
    resetFilter: resetFilter
  };
  }  // end boot()

  /* ---------------- 启动 ---------------- */
  function start() {
    var useApi = /[?&]api=1/.test(location.search) &&
                 location.protocol.indexOf("http") === 0;
    if (useApi && window.fetch) {
      fetch("api/dashboard")
        .then(function (r) {
          if (!r.ok) throw new Error("HTTP " + r.status);
          return r.json();
        })
        .then(boot)
        .catch(function (e) {
          console.warn("[大屏] 接口不可用，回退本地数据文件：", e.message);
          boot(window.DASHBOARD_DATA);
        });
      return;
    }
    if (!window.DASHBOARD_DATA) {
      document.body.innerHTML =
        '<div style="color:#f87171;font:16px/1.8 Microsoft YaHei;padding:40px">' +
        "未找到 data/dashboard_data.js，请先执行 python gen_data.py 生成数据。</div>";
      return;
    }
    boot(window.DASHBOARD_DATA);
  }

  start();
})();
