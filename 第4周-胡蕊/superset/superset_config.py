# -*- coding: utf-8 -*-
"""
Superset 配置文件（挂载到容器 /app/pythonpath/superset_config.py）
---------------------------------------------------------------
要点：
  1. SECRET_KEY / 元数据库密码全部从环境变量注入，禁止硬编码；
  2. 元数据库使用 MySQL 中独立的 superset 库，与 Hive Metastore 库隔离；
  3. 开启跨图表联动（DASHBOARD_CROSS_FILTERS）与下钻能力；
  4. Hive 查询设置超时与行数上限，避免大屏被慢查询拖垮。
"""
import os

# ---------------- 基础安全配置 ----------------
SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]
WTF_CSRF_ENABLED = True
TALISMAN_ENABLED = False  # 内网实训环境关闭 HTTPS 强制跳转
ENABLE_PROXY_FIX = True

# ---------------- 元数据库 ----------------
MYSQL_HOST = os.getenv("MYSQL_HOST", "mysql")
MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.environ["MYSQL_ROOT_PASSWORD"]
MYSQL_DB = os.getenv("SUPERSET_DB_NAME", "superset")

# 必须显式使用 pymysql 方言：镜像内安装的是 pymysql，没有 mysqlclient
SQLALCHEMY_DATABASE_URI = (
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
    "?charset=utf8mb4"
)

# ---------------- 功能开关 ----------------
FEATURE_FLAGS = {
    "DASHBOARD_CROSS_FILTERS": True,        # 图表联动（点击图表筛选其他图表）
    "DASHBOARD_NATIVE_FILTERS": True,       # 仪表板级筛选器
    "DRILL_TO_DETAIL": True,                # 下钻到明细
    "DRILL_BY": True,
    "ENABLE_TEMPLATE_PROCESSING": True,     # SQL 中使用 {{ filter_values() }} 动态筛选
    "ALERT_REPORTS": True,
    "HORIZONTAL_FILTER_BAR": True,
}

# ---------------- 查询与缓存 ----------------
ROW_LIMIT = 10000                       # 单次查询返回行数上限
SQLLAB_TIMEOUT = 120                    # SQL Lab 超时（秒）
SUPERSET_WEBSERVER_TIMEOUT = 120
SQL_MAX_ROW = 50000
DEFAULT_CACHE_TIMEOUT = 300             # 图表缓存 5 分钟

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": os.getenv("REDIS_URL", "redis://redis:6379/1"),
}

# ---------------- 地图 ----------------
# 区域分布地图使用 Superset 内置 country map（china），无需额外配置；
# 若使用自建 GeoJSON，可在此指定：
# EXTRA_CATEGORICAL_COLOR_SCHEMES = []
# 中文界面
BABEL_DEFAULT_LOCALE = "zh"
LANGUAGES = {"zh": {"flag": "cn", "name": "Chinese"}}

# ---------------- 日志 ----------------
import logging
LOG_LEVEL = logging.INFO
