<div align="center">

<img src="man/figures/logo.png" width="160" alt="ukbflow logo" />

# ukbflow

### *面向 UK Biobank 的 RAP 原生 R 分析工作流*

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://app.codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[📚 文档](https://evanbio.github.io/ukbflow/) •
[🚀 快速开始](https://evanbio.github.io/ukbflow/articles/get-started.html) •
[💬 问题反馈](https://github.com/evanbio/ukbflow/issues) •
[🤝 贡献指南](https://github.com/evanbio/ukbflow/blob/main/CONTRIBUTING.md)

**语言：** [English](README.md) | 简体中文

</div>

---

## 简介

**ukbflow** 提供了一套完整的、RAP 原生的 UK Biobank 分析工作流 —— 从表型提取、疾病衍生，到关联分析和发表级图表，全程在 RAP 云端环境中运行。

> **UK Biobank 数据政策（2024+）**：个体水平数据必须保留在 RAP 环境中，不得下载到本地。所有 `ukbflow` 函数均遵循此约束设计。

```r
library(ukbflow)

# 本地生成合成 UKB 数据（在 RAP 上请替换为 extract_batch() + job_wait()）
data <- ops_toy(n = 5000, seed = 2026) |>
  derive_missing()

# 衍生肺癌结局（ICD-10 C34）及随访时间
data <- data |>
  derive_icd10(name = "lung", icd10 = "C34",
               source = c("cancer_registry", "hes")) |>
  derive_followup(name         = "lung",
                  event_col    = "lung_icd10_date",
                  baseline_col = "p53_i0",
                  censor_date  = as.Date("2022-10-31"),
                  death_col    = "p40000_i0")

# 定义暴露变量：曾吸烟 vs. 从不吸烟
data[, smoking_ever := factor(
  ifelse(p20116_i0 == "Never", "Never", "Ever"),
  levels = c("Never", "Ever")
)]

# Cox 回归：吸烟 → 肺癌（三模型校正框架）
res <- assoc_coxph(data,
  outcome_col  = "lung_icd10",
  time_col     = "lung_followup_years",
  exposure_col = "smoking_ever",
  covariates   = c("p21022", "p31", "p22189"))

# 森林图
res_df <- as.data.frame(res)
plot_forest(
  data      = res_df,
  est       = res_df$HR,
  lower     = res_df$CI_lower,
  upper     = res_df$CI_upper,
  ci_column = 2L
)
```

---

## 安装

```r
# 推荐
pak::pkg_install("evanbio/ukbflow")

# 或者
remotes::install_github("evanbio/ukbflow")
```

**环境要求：** R ≥ 4.1 · [dxpy](https://documentation.dnanexus.com/downloads)（dx-toolkit，RAP 交互必需）

```bash
pip install dxpy
```

---

## 核心功能

| 层级 | 核心函数 | 说明 |
|---|---|---|
| **连接** | `auth_login`、`auth_select_project` | 通过 dx-toolkit 认证并连接 RAP |
| **数据获取** | `fetch_metadata`、`extract_batch`、`job_wait` | 从 RAP 上的 UKB 数据集提取表型数据 |
| **数据处理** | `decode_names`、`decode_values`、`derive_icd10`、`derive_followup`、`derive_case` | 多源记录整合；构建分析就绪队列 |
| **关联分析** | `assoc_coxph`、`assoc_logistic`、`assoc_subgroup` | 三模型框架校正；亚组与趋势分析 |
| **基因组评分** | `grs_bgen2pgen`、`grs_score`、`grs_standardize` | 在 RAP 工作节点分布式运行 plink2 评分 |
| **可视化** | `plot_forest`、`plot_tableone` | 发表级图表输出 |
| **实用工具** | `ops_setup`、`ops_toy`、`ops_na`、`ops_snapshot`、`ops_withdraw` | 环境检查、合成数据生成、流程诊断与队列管理 |

---

## 函数一览

<details>
<summary><b>认证与文件获取</b></summary>

- `auth_login()`、`auth_status()`、`auth_logout()`、`auth_list_projects()`、`auth_select_project()` — RAP 认证
- `fetch_ls()`、`fetch_tree()`、`fetch_url()`、`fetch_file()` — RAP 文件系统
- `fetch_metadata()`、`fetch_field()` — UKB 元数据快捷下载

</details>

<details>
<summary><b>提取与解码</b></summary>

- `extract_ls()`、`extract_pheno()`、`extract_batch()` — 表型提取
- `decode_values()` — 整数编码 → 可读标签
- `decode_names()` — 字段 ID → snake_case 列名

</details>

<details>
<summary><b>任务监控</b></summary>

- `job_status()` — 按 ID 查询任务状态
- `job_wait()` — 阻塞等待任务完成（支持超时）
- `job_path()` — 获取已完成任务的输出路径
- `job_result()` — 获取任务结果对象
- `job_ls()` — 列出最近提交的任务

</details>

<details>
<summary><b>衍生 — 疾病表型</b></summary>

- `derive_missing()` — 处理"不知道"/"不愿回答"
- `derive_covariate()` — 类型转换 + 分布汇总
- `derive_cut()` — 连续变量分组
- `derive_selfreport()` — 自报告疾病状态 + 日期
- `derive_hes()` — HES 住院 ICD-10
- `derive_first_occurrence()` — First Occurrence 字段
- `derive_cancer_registry()` — 癌症注册
- `derive_death_registry()` — 死亡注册
- `derive_icd10()` — 多源合并（封装函数）
- `derive_case()` — 自报告 + ICD-10 最终合并

</details>

<details>
<summary><b>衍生 — 生存变量</b></summary>

- `derive_timing()` — 患病时间分类（现患 vs. 新发）
- `derive_age()` — 事件发生年龄
- `derive_followup()` — 随访终止日期与随访年数

</details>

<details>
<summary><b>关联分析</b></summary>

- `assoc_coxph()` / `assoc_cox()` — Cox 比例风险模型（HR）
- `assoc_logistic()` / `assoc_logit()` — 逻辑回归（OR）
- `assoc_linear()` / `assoc_lm()` — 线性回归（β）
- `assoc_coxph_zph()` — 比例风险假设检验
- `assoc_subgroup()` — 分层分析 + 交互项 LRT
- `assoc_trend()` — 剂量-反应趋势 + p_trend
- `assoc_competing()` — Fine-Gray 竞争风险（SHR）
- `assoc_lag()` — 滞后暴露敏感性分析

</details>

<details>
<summary><b>可视化</b></summary>

- `plot_forest()` — 森林图（PNG / PDF / JPG / TIFF，300 dpi）
- `plot_tableone()` — 基线特征表（DOCX / HTML / PDF / PNG）

</details>

<details>
<summary><b>实用工具与诊断</b></summary>

- `ops_setup()` — 环境健康检查（dx CLI、RAP 认证、R 包依赖）
- `ops_toy()` — 生成合成 UKB 风格数据，用于开发与测试
- `ops_na()` — 逐列汇总缺失值（NA 与 `""`）及缺失率
- `ops_snapshot()` — 记录流程检查点，追踪数据集在各步骤的变化
- `ops_snapshot_cols()` — 获取指定快照保存的列名列表
- `ops_snapshot_diff()` — 比较两个快照之间的列差异
- `ops_snapshot_remove()` — 删除某快照之后新增的列
- `ops_set_safe_cols()` — 设置受保护列，ops_snapshot_remove 不会删除这些列
- `ops_withdraw()` — 从队列中排除 UKB 撤回参与者

</details>

<details>
<summary><b>GRS 流程</b></summary>

- `grs_check()` — 验证 SNP 权重文件
- `grs_bgen2pgen()` — 在 RAP 上将 BGEN 转换为 PGEN（提交云端任务）
- `grs_score()` — 使用 plink2 跨染色体计算 GRS
- `grs_standardize()` / `grs_zscore()` — Z 分标准化
- `grs_validate()` — OR/HR per SD、高 vs. 低、趋势检验、AUC/C-index

</details>

---

## 文档

完整 vignette 与函数参考：

**[https://evanbio.github.io/ukbflow/](https://evanbio.github.io/ukbflow/)**

---

## 贡献

欢迎提交 Bug 报告、功能建议和 PR，详见 [CONTRIBUTING.md](https://github.com/evanbio/ukbflow/blob/main/CONTRIBUTING.md)。

---

## 许可证

MIT License © 2026 [Yibin Zhou](mailto:evanzhou.bio@gmail.com)

---

<div align="center">

**Made with ❤️ by [Yibin Zhou](https://github.com/evanbio)**

[⬆ 回到顶部](#ukbflow)

</div>
