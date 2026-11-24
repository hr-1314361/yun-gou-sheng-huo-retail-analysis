# ============================================================
# Superset 镜像：官方 3.1.3 + MySQL(PyMySQL) + Hive(PyHive) 驱动
# 构建：docker build -t ydsh/superset:3.1.3 ./docker/superset
# ============================================================
FROM apache/superset:3.1.3

USER root

RUN pip install --no-cache-dir \
        pymysql \
        pyhive \
        thrift \
        clickhouse-connect \
        pillow

USER superset
