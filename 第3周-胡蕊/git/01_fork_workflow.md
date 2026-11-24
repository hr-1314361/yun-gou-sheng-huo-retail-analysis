# Git Fork 工作流实践记录

## 一、Fork 工作流概述

Fork 工作流是分布式团队协作的经典模式：每位开发者从主仓库 Fork 一份到个人空间，
在个人仓库的分支上开发，完成后通过 Pull Request (PR) 向主仓库提交合并请求。

## 二、实际操作流程

### 1. Fork 主仓库
- 主仓库：`git@github.com:ydsh-team/yunGou-dw.git`（团队公共仓库）
- 个人 Fork：`git@github.com:hurui/yunGou-dw.git`（个人仓库）

### 2. 克隆到本地
```bash
git clone git@github.com:hurui/yunGou-dw.git
cd yunGou-dw
# 添加上游主仓库
git remote add upstream git@github.com:ydsh-team/yunGou-dw.git
```

### 3. 创建功能分支开发
```bash
git checkout -b feature/dws-ads-layer
# 开发 DWS/ADS 层 SQL 脚本
git add sql/dws/ sql/ads/
git commit -m "feat(dws): 新增DWS汇总层与ADS应用层DDL及ETL脚本"
```

### 4. 推送到个人仓库
```bash
git push origin feature/dws-ads-layer
```

### 5. 发起 Pull Request
- 在 GitHub 上从 `hurui/yunGou-dw:feature/dws-ads-layer` → `ydsh-team/yunGou-dw:main`
- PR 标题：`[DWS/ADS] 汇总层与应用层建设`
- PR 描述：包含变更内容、测试方法、关联 Issue

### 6. 同步上游更新
```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## 三、分支命名规范

| 分支类型 | 命名格式 | 示例 |
|----------|----------|------|
| 功能分支 | feature/<功能描述> | feature/dws-ads-layer |
| 修复分支 | fix/<问题描述> | fix/prediction-mae-calc |
| 文档分支 | docs/<文档描述> | docs/ai-reflection |
| 热修复分支 | hotfix/<问题描述> | hotfix/nl2sql-schema |

## 四、提交信息规范（Conventional Commits）

```
<type>(<scope>): <subject>

<body>

<footer>
```

type 取值：feat / fix / docs / style / refactor / test / chore
scope 取值：dws / ads / python / nl2sql / git 等

示例：
- `feat(dws): 新增销售日汇总表dws_sales_1d`
- `fix(nl2sql): 修复Schema抽取时分区列遗漏问题`
- `docs(git): 补充Fork工作流实践记录`
