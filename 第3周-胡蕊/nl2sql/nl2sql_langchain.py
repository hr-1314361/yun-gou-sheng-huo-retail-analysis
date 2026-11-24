# -*- coding: utf-8 -*-
"""
第3周 子任务4（下）：NL2SQL 构建（基于 LangChain）
================================================
功能：自然语言 → 生成 SQL → 执行 SQL → 返回结果
链路：用户问题 → Prompt(含Schema) → 大模型 → SQL → Hive执行 → 结果
依赖：pip install python-dotenv openai langchain pyhive pandas
运行：python nl2sql_langchain.py
"""
import os
import re
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("DEEPSEEK_API_KEY")
BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
HIVE_HOST = os.getenv("HIVE_HOST", "localhost")
HIVE_PORT = int(os.getenv("HIVE_PORT", "10000"))
HIVE_USER = os.getenv("HIVE_USER", "root")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_schema_text() -> str:
    """加载 Schema 文本（优先从抽取结果，否则静态内置）"""
    schema_path = os.path.join(BASE_DIR, "output", "schema_info.txt")
    if os.path.exists(schema_path):
        with open(schema_path, encoding="utf-8") as f:
            return f.read()
    from schema_extract import generate_fallback_schema, schema_to_text
    return schema_to_text(generate_fallback_schema())


def load_prompt_template() -> str:
    with open(os.path.join(BASE_DIR, "prompt_template.txt"), encoding="utf-8") as f:
        return f.read()


def build_chain():
    """构建 LangChain NL2SQL 链路（使用 LCEL）"""
    from langchain.prompts import PromptTemplate
    from langchain_openai import ChatOpenAI
    from langchain_core.output_parsers import StrOutputParser

    schema = load_schema_text()
    prompt = PromptTemplate(
        input_variables=["question"],
        template=load_prompt_template(),
        partial_variables={"schema": schema},
    )
    llm = ChatOpenAI(
        model="deepseek-chat",
        api_key=API_KEY,
        base_url=BASE_URL,
        temperature=0.0,
        max_tokens=512,
    )
    chain = prompt | llm | StrOutputParser()
    return chain


def clean_sql(text: str) -> str:
    """清洗模型输出：去除 Markdown 代码块、前后空白"""
    sql = text.strip()
    sql = re.sub(r"^```(?:sql)?\s*", "", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\s*```$", "", sql)
    sql = sql.strip().rstrip(";")
    return sql


def execute_sql(sql: str):
    """在 Hive 中执行 SQL 并返回结果"""
    from pyhive import hive
    conn = hive.Connection(host=HIVE_HOST, port=HIVE_PORT, username=HIVE_USER)
    cursor = conn.cursor()
    cursor.execute(sql)
    cols = [d[0] for d in cursor.description] if cursor.description else []
    rows = cursor.fetchall()
    conn.close()
    return cols, rows


def ask(question: str):
    """完整 NL2SQL 闭环：提问 → SQL → 执行 → 结果"""
    if not API_KEY or "your-" in API_KEY:
        print("[ERROR] 请先在 .env 中配置 DEEPSEEK_API_KEY")
        return
    chain = build_chain()
    print(f"\n[问题] {question}")
    raw = chain.invoke({"question": question})
    sql = clean_sql(raw)
    print(f"[SQL] {sql}")
    try:
        cols, rows = execute_sql(sql)
        print(f"[结果] 共 {len(rows)} 行")
        if cols:
            print(" | ".join(cols))
            print("-" * 60)
        for r in rows[:20]:
            print(" | ".join(str(c) for c in r))
        if len(rows) > 20:
            print(f"... (仅显示前20行，共{len(rows)}行)")
    except Exception as e:
        print(f"[执行失败] {e}")
    return sql


if __name__ == "__main__":
    print("=" * 60)
    print("NL2SQL 智能问答（云购生活数仓）")
    print("=" * 60)
    # 典型问题测试
    questions = [
        "广东省上月销售额是多少？",
        "销量最高的前5个品类",
        "2024年11月的GMV和订单量是多少？",
        "全年客单价最高的门店是哪家？",
        "APP渠道的GMV占比是多少？",
    ]
    for q in questions:
        ask(q)
