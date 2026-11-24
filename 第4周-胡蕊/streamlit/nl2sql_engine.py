# -*- coding: utf-8 -*-
"""
第4周 子任务3：Streamlit 对话问答的 NL2SQL 引擎
================================================
职责：自然语言问题 → 生成 SQL → 执行 Hive → 返回结构化结果。
设计：
  1. 复用第 3 周 nl2sql 的链路（Schema + Prompt + DeepSeek），改为可被 UI 调用的类；
  2. 三级降级，保证答辩现场任何一步不可用都能演示：
       ① 大模型可用 + Hive 可用 → 真实闭环
       ② 大模型可用 + Hive 不可用 → 展示 SQL，返回演示结果并标注「演示数据」
       ③ 均不可用 → 本地示例问答，仍展示完整「问题→SQL→结果」流程
依赖：pip install openai python-dotenv pyhive pandas
"""
import os
import re
import time

try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:  # pragma: no cover
    pass

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROMPT_FILE = os.path.join(BASE_DIR, "prompt_template.txt")

API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
MODEL = os.getenv("LLM_MODEL", "deepseek-chat")
HIVE_HOST = os.getenv("HIVE_HOST", "localhost")
HIVE_PORT = int(os.getenv("HIVE_PORT", "10000"))
HIVE_USER = os.getenv("HIVE_USER", "hive")

SCHEMA_TEXT = """
# 数据库表结构（只读 ADS / DWS 层）
## ydsh_ads.ads_sales_daily(stat_date STRING 统计日期, gmv DOUBLE 成交总额, order_cnt BIGINT 订单量,
   user_cnt BIGINT 下单用户数, aov DOUBLE 客单价, avg_per_user DOUBLE 人均消费, item_cnt BIGINT 商品件数,
   gmv_yoy DOUBLE 同比, gmv_mom DOUBLE 环比)
## ydsh_ads.ads_category_topn(stat_date STRING, category STRING 品类, gmv DOUBLE, order_cnt BIGINT,
   user_cnt BIGINT, gmv_share DOUBLE 占比, rank_no INT 排名)
## ydsh_ads.ads_region_sales(stat_date STRING, province STRING 省份, gmv DOUBLE, order_cnt BIGINT,
   user_cnt BIGINT, store_cnt BIGINT, gmv_share DOUBLE)
## ydsh_ads.ads_pay_type_daily(stat_date STRING, pay_type STRING 支付方式, gmv DOUBLE, order_cnt BIGINT,
   user_cnt BIGINT, aov DOUBLE, gmv_share DOUBLE)
## ydsh_ads.ads_core_kpi(stat_period STRING 统计周期, gmv DOUBLE, order_cnt BIGINT, user_cnt BIGINT,
   aov DOUBLE, repurchase_rate DOUBLE 复购率, active_user_cnt BIGINT)
## ydsh_ads.ads_repurchase_daily(stat_date STRING, order_user_cnt BIGINT, repurchase_user_cnt BIGINT,
   repurchase_rate DOUBLE)
## ydsh_dws.dws_sales_1m(month_key STRING 月份, gmv DOUBLE, order_cnt BIGINT, user_cnt BIGINT,
   aov DOUBLE, mom_gmv DOUBLE 环比)
## ydsh_dwd.dwd_order(order_id STRING, user_id STRING, store_id STRING, product_id STRING,
   quantity INT, unit_price DOUBLE, amount DOUBLE, pay_type STRING, order_status STRING,
   channel STRING, order_date STRING 分区)
## ydsh_dwd.dim_store(store_id STRING, store_name STRING, province STRING, city STRING)
## ydsh_dwd.dim_product(product_id STRING, product_name STRING, category STRING, sub_category STRING,
   brand STRING, price DOUBLE)
"""

DEFAULT_PROMPT = """你是资深 Hive SQL 工程师。请根据下方表结构，将用户问题转换为一条可执行的 Hive SQL。
要求：
1. 只输出 SQL，不要解释，不要 Markdown 代码块；
2. 只使用 SELECT，禁止 INSERT/UPDATE/DELETE/DROP；
3. 优先查询 ydsh_ads 结果表，必要时才查 dws/dwd；
4. 字符串条件加引号，度量加别名，结果按业务含义排序，默认 LIMIT 100。

{schema}

用户问题：{question}
SQL："""


# ------------------------------------------------------------
# 本地演示问答（无大模型/无 Hive 时的兜底，保证闭环可演示）
# ------------------------------------------------------------
DEMO_CASES = [
    {
        "keywords": ["11月", "gmv", "订单"],
        "sql": "SELECT stat_date, gmv, order_cnt, aov\nFROM ydsh_ads.ads_sales_daily\n"
               "WHERE substr(stat_date, 1, 7) = '2024-11'\nORDER BY stat_date",
        "columns": ["stat_date", "gmv", "order_cnt", "aov"],
        "rows": [["2024-11-11", 21860000.0, 486, 44979.42],
                 ["2024-11-12", 12430000.0, 279, 44551.97],
                 ["2024-11-18", 9860000.0, 221, 44615.38],
                 ["2024-11-25", 7420000.0, 168, 44166.67],
                 ["2024-11-30", 5810000.0, 133, 43684.21]],
    },
    {
        "keywords": ["品类", "前5", "top5", "排名"],
        "sql": "SELECT rank_no, category, gmv, gmv_share, order_cnt\n"
               "FROM ydsh_ads.ads_category_topn\n"
               "WHERE rank_no <= 5\nORDER BY rank_no",
        "columns": ["rank_no", "category", "gmv", "gmv_share", "order_cnt"],
        "rows": [[1, "运动户外", 118980000.0, 0.180, 2700],
                 [2, "家用电器", 105760000.0, 0.160, 2400],
                 [3, "食品生鲜", 92540000.0, 0.140, 2100],
                 [4, "美妆个护", 79320000.0, 0.120, 1800],
                 [5, "服饰鞋包", 72710000.0, 0.110, 1650]],
    },
    {
        "keywords": ["支付方式", "占比", "支付"],
        "sql": "SELECT pay_type, SUM(gmv) AS gmv, SUM(gmv) / SUM(SUM(gmv)) OVER () AS gmv_share\n"
               "FROM ydsh_ads.ads_pay_type_daily\nGROUP BY pay_type\nORDER BY gmv DESC",
        "columns": ["pay_type", "gmv", "gmv_share"],
        "rows": [["支付宝", 277620000.0, 0.42],
                 ["微信支付", 251180000.0, 0.38],
                 ["银行卡", 79320000.0, 0.12],
                 ["货到付款", 52880000.0, 0.08]],
    },
    {
        "keywords": ["区域", "省份", "地区", "省"],
        "sql": "SELECT province, SUM(gmv) AS gmv, SUM(order_cnt) AS order_cnt\n"
               "FROM ydsh_ads.ads_region_sales\nGROUP BY province\nORDER BY gmv DESC\nLIMIT 10",
        "columns": ["province", "gmv", "order_cnt"],
        "rows": [["广东省", 117658000.0, 2670],
                 ["江苏省", 74032000.0, 1680],
                 ["浙江省", 71388000.0, 1620],
                 ["山东省", 58168000.0, 1320],
                 ["河南省", 46270000.0, 1050],
                 ["四川省", 43626000.0, 990],
                 ["湖北省", 38338000.0, 870],
                 ["湖南省", 34372000.0, 780],
                 ["河北省", 31728000.0, 720],
                 ["福建省", 30406000.0, 690]],
    },
    {
        "keywords": ["复购", "留存"],
        "sql": "SELECT stat_period, repurchase_rate\nFROM ydsh_ads.ads_core_kpi",
        "columns": ["stat_period", "repurchase_rate"],
        "rows": [["2024全年", 0.312], ["2024-Q4", 0.338], ["2024-Q3", 0.315]],
    },
    {
        "keywords": ["趋势", "每月", "月度", "全年"],
        "sql": "SELECT month_key, gmv, order_cnt, aov\nFROM ydsh_dws.dws_sales_1m\nORDER BY month_key",
        "columns": ["month_key", "gmv", "order_cnt", "aov"],
        "rows": [["2024-01", 46270000.0, 1050, 44066.67],
                 ["2024-02", 36355000.0, 825, 44066.67],
                 ["2024-03", 46270000.0, 1050, 44066.67],
                 ["2024-04", 47592000.0, 1080, 44066.67],
                 ["2024-05", 51558000.0, 1170, 44066.67],
                 ["2024-06", 54202000.0, 1230, 44066.67],
                 ["2024-07", 52880000.0, 1200, 44066.67],
                 ["2024-08", 51558000.0, 1170, 44066.67],
                 ["2024-09", 52880000.0, 1200, 44066.67],
                 ["2024-10", 58168000.0, 1320, 44066.67],
                 ["2024-11", 95845000.0, 2175, 44066.67],
                 ["2024-12", 67422000.0, 1530, 44066.67]],
    },
]

FALLBACK_CASE = {
    "sql": "SELECT stat_period, gmv, order_cnt, user_cnt, aov, repurchase_rate\nFROM ydsh_ads.ads_core_kpi",
    "columns": ["stat_period", "gmv", "order_cnt", "user_cnt", "aov", "repurchase_rate"],
    "rows": [["2024全年", 661000000.0, 15000, 8932, 44066.67, 0.312]],
}


def clean_sql(text: str) -> str:
    sql = (text or "").strip()
    sql = re.sub(r"^```(?:sql)?\s*", "", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\s*```$", "", sql)
    return sql.strip().rstrip(";").strip()


def is_safe_sql(sql: str) -> bool:
    """只允许单条 SELECT 查询"""
    s = sql.strip().lower()
    if not s.startswith("select"):
        return False
    banned = ["insert ", "update ", "delete ", "drop ", "alter ", "truncate ", "create "]
    return not any(b in s for b in banned)


class NL2SQLEngine:
    def __init__(self):
        self.api_key = API_KEY
        self.llm_ready = bool(self.api_key) and "your-" not in self.api_key
        self.hive_ready = False
        self.last_error = ""

    # ---------------- 大模型生成 SQL ----------------
    def generate_sql(self, question: str) -> str:
        if not self.llm_ready:
            raise RuntimeError("未配置 DEEPSEEK_API_KEY")
        from openai import OpenAI
        client = OpenAI(api_key=self.api_key, base_url=BASE_URL)
        template = DEFAULT_PROMPT
        if os.path.exists(PROMPT_FILE):
            with open(PROMPT_FILE, encoding="utf-8") as f:
                template = f.read()
        prompt = template.replace("{schema}", SCHEMA_TEXT).replace("{question}", question)
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0,
            max_tokens=600,
        )
        return clean_sql(resp.choices[0].message.content)

    # ---------------- 执行 Hive ----------------
    def execute(self, sql: str):
        from pyhive import hive
        conn = hive.Connection(host=HIVE_HOST, port=HIVE_PORT, username=HIVE_USER,
                               auth="NOSASL")
        try:
            cur = conn.cursor()
            cur.execute(sql)
            cols = [d[0].split(".")[-1] for d in cur.description] if cur.description else []
            rows = [list(r) for r in cur.fetchall()]
            return cols, rows
        finally:
            conn.close()

    # ---------------- 演示数据 ----------------
    @staticmethod
    def demo_answer(question: str):
        for case in DEMO_CASES:
            if any(k.lower() in question.lower() for k in case["keywords"]):
                return case["sql"], case["columns"], case["rows"]
        return FALLBACK_CASE["sql"], FALLBACK_CASE["columns"], FALLBACK_CASE["rows"]

    # ---------------- 统一入口 ----------------
    def ask(self, question: str) -> dict:
        """
        返回：{sql, columns, rows, elapsed, source, error}
        source: llm+hive / llm+demo / demo
        """
        t0 = time.time()
        result = {"sql": "", "columns": [], "rows": [], "elapsed": 0.0,
                  "source": "demo", "error": ""}

        # 1) 生成 SQL
        if self.llm_ready:
            try:
                sql = self.generate_sql(question)
                if not is_safe_sql(sql):
                    raise RuntimeError("生成结果不是安全的 SELECT 语句，已拦截")
                result["sql"] = sql
            except Exception as e:
                result["error"] = f"SQL 生成失败：{e}"
                sql, cols, rows = self.demo_answer(question)
                result.update(sql=sql, columns=cols, rows=rows, source="demo",
                              elapsed=round(time.time() - t0, 3))
                result["error"] += "（已切换为演示数据）"
                return result
        else:
            sql, cols, rows = self.demo_answer(question)
            result.update(sql=sql, columns=cols, rows=rows, source="demo",
                          elapsed=round(time.time() - t0, 3))
            result["error"] = "未配置大模型密钥，当前为演示模式"
            return result

        # 2) 执行 SQL
        try:
            cols, rows = self.execute(sql)
            result.update(columns=cols, rows=rows, source="llm+hive")
        except Exception as e:
            # Hive 不可用：保留 SQL，返回演示结果
            _, cols, rows = self.demo_answer(question)
            result.update(columns=cols, rows=rows, source="llm+demo")
            result["error"] = f"Hive 执行失败：{e}（结果为演示数据）"

        result["elapsed"] = round(time.time() - t0, 3)
        return result


def sample_questions():
    return [
        "2024 年 11 月的 GMV 和订单量是多少？",
        "销量最高的前 5 个品类",
        "各支付方式的 GMV 占比",
        "GMV 排名前 10 的省份",
        "2024 年复购率是多少？",
        "2024 年每月的销售趋势",
    ]
