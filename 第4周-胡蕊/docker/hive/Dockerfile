# ============================================================
# Hive 镜像：在官方 apache/hive:4.0.0 基础上加入 MySQL JDBC 驱动
# 构建：docker build -t ydsh/hive:4.0.0 ./docker/hive
# ============================================================
FROM apache/hive:4.0.0

USER root

# 驱动文件随仓库提交（docker/hive/lib/mysql-connector-j-8.0.33.jar）
# 若仓库中无该文件，可在构建前执行：
#   curl -o docker/hive/lib/mysql-connector-j-8.0.33.jar \
#     https://maven.aliyun.com/repository/public/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
COPY lib/mysql-connector-j-8.0.33.jar /opt/hive/lib/mysql-connector-j-8.0.33.jar

RUN chown hive:hive /opt/hive/lib/mysql-connector-j-8.0.33.jar && \
    mkdir -p /user/hive/warehouse && chown -R hive:hive /user/hive

USER hive
