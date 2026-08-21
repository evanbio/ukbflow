# ukbflow

![ukbflow logo](reference/figures/logo.png)

### *面向 UK Biobank 的 RAP 原生 R 分析工作流*

[![CRAN
status](https://www.r-pkg.org/badges/version/ukbflow)](https://CRAN.R-project.org/package=ukbflow)
[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://app.codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)

[📚 文档](https://evanbio.github.io/ukbflow/) • [🚀
快速开始](https://evanbio.github.io/ukbflow/articles/get-started.html) •
[🎨 Tessera](https://folio.evanzhou.org/tessera) • [🧪 Palette
Lab](https://folio.evanzhou.org/apps/palette-lab) • [💬
问题反馈](https://github.com/evanbio/ukbflow/issues) • [🤝
贡献指南](https://github.com/evanbio/ukbflow/blob/main/.github/CONTRIBUTING.md)

**语言：** [English](https://evanbio.github.io/ukbflow/README.md) \|
简体中文

------------------------------------------------------------------------

> \[!NOTE\] 🎉 **2026-04 — ukbflow 现已上架 CRAN！** 使用
> `install.packages("ukbflow")` 安装。

## 简介

**ukbflow** 的定位是面向 UK Biobank 受控数据平台的 R-native、RAP-aware
工作流系统。它为表型提取、疾病衍生、关联分析、可复现表型配方、审计记录和发表级输出提供统一的工作流层，同时让个体水平数据保留在
RAP 环境中。

> **UK Biobank 数据政策（2024+）**：个体水平数据必须保留在 RAP
> 环境中，不得下载到本地。`ukbflow` 旨在支持符合该约束的 RAP
> 原生分析流程；用户仍需确保仅下载获准的汇总级结果。

``` r

library(ukbflow)

# 打开审计 manifest：分析过程中自动记录做了什么
aud <- audit_start("smoking_lung_cancer")

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

# 森林图 —— 直接传入结果表，自动推导估计值 / 置信区间 / 列 / 坐标轴
plot_forest(res)

# 记录模型并写出 manifest：字段 ID、队列快照、表型摘要、
# 模型结果与 session metadata，输出为 JSON
aud <- audit_model(aud, res)
audit_write(aud, "smoking_lung_cancer_audit.json")
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
| **数据获取** | `extract_batch`、`extract_olink`、`extract_nmr`、`job_wait`、`job_result` | 从 RAP 上的 UKB 数据集提取表型、蛋白组与代谢组数据 |
| **数据处理** | `decode_names`、`decode_values`、`derive_icd10`、`derive_followup`、`derive_case`、`derive_recipe` | 多源记录整合；构建分析就绪队列 |
| **关联分析** | `assoc_coxph`、`assoc_logistic`、`assoc_subgroup`、`assoc_rcs`、`assoc_evalue` | 三模型框架校正；亚组、趋势、限制性立方样条剂量反应与 E-value |
| **基因组评分** | `grs_bgen2pgen`、`grs_score`、`grs_standardize` | 在 RAP 工作节点分布式运行 plink2 评分 |
| **可视化** | `plot_forest`、`plot_survival`、`plot_rcs`、`plot_tableone` | 发表级图表输出 |
| **实用工具** | `ops_setup`、`ops_fields`、`ops_fields_common`、`ops_fo`、`ops_alg`、`ops_covariates`、`ops_toy`、`ops_na`、`ops_snapshot`、`ops_withdraw` | 环境检查、项目字段搜索、离线字段速查（含血常规、血生化、NMR 三个完整 panel）、首次发生结局与算法判定结局字段速查、常用协变量预设、合成数据生成、流程诊断与队列管理 |
| **表型配方** | `recipe_list`、`recipe_get`、`recipe_sources`、`recipe_new`、`recipe_write`、`derive_recipe` | 版本化的可复现表型定义库；浏览查阅、无需手写 YAML 即可撰写新配方、并用 [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md) 应用到数据 |
| **分析审计** | `audit_start`、`audit_fields`、`audit_snapshot`、`audit_pheno`、`audit_recipe`、`audit_model`、`audit_job`、`audit_write`、`audit_read`、`audit_diff`、`audit_flowchart` | 为字段、快照、表型、配方、模型结果、RAP 任务和 session metadata 生成轻量分析 manifest；读回并对比 manifest；导出队列衰减表 |

------------------------------------------------------------------------

## 当前支持的表型来源

`ukbflow` 当前聚焦于 UK Biobank
表型提取流程中最常用、最稳定的疾病表型来源：

| 来源 | 编码系统 / 字段类型 | 主要函数 |
|----|----|----|
| 自报告疾病 / 癌症 | UKB 字段 `20002` / `20001` | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) |
| HES 住院诊断 | ICD-10 诊断；`position` 可选任意位置（`41270`）或主要诊断（`41202`） | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) |
| HES 住院诊断（ICD-9） | 少数遗留编码体系；`41271`/`41281`（任意位置）、`41203`/`41263`（主诊断） | [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) |
| HES 住院手术操作（OPCS-4） | `41272`/`41282`（任意位置）、`41200`/`41260`（主操作） | [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) |
| GP 初级保健（Read v2） | `gp_clinical` record 表 `read_2` 列（用 [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md) 取数） | [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) |
| GP 初级保健（CTV3） | `gp_clinical` record 表 `read_3` 列（用 [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md) 取数） | [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) |
| First Occurrence 字段 | UKB 预计算的 `p131xxx` 日期字段 | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) |
| 算法判定结局（ADO） | UKB Category 42 判定后的日期字段，如 `42018`（痴呆）；自成完整病例定义，不经 [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) | [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md) |
| 癌症注册 | ICD-10、histology、behaviour、诊断日期 | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) |
| 癌症注册（ICD-9） | ICD-9 编码（`40013`），与 ICD-10 分支共用 histology/behaviour/诊断日期字段 | [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) |
| 死亡注册 | ICD-10 主要 / 次要死因；`cause` 可选 primary、secondary 或两者 | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) |
| 多源 ICD-10 表型 | HES、死亡注册、First Occurrence、癌症注册 | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) |
| 多源 ICD-9 表型 | HES（ICD-9）、癌症注册（ICD-9） | [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md) |
| 最终病例定义 | 自报告 + ICD-10 衍生 + 可选 ICD-9 / OPCS-4 / GP（Read v2 / CTV3）衍生状态 / 日期 | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) |

GP 处方（`gp_scripts`）和数值测量值暂不属于当前 public API。 UKB
的死亡注册和 First Occurrence 字段没有 ICD-9 或 OPCS-4 对应版本。

------------------------------------------------------------------------

## 局限性

`ukbflow` 是工作流系统，不替代底层 RAP 和统计工具。它围绕 dx-toolkit /
DNAnexus 任务、R 建模函数、绘图包以及基于 PLINK2 的 GRS
流程进行封装、编排与记录。 它不提供通用 DAG 调度器，不估算 RAP
费用，不替代 DNAnexus 界面，也不替代研究设计、
协变量选择、表型有效性判断或因果解释。当前 public phenotype helpers
聚焦上表列出的 UKB 数据来源，含初级保健诊断（Read v2 / CTV3）；GP
处方与数值测量暂不覆盖。

------------------------------------------------------------------------

## 函数一览

**认证与文件获取**

- [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)、[`auth_status()`](https://evanbio.github.io/ukbflow/reference/auth_status.md)、[`auth_logout()`](https://evanbio.github.io/ukbflow/reference/auth_logout.md)、[`auth_list_projects()`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md)、[`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md)
  — RAP 认证
- [`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md)、[`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)
  — 浏览 RAP 文件系统

**提取与解码**

- [`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)、[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)、[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
  — 表型提取
- [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)
  — 导出 GP 初级保健 record 表（gp_clinical 等）
- [`extract_olink()`](https://evanbio.github.io/ukbflow/reference/extract_olink.md)
  — 导出 Olink 蛋白组 entity（约 2900 个蛋白，NPX 值）
- [`extract_nmr()`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md)
  — 导出 249 个 Nightingale NMR 代谢物
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
- [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md)
  — HES 住院 ICD-9（少数遗留编码体系）
- [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md)
  — HES 住院 OPCS-4 手术操作
- [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
  — GP 初级保健诊断（Read v2），基于自行提供的 gp_clinical 表
- [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md)
  — GP 初级保健诊断（CTV3 / Read v3）
- [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md)
  — First Occurrence 字段
- [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md)
  — 算法判定结局（Category 42 判定后的日期字段）
- [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
  — 癌症注册（ICD-10）
- [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md)
  — 癌症注册（ICD-9）
- [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
  — 死亡注册
- [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
  — 多源 ICD-10 合并（封装函数）
- [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)
  — 多源 ICD-9 合并（封装函数）
- [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
  — 自报告 + ICD-10 + 可选 ICD-9 / OPCS-4 / GP（Read v2 / CTV3）最终合并
- [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
  — 一次调用跑完一个内置表型配方

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
- [`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md)
  — 限制性立方样条剂量反应（非线性 + p-nonlinear）
- [`assoc_evalue()`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md)
  — 未测量混杂的 E-value 敏感性分析

**可视化**

- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  — 森林图（PNG / PDF / JPG / TIFF，300 dpi）
- [`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md)
  — 生存曲线（Kaplan-Meier，PNG / PDF / JPG / TIFF，300 dpi）
- [`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md)
  — 限制性立方样条剂量反应曲线（PNG / PDF / JPG / TIFF，300 dpi）
- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  — 基线特征表（DOCX / HTML / PDF / PNG）

**实用工具与诊断**

- [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
  — 环境健康检查（dx CLI、RAP 认证、R 包依赖）
- [`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
  — 搜索当前 RAP 项目中已获批的 UKB 字段
- [`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md)
  — 离线字段速查表：手选常用字段，外加血常规、血生化、NMR 三个完整 panel
- [`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md) —
  1,165 个首次发生（First Occurrence）结局的离线速查表，按 3 字符 ICD-10
  码给出日期与来源字段号
- [`ops_alg()`](https://evanbio.github.io/ukbflow/reference/ops_alg.md)
  — 19 个算法判定结局（Category
  42）的离线速查表，按结局给出日期与来源字段号
- [`ops_covariates()`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md)
  — 常用协变量预设的离线目录，返回解码后的列名
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

**表型配方**

- [`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
  — 列出内置的表型定义配方库
- [`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
  — 读取单个配方为规范化的 `ukbflow_recipe` 对象
- [`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md)
  — 将配方规则摊平为一行一条规则的整洁表
- [`recipe_rule()`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md)
  — 构建单条来源规则
- [`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
  — 构建并校验配方，无需手写 YAML
- [`recipe_write()`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)
  — 将配方对象写出为 YAML 文件
- [`print()`](https://rdrr.io/r/base/print.html) —
  以可读形式渲染配方定义
- [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
  — 将配方应用到数据（归在 `derive_*` 家族；只新增 `{id}_status` /
  `{id}_date` 两列）

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
- [`audit_recipe()`](https://evanbio.github.io/ukbflow/reference/audit_recipe.md)
  — 记录版本化表型配方，内嵌自包含的定义快照
- [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
  — 记录关联分析结果表；outcome/time/协变量等调用细节从 `assoc_*`
  自动读取
- [`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
  — 记录 DNAnexus job ID，并在可用时记录轻量任务 metadata
- [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
  — 将 audit manifest 写出为 JSON
- [`audit_read()`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
  — 将 JSON manifest 读回成可用的 audit 对象
- [`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
  — 对比同一个 audit
  对象内的两条记录（比如快照前后列变化、模型间协变量变化），或对比两个
  audit 对象的整体结构
- [`audit_flowchart()`](https://evanbio.github.io/ukbflow/reference/audit_flowchart.md)
  — 从记录的快照导出队列衰减表，可直接喂给流程图渲染工具
- [`print()`](https://rdrr.io/r/base/print.html) /
  [`summary()`](https://rdrr.io/r/base/summary.html) — 打印简短或详细的
  audit 总览

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

可视化资源：

- **[Tessera](https://folio.evanzhou.org/tessera)** —
  配色、示例数据和可复现的 R 作图配方
- **[Palette Lab](https://folio.evanzhou.org/apps/palette-lab)** —
  在一组固定图形中快速比较不同配色

------------------------------------------------------------------------

## 贡献

欢迎提交 Bug 报告、功能建议和 PR，详见
[CONTRIBUTING.md](https://github.com/evanbio/ukbflow/blob/main/.github/CONTRIBUTING.md)。

------------------------------------------------------------------------

## 许可证

MIT License © 2026 [Yibin Zhou](mailto:evanzhou.bio@gmail.com)

------------------------------------------------------------------------

**Made with ❤️ by [Yibin Zhou](https://github.com/evanbio)**

[⬆ 回到顶部](#ukbflow)
