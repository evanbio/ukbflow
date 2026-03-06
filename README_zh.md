<div align="center">

<img src="man/figures/logo.png" width="160" alt="ukbflow logo" />

# ukbflow

### *面向 UK Biobank 的 RAP 原生 R 分析工作流*

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[📚 文档](https://evanbio.github.io/ukbflow/) •
[🚀 快速开始](https://evanbio.github.io/ukbflow/articles/get-started.html) •
[💬 问题反馈](https://github.com/evanbio/ukbflow/issues) •
[🤝 贡献指南](CONTRIBUTING.md)

**语言：** [English](README.md) | 简体中文

</div>

---

## 简介

**ukbflow** 提供了一套完整的、RAP 原生的 UK Biobank 分析工作流 —— 从表型提取、疾病衍生，到关联分析和发表级图表，全程在 RAP 云端环境中运行。

> **UK Biobank 数据政策（2024+）**：个体水平数据必须保留在 RAP 环境中，不得下载到本地。所有 `ukbflow` 函数均遵循此约束设计。

```r
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

---

## 安装

```r
# 推荐
pak::pkg_install("evanbio/ukbflow")

# 或者
remotes::install_github("evanbio/ukbflow")
```

**环境要求：** R ≥ 4.1，[dxpy](https://documentation.dnanexus.com/downloads)（仅本地模式需要）

---

## 核心功能

<table>
<tr>
<td width="50%">

### 文件获取与提取
- 浏览 RAP 项目文件（`fetch_ls`、`fetch_tree`）
- 下载汇总结果（`fetch_file`）
- 提取 UKB 表型字段（`extract_pheno`）

</td>
<td width="50%">

### 解码
- 值解码：`0/1` → `"Female"/"Male"`（`decode_values`）
- 列名解码：`p31` → `sex`（`decode_names`）

</td>
</tr>
<tr>
<td width="50%">

### 衍生 — 疾病表型
- 自报告、HES、癌症注册、死亡注册
- First Occurrence 字段
- 多源合并（`derive_icd10`、`derive_case`）

</td>
<td width="50%">

### 衍生 — 生存变量
- 患病时间分类（`derive_timing`）
- 事件发生年龄（`derive_age`）
- 随访时间（含竞争事件，`derive_followup`）

</td>
</tr>
<tr>
<td width="50%">

### 关联分析
- Cox、逻辑回归、线性回归
- 亚组分析 + 交互项 LRT
- 剂量-反应趋势、Fine-Gray 竞争风险
- 自动三模型框架（粗模型 → 年龄性别校正 → 全校正）

</td>
<td width="50%">

### 可视化与 GRS
- 森林图（`plot_forest`）
- 基线特征表（`plot_tableone`）
- RAP 端到端 GRS 流程（`grs_check`、`grs_score`、`grs_validate`）

</td>
</tr>
</table>

---

## 函数一览

<details>
<summary><b>认证与文件获取</b></summary>

- `auth_login()`、`auth_status()`、`auth_select_project()` — RAP 认证
- `fetch_ls()`、`fetch_tree()`、`fetch_url()`、`fetch_file()` — RAP 文件系统
- `fetch_metadata()`、`fetch_field()` — UKB 元数据快捷下载

</details>

<details>
<summary><b>提取与解码</b></summary>

- `extract_pheno()`、`extract_batch()` — 表型提取
- `decode_values()` — 整数编码 → 可读标签
- `decode_names()` — 字段 ID → snake_case 列名

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

</details>

<details>
<summary><b>可视化</b></summary>

- `plot_forest()` — 森林图（PNG / PDF / JPG / TIFF，300 dpi）
- `plot_tableone()` — 基线特征表（DOCX / HTML / PDF / PNG）

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

欢迎提交 Bug 报告、功能建议和 PR，详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 许可证

MIT License © 2026 [Evan Zhou](mailto:evanzhou.bio@gmail.com)

---

<div align="center">

**Made with ❤️ by [Evan Zhou](https://github.com/evanbio)**

[⬆ 回到顶部](#ukbflow)

</div>
