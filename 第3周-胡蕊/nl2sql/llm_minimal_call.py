# -*- coding: utf-8 -*-
"""
第3周 子任务3：大模型 API 接入与密钥管理
========================================
功能：编写 Python 脚本完成一次最小化的大模型调用，验证连通性与返回格式。
依赖：pip install python-dotenv openai
运行：python llm_minimal_call.py
"""
import os
from dotenv import load_dotenv

# 加载 .env 中的密钥（严禁硬编码）
load_dotenv()

API_KEY = os.getenv("DEEPSEEK_API_KEY")
BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")

if not API_KEY or "your-" in API_KEY:
    raise ValueError("请先在 .env 文件中配置有效的 DEEPSEEK_API_KEY（参考 .env.example）")


def minimal_chat(prompt: str) -> str:
    """最小化大模型调用：单轮对话，返回模型回复文本"""
    from openai import OpenAI
    client = OpenAI(api_key=API_KEY, base_url=BASE_URL)
    resp = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1,
        max_tokens=200,
    )
    return resp.choices[0].message.content


if __name__ == "__main__":
    print("=" * 50)
    print("大模型 API 最小化调用测试")
    print("=" * 50)
    test_prompt = "用一句话介绍数据仓库中的 DWS 层和 ADS 层的区别。"
    print(f"\n[输入] {test_prompt}\n")
    try:
        reply = minimal_chat(test_prompt)
        print(f"[输出] {reply}")
        print("\n[OK] 连通性验证通过，返回格式正常。")
    except Exception as e:
        print(f"[FAIL] 调用失败: {e}")
