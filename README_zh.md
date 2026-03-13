# ukbflow

![ukbflow logo](reference/figures/logo.png)

### *面向 UK Biobank 的 RAP 原生 R 分析工作流*

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License:
MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[📚 文档](https://evanbio.github.io/ukbflow/) • [🚀
快速开始](https://evanbio.github.io/ukbflow/articles/get-started.html) •
[💬 问题反馈](https://github.com/evanbio/ukbflow/issues) • [🤝
贡献指南](https://evanbio.github.io/ukbflow/CONTRIBUTING.md)

**语言：** [English](https://evanbio.github.io/ukbflow/README.md) \|
简体中文

------------------------------------------------------------------------

## 简介

**ukbflow** 提供了一套完整的、RAP 原生的 UK Biobank 分析工作流 ——
从表型提取、疾病衍生，到关联分析和发表级图表，全程在 RAP
云端环境中运行。

> **UK Biobank 数据政策（2024+）**：个体水平数据必须保留在 RAP
> 环境中，不得下载到本地。所有 `ukbflow` 函数均遵循此约束设计。

``` r
library(ukbflow)

# 认证并提取数据
auth_login()
df <- extract_pheno(c(31, 21022, 53, 20116, 41270, 41280)) |>
  decode_values() |>
  decode_names()

# 衍生疾病表型
df <- df |>
  derive_missing() |>
  derive_icd10(name = "outcome", icd10 = "E11",
               source = c("hes", "first_occurrence")) |>
  derive_followup(name = "outcome", event_col = "outcome_date",
                  baseline_col = "date_baseline",
                  censor_date  = as.Date("2022-06-01"))

# 关联分析 → 森林图
res <- assoc_coxph(df, outcome_col = "outcome_status",
                   time_col = "outcome_followup_years",
                   exposure_col = "exposure_status",
                   covariates = c("age_at_recruitment", "sex", "tdi"))
plot_forest(res)
```

------------------------------------------------------------------------

## 安装

``` r
# 推荐
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

------------------------------------------------------------------------

## 核心功能

| 层级           | 核心函数                                                                          | 说明                                       |
|----------------|-----------------------------------------------------------------------------------|--------------------------------------------|
| **连接**       | `auth_login`、`auth_select_project`                                               | 通过 dx-toolkit 认证并连接 RAP             |
| **数据获取**   | `fetch_metadata`、`extract_batch`、`job_wait`                                     | 从 RAP 上的 UKB 数据集提取表型数据         |
| **数据处理**   | `decode_names`、`decode_values`、`derive_icd10`、`derive_followup`、`derive_case` | 多源记录整合；构建分析就绪队列             |
| **关联分析**   | `assoc_coxph`、`assoc_logistic`、`assoc_subgroup`                                 | 三模型框架校正；亚组与趋势分析             |
| **基因组评分** | `grs_bgen2pgen`、`grs_score`、`grs_standardize`                                   | 在 RAP 工作节点分布式运行 plink2 评分      |
| **可视化**     | `plot_forest`、`plot_tableone`                                                    | 发表级图表输出                             |
| **实用工具**   | `ops_setup`、`ops_toy`、`ops_na`、`ops_snapshot`、`ops_withdraw`                  | 环境检查、合成数据生成、流程诊断与队列管理 |

------------------------------------------------------------------------

## 函数一览

**认证与文件获取**

- [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)、[`auth_status()`](https://evanbio.github.io/ukbflow/reference/auth_status.md)、[`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md)
  — RAP 认证
- [`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md)、[`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)、[`fetch_url()`](https://evanbio.github.io/ukbflow/reference/fetch_url.md)、[`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md)
  — RAP 文件系统
- [`fetch_metadata()`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md)、[`fetch_field()`](https://evanbio.github.io/ukbflow/reference/fetch_field.md)
  — UKB 元数据快捷下载

**提取与解码**

- [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)、[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
  — 表型提取
- [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
  — 整数编码 → 可读标签
- [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
  — 字段 ID → snake_case 列名

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

**可视化**

- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  — 森林图（PNG / PDF / JPG / TIFF，300 dpi）
- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  — 基线特征表（DOCX / HTML / PDF / PNG）

**实用工具与诊断**

- [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
  — 环境健康检查（dx CLI、RAP 认证、R 包依赖）
- [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
  — 生成合成 UKB 风格数据，用于开发与测试
- [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md) —
  逐列汇总缺失值（NA 与 `""`）及缺失率
- [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
  — 记录流程检查点，追踪数据集在各步骤的变化
- [`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
  — 从队列中排除 UKB 撤回参与者

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
[CONTRIBUTING.md](https://evanbio.github.io/ukbflow/CONTRIBUTING.md)。

------------------------------------------------------------------------

## 许可证

MIT License © 2026 [Yibin Zhou](mailto:evanzhou.bio@gmail.com)

------------------------------------------------------------------------

**Made with ❤️ by [Yibin Zhou](https://github.com/evanbio)**

[⬆ 回到顶部](#ukbflow)
