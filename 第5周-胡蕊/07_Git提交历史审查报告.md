# 云购生活新零售 · Git 提交历史审查报告

| 项目 | 内容 |
|---|---|
| 文档版本 | v1.0 |
| 编写人 | 胡蕊 |
| 编写日期 | 2026-11-24 |

---

## 一、仓库概览

| 项 | 内容 |
|---|---|
| 仓库路径 | `d:\xmsx` |
| 主分支 | `master` |
| 提交总数 | 5（截至审查日） |
| 贡献者 | 胡蕊 |

## 二、提交历史

```
2df5001 fix(w3): 内嵌仓库转为普通文件提交
257cdf0 feat(w4): 可视化与Docker一键部署
03cad4c feat(w3): DWS/ADS建模、预测建模与NL2SQL
01d7139 feat(w2): 数据清洗与DWD明细层建设
2328c4b feat(w1): 环境搭建与数据质量评估
```

## 三、提交规范审查

### 3.1 约定式提交（Conventional Commits）

| 提交类型 | 数量 | 说明 |
|---|---|---|
| `feat` | 4 | 新功能（各周核心交付） |
| `fix` | 1 | 修复（内嵌仓库转普通文件） |
| `docs` | 0 | 文档（第 5 周提交将补充） |

**评审结论**：提交信息遵循 `<type>(<scope>): <subject>` 格式，type 使用 `feat`/`fix`，scope 使用 `w1`~`w4` 标识周次，subject 简洁描述交付内容，符合约定式提交规范。

### 3.2 分支结构

当前项目采用单分支 `master` 线性提交，按周次顺序推进。由于是个人实训项目，分支结构简洁清晰。

**建议**（团队协作场景）：
- 每个功能模块应独立分支开发，如 `feature/w4-echarts`、`feature/w4-docker`
- 开发完成后通过 Pull Request 合并到 `master`
- PR 需至少 1 人 Code Review 后方可合并

### 3.3 提交粒度

| 周次 | 提交数 | 粒度评价 |
|---|---|---|
| 第 1 周 | 1 | 环境搭建 + 数据质量评估，粒度适中 |
| 第 2 周 | 1 | 清洗 + DWD + 文档，粒度适中 |
| 第 3 周 | 2 | DWS/ADS + NL2SQL + Git 协作，修复内嵌仓库问题单独提交，粒度合理 |
| 第 4 周 | 1 | 可视化 + 部署 + 优化，粒度偏大（可拆分为 echarts/streamlit/docker 三个提交） |

**改进点**：第 4 周提交涉及多个独立模块，建议后续按模块拆分提交，便于回溯与 Code Review。

## 四、PR / Issue 记录

本项目在第 3 周实践了 Git Fork 工作流，相关记录存放在 `第3周-胡蕊/git/` 目录：

| 文件 | 内容 |
|---|---|
| `01_fork_workflow.md` | Fork 工作流操作记录 |
| `02_pr_code_review.md` | PR 与 Code Review 记录（2 位评审人，5 条意见） |
| `03_issues.md` | Issue 追踪记录（4 个 Issue） |
| `04_merge_conflict.md` | 合并冲突解决记录 |

## 五、.gitignore 审查

`.gitignore` 已排除以下内容：

| 类别 | 规则 |
|---|---|
| Python 缓存 | `__pycache__/`, `*.py[cod]`, `.venv/` |
| 密钥 | `.env`, `*.env` |
| 大文件依赖 | `echarts.min.js`, `dashboard_data.*`, `mysql-connector-j-*.jar` |
| IDE | `.idea/`, `.vscode/` |
| 临时文件 | `*.log`, `*.db`, `results/*.csv` |

**评审结论**：敏感信息（密钥）与大文件依赖未纳入版本控制，符合工程化规范。

## 六、问题与改进计划

| 问题 | 改进措施 |
|---|---|
| 第 4 周提交粒度过大 | 后续按模块拆分提交（echarts / streamlit / docker） |
| 缺少 `docs` 类型提交 | 第 5 周文档交付使用 `docs(w5):` 类型 |
| 分支结构单一 | 团队协作时启用 feature 分支 + PR 流程 |
| 缺少提交签名 | 后续可配置 GPG 签名提交 |

## 七、总结

本项目 Git 提交历史整体规范，提交信息遵循约定式提交格式，.gitignore 配置合理，敏感信息与大文件未入库。主要改进方向是细化提交粒度与引入 feature 分支 + PR 流程，以适应团队协作场景。
