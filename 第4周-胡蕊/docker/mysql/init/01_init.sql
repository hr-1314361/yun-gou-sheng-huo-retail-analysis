-- ============================================================
-- MySQL 初始化脚本（容器首次启动自动执行）
-- 作用：创建 Hive Metastore 与 Superset 元数据库，并授权
-- 注意：密码由环境变量控制，此处仅建库，不写死任何密码
-- ============================================================

CREATE DATABASE IF NOT EXISTS metastore
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE DATABASE IF NOT EXISTS superset
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE DATABASE IF NOT EXISTS ydsh_ads
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- 只读分析账号：仅授予查询权限，体现权限最小化
CREATE USER IF NOT EXISTS 'ydsh_reader'@'%' IDENTIFIED BY 'readonly_2024';
GRANT SELECT ON ydsh_ads.* TO 'ydsh_reader'@'%';
FLUSH PRIVILEGES;
