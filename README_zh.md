# ukbflow

![ukbflow logo](reference/figures/logo.png)

### *面向 UK Biobank 的 RAP 原生 R 分析工作流*

[![CRAN
status](https://www.r-pkg.org/badges/version/ukbflow)](https://CRAN.R-project.org/package=ukbflow)
[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://app.codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)

[📚 文档](https://evanbio.github.io/ukbflow/) • [📖
教程书](https://ukbflow.evanzhou.org) • [🚀
快速开始](https://evanbio.github.io/ukbflow/articles/get-started.html) •
[💬 问题反馈](https://github.com/evanbio/ukbflow/issues) • [🤝
贡献指南](https://github.com/evanbio/ukbflow/blob/main/CONTRIBUTING.md)

**语言：** [English](https://evanbio.github.io/ukbflow/README.md) \|
简体中文

------------------------------------------------------------------------

> \[!NOTE\] 🎉 **2026-04 — ukbflow 现已上架 CRAN！** 使用
> `install.packages("ukbflow")` 安装。

## 简介

**ukbflow** 的定位是面向 UK Biobank 受控数据平台的 R-native、RAP-aware
工作流系统。它为表型提取、疾病衍生、关联分析、审计记录和发表级输出提供统一的工作流层，同时让个体水平数据保留在
RAP 环境中。

> **UK Biobank 数据政策（2024+）**：个体水平数据必须保留在 RAP
> 环境中，不得下载到本地。`ukbflow` 旨在支持符合该约束的 RAP
> 原生分析流程；用户仍需确保仅下载获准的汇总级结果。

``` r

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

------------------------------------------------------------------------

## 安装

``` r

# 从 CRAN 安装（推荐）
install.packages("ukbflow")

# 从 GitHub 安装最新开发版
pak::pkg_install("evanbio/ukbflow")

# 或者
remotes::install_github("evanbio/ukbflow")
```

**环境要求：** R ≥ 4.1 ·
[dxpy](https://documentation.dnanexus.com/downloads)（dx-toolkit，RAP
交互必需）

``` bash
pip install dxpy
```

GRS 流程还需要 RAP 任务环境中可用的 `plink2`。

------------------------------------------------------------------------

## 核心功能

| 层级 | 核心函数 | 说明 |
|----|----|----|
| **连接** | `auth_login`、`auth_select_project` | 通过 dx-toolkit 认证并连接 RAP |
| **数据获取** | `fetch_metadata`、`extract_batch`、`job_wait` | 从 RAP 上的 UKB 数据集提取表型数据 |
| **数据处理** | `decode_names`、`decode_values`、`derive_icd10`、`derive_followup`、`derive_case` | 多源记录整合；构建分析就绪队列 |
| **关联分析** | `assoc_coxph`、`assoc_logistic`、`assoc_subgroup` | 三模型框架校正；亚组与趋势分析 |
| **基因组评分** | `grs_bgen2pgen`、`grs_score`、`grs_standardize` | 在 RAP 工作节点分布式运行 plink2 评分 |
| **可视化** | `plot_forest`、`plot_tableone` | 发表级图表输出 |
| **实用工具** | `ops_setup`、`ops_fields`、`ops_fields_common`、`ops_toy`、`ops_na`、`ops_snapshot`、`ops_withdraw` | 环境检查、项目字段搜索、常见字段速查、合成数据生成、流程诊断与队列管理 |
| **分析审计** | `audit_start`、`audit_fields`、`audit_snapshot`、`audit_pheno`、`audit_model`、`audit_job`、`audit_write` | 为字段、快照、表型、模型结果、RAP 任务和 session metadata 生成轻量分析 manifest |

------------------------------------------------------------------------

## 当前支持的表型来源

`ukbflow` 当前聚焦于 UK Biobank
表型提取流程中最常用、最稳定的疾病表型来源：

| 来源 | 编码系统 / 字段类型 | 主要函数 |
|----|----|----|
| 自报告疾病 / 癌症 | UKB 字段 `20002` / `20001` | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) |
| HES 住院诊断 | ICD-10，任意诊断位置字段 `41270`，日期来自 `41280`；暂不区分 primary/secondary position | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) |
| First Occurrence 字段 | UKB 预计算的 `p131xxx` 日期字段 | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) |
| 癌症注册 | ICD-10、histology、behaviour、诊断日期 | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) |
| 死亡注册 | ICD-10 主要 / 次要死因 | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) |
| 多源 ICD-10 表型 | HES、死亡注册、First Occurrence、癌症注册 | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) |
| 最终病例定义 | 自报告 + ICD-10 衍生状态 / 日期 | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) |

ICD-9、OPCS-4、Read v2、CTV3 以及其他 GP / primary-care
编码系统暂不属于当前 public API。

------------------------------------------------------------------------

## 局限性

`ukbflow` 是工作流系统，不替代底层 RAP 和统计工具。它围绕 dx-toolkit /
DNAnexus 任务、R 建模函数、绘图包以及基于 PLINK2 的 GRS
流程进行封装、编排与记录。 它不提供通用 DAG 调度器，不估算 RAP
费用，不替代 DNAnexus 界面，也不替代研究设计、
协变量选择、表型有效性判断或因果解释。当前 public phenotype helpers
聚焦上表列出的 UKB 数据来源，暂不覆盖 GP / primary-care 编码系统。

------------------------------------------------------------------------

## 函数一览

**认证与文件获取**

- [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)、[`auth_status()`](https://evanbio.github.io/ukbflow/reference/auth_status.md)、[`auth_logout()`](https://evanbio.github.io/ukbflow/reference/auth_logout.md)、[`auth_list_projects()`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md)、[`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md)
  — RAP 认证
- [`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md)、[`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)、[`fetch_url()`](https://evanbio.github.io/ukbflow/reference/fetch_url.md)、[`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md)
  — RAP 文件系统
- [`fetch_metadata()`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md)、[`fetch_field()`](https://evanbio.github.io/ukbflow/reference/fetch_field.md)
  — UKB 元数据快捷下载

**提取与解码**

- [`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)、[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)、[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
  — 表型提取
- [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
  — 整数编码 → 可读标签
- [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
  — 字段 ID → snake_case 列名

**任务监控**

- [`job_status()`](https://evanbio.github.io/ukbflow/reference/job_status.md)
  — 按 ID 查询任务状态
- [`job_wait()`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
  — 阻塞等待任务完成（支持超时）
- [`job_path()`](https://evanbio.github.io/ukbflow/reference/job_path.md)
  — 获取已完成任务的输出路径
- [`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md)
  — 获取任务结果对象
- [`job_ls()`](https://evanbio.github.io/ukbflow/reference/job_ls.md) —
  列出最近提交的任务

**衍生 — 疾病表型**

- [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
  — 处理”不知道”/“不愿回答”
- [`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md)
  — 类型转换 + 分布汇总
- [`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
  — 连续变量分组
- [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
  — 自报告疾病状态 + 日期
- [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
  — HES 住院 ICD-10
- [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md)
  — First Occurrence 字段
- [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
  — 癌症注册
- [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
  — 死亡注册
- [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
  — 多源合并（封装函数）
- [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
  — 自报告 + ICD-10 最终合并

**衍生 — 生存变量**

- [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
  — 患病时间分类（现患 vs. 新发）
- [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md)
  — 事件发生年龄
- [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
  — 随访终止日期与随访年数

**关联分析**

- [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  /
  [`assoc_cox()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  — Cox 比例风险模型（HR）
- [`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  /
  [`assoc_logit()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  — 逻辑回归（OR）
- [`assoc_linear()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
  /
  [`assoc_lm()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
  — 线性回归（β）
- [`assoc_coxph_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md)
  — 比例风险假设检验
- [`assoc_subgroup()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md)
  — 分层分析 + 交互项 LRT
- [`assoc_trend()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
  — 剂量-反应趋势 + p_trend
- [`assoc_competing()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md)
  — Fine-Gray 竞争风险（SHR）
- [`assoc_lag()`](https://evanbio.github.io/ukbflow/reference/assoc_lag.md)
  — 滞后暴露敏感性分析

**可视化**

- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  — 森林图（PNG / PDF / JPG / TIFF，300 dpi）
- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  — 基线特征表（DOCX / HTML / PDF / PNG）

**实用工具与诊断**

- [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
  — 环境健康检查（dx CLI、RAP 认证、R 包依赖）
- [`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
  — 搜索当前 RAP 项目中已获批的 UKB 字段
- [`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md)
  — 常用 UKB 字段 ID 的小型离线速查表
- [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
  — 生成合成 UKB 风格数据，用于开发与测试
- [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md) —
  逐列汇总缺失值（NA 与 `""`）及缺失率
- [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
  — 记录流程检查点，追踪数据集在各步骤的变化
- [`ops_snapshot_cols()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md)
  — 获取指定快照保存的列名列表
- [`ops_snapshot_diff()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_diff.md)
  — 比较两个快照之间的列差异
- [`ops_snapshot_remove()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_remove.md)
  — 删除某快照之后新增的列
- [`ops_set_safe_cols()`](https://evanbio.github.io/ukbflow/reference/ops_set_safe_cols.md)
  — 设置受保护列，ops_snapshot_remove 不会删除这些列
- [`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
  — 从队列中排除 UKB 撤回参与者

**分析审计**

- [`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
  — 创建分析审计对象，记录包版本与 session metadata
- [`audit_fields()`](https://evanbio.github.io/ukbflow/reference/audit_fields.md)
  — 记录提取所用的 UKB 字段 ID
- [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
  — 记录队列大小、列数、缺失列数和完整列名
- [`audit_cols()`](https://evanbio.github.io/ukbflow/reference/audit_cols.md)
  — 从 audit snapshot 中取回列名
- [`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
  — 基于 `derive_*` 标准命名汇总衍生表型
- [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
  — 记录关联分析结果表和可选协变量
- [`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
  — 记录 DNAnexus job ID，并在可用时记录轻量任务 metadata
- [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
  — 将 audit manifest 写出为 JSON
- [`summary()`](https://rdrr.io/r/base/summary.html) — 打印简短的 audit
  总览

**GRS 流程**

- [`grs_check()`](https://evanbio.github.io/ukbflow/reference/grs_check.md)
  — 验证 SNP 权重文件
- [`grs_bgen2pgen()`](https://evanbio.github.io/ukbflow/reference/grs_bgen2pgen.md)
  — 在 RAP 上将 BGEN 转换为 PGEN（提交云端任务）
- [`grs_score()`](https://evanbio.github.io/ukbflow/reference/grs_score.md)
  — 使用 plink2 跨染色体计算 GRS
- [`grs_standardize()`](https://evanbio.github.io/ukbflow/reference/grs_standardize.md)
  /
  [`grs_zscore()`](https://evanbio.github.io/ukbflow/reference/grs_standardize.md)
  — Z 分标准化
- [`grs_validate()`](https://evanbio.github.io/ukbflow/reference/grs_validate.md)
  — OR/HR per SD、高 vs. 低、趋势检验、AUC/C-index

------------------------------------------------------------------------

## 文档

完整 vignette 与函数参考：

**<https://evanbio.github.io/ukbflow/>**

------------------------------------------------------------------------

## 贡献

欢迎提交 Bug 报告、功能建议和 PR，详见
[CONTRIBUTING.md](https://github.com/evanbio/ukbflow/blob/main/CONTRIBUTING.md)。

------------------------------------------------------------------------

## 许可证

MIT License © 2026 [Yibin Zhou](mailto:evanzhou.bio@gmail.com)

------------------------------------------------------------------------

**Made with ❤️ by [Yibin Zhou](https://github.com/evanbio)**

[⬆ 回到顶部](#ukbflow)
