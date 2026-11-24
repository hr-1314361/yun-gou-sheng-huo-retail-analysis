# ============================================================
# Python App（Streamlit 智能问数）
# 构建上下文：第4周-胡蕊/（即 docker 目录的上一级）
# 构建：docker build -f docker/app/Dockerfile -t ydsh/streamlit-app:1.0 .
# ============================================================
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Shanghai \
    ECHARTS_JS=/opt/echarts/echarts.min.js \
    STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

WORKDIR /app

# 系统依赖：PyHive 纯 Python 即可，无需编译；仅保留 curl 用于健康检查
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY streamlit/requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

COPY streamlit/ /app/
# 复用大屏的本地 ECharts，避免容器内依赖 CDN
COPY echarts/static/echarts.min.js /opt/echarts/echarts.min.js

EXPOSE 8501

HEALTHCHECK --interval=20s --timeout=5s --start-period=40s --retries=5 \
    CMD curl -fsS http://localhost:8501/_stcore/health || exit 1

CMD ["streamlit", "run", "app.py", \
     "--server.port=8501", "--server.address=0.0.0.0", \
     "--server.headless=true", "--browser.gatherUsageStats=false"]
