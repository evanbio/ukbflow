<div align="center">

<img src="man/figures/logo.png" width="160" alt="ukbflow logo" />

# ukbflow

### *RAP-Native R Workflow for UK Biobank Analysis*

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[📚 Documentation](https://evanbio.github.io/ukbflow/) •
[🚀 Get Started](https://evanbio.github.io/ukbflow/articles/get-started.html) •
[💬 Issues](https://github.com/evanbio/ukbflow/issues) •
[🤝 Contributing](CONTRIBUTING.md)

**Languages:** English | [简体中文](README_zh.md)

</div>

---

## Overview

**ukbflow** provides a streamlined, RAP-native R workflow for UK Biobank analysis — from phenotype extraction and disease derivation to association analysis and publication-quality figures.

> **UK Biobank Data Policy (2024+)**: Individual-level data must remain within the RAP environment. Only summary-level outputs may be downloaded locally. All `ukbflow` functions are designed with this constraint in mind.

```r
library(ukbflow)

# Simulate UKB-style data locally (on RAP: replace with extract_batch() + job_wait())
data <- ops_toy(n = 5000, seed = 2026) |>
  derive_missing()

# Derive lung cancer outcome (ICD-10 C34) and follow-up time
data <- data |>
  derive_icd10(name = "lung", icd10 = "C34",
               source = c("cancer_registry", "hes")) |>
  derive_followup(name        = "lung",
                  event_col   = "lung_icd10_date",
                  baseline_col = "p53_i0",
                  censor_date  = as.Date("2022-10-31"),
                  death_col    = "p40000_i0")

# Define exposure: ever vs. never smoker
data[, smoking_ever := factor(
  ifelse(p20116_i0 == "Never", "Never", "Ever"),
  levels = c("Never", "Ever")
)]

# Cox regression: smoking → lung cancer (3-model adjustment)
res <- assoc_coxph(data,
  outcome_col  = "lung_icd10",
  time_col     = "lung_followup_years",
  exposure_col = "smoking_ever",
  covariates   = c("p21022", "p31", "p22189"))

# Forest plot
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

## Installation

```r
# Recommended
pak::pkg_install("evanbio/ukbflow")

# or
remotes::install_github("evanbio/ukbflow")
```

**Requirements:** R ≥ 4.1 · [dxpy](https://documentation.dnanexus.com/downloads) (dx-toolkit, required for RAP interaction)

```bash
pip install dxpy
```

---

## Core Features

| Layer | Key Functions | Description |
|---|---|---|
| **Connection** | `auth_login`, `auth_select_project` | Authenticate to RAP via dx-toolkit |
| **Data Access** | `fetch_metadata`, `extract_batch`, `job_wait` | Retrieve phenotype data from UKB dataset on RAP |
| **Data Processing** | `decode_names`, `decode_values`, `derive_icd10`, `derive_followup`, `derive_case` | Harmonize multi-source records; derive analysis-ready cohort |
| **Association Analysis** | `assoc_coxph`, `assoc_logistic`, `assoc_subgroup` | Three-model adjustment; subgroup & trend analysis |
| **Genomic Scoring** | `grs_bgen2pgen`, `grs_score`, `grs_standardize` | Distributed plink2 scoring on RAP worker nodes |
| **Visualization** | `plot_forest`, `plot_tableone` | Publication-ready figures & tables |
| **Utilities** | `ops_setup`, `ops_toy`, `ops_na`, `ops_snapshot`, `ops_withdraw` | Environment check, synthetic data, pipeline diagnostics, and cohort management |

---

## Function Reference

<details>
<summary><b>Auth & Fetch</b></summary>

- `auth_login()`, `auth_status()`, `auth_logout()`, `auth_list_projects()`, `auth_select_project()` — RAP authentication
- `fetch_ls()`, `fetch_tree()`, `fetch_url()`, `fetch_file()` — RAP file system
- `fetch_metadata()`, `fetch_field()` — UKB metadata shortcuts

</details>

<details>
<summary><b>Extract & Decode</b></summary>

- `extract_ls()`, `extract_pheno()`, `extract_batch()` — phenotype extraction
- `decode_values()` — integer codes → human-readable labels
- `decode_names()` — field IDs → snake_case column names

</details>

<details>
<summary><b>Job Monitoring</b></summary>

- `job_status()` — query job status by ID
- `job_wait()` — block until job completes (with timeout)
- `job_path()` — get output path of a completed job
- `job_result()` — retrieve job result object
- `job_ls()` — list recent jobs

</details>

<details>
<summary><b>Derive — Phenotypes</b></summary>

- `derive_missing()` — handle "Do not know" / "Prefer not to answer"
- `derive_covariate()` — type conversion + summary
- `derive_cut()` — bin continuous variables
- `derive_selfreport()` — self-reported disease status + date
- `derive_hes()` — HES inpatient ICD-10
- `derive_first_occurrence()` — First Occurrence fields
- `derive_cancer_registry()` — cancer registry
- `derive_death_registry()` — death registry
- `derive_icd10()` — combine sources (wrapper)
- `derive_case()` — merge self-report + ICD-10

</details>

<details>
<summary><b>Derive — Survival</b></summary>

- `derive_timing()` — prevalent vs. incident classification
- `derive_age()` — age at event
- `derive_followup()` — follow-up end date and duration

</details>

<details>
<summary><b>Association Analysis</b></summary>

- `assoc_coxph()` / `assoc_cox()` — Cox proportional hazards (HR)
- `assoc_logistic()` / `assoc_logit()` — logistic regression (OR)
- `assoc_linear()` / `assoc_lm()` — linear regression (β)
- `assoc_coxph_zph()` — proportional hazards assumption test
- `assoc_subgroup()` — stratified analysis + interaction LRT
- `assoc_trend()` — dose-response trend + p_trend
- `assoc_competing()` — Fine-Gray competing risks (SHR)
- `assoc_lag()` — lagged exposure sensitivity analysis

</details>

<details>
<summary><b>Visualisation</b></summary>

- `plot_forest()` — forest plot (PNG / PDF / JPG / TIFF, 300 dpi)
- `plot_tableone()` — Table 1 (DOCX / HTML / PDF / PNG)

</details>

<details>
<summary><b>Utilities &amp; Diagnostics</b></summary>

- `ops_setup()` — environment health check (dx CLI, RAP auth, R packages)
- `ops_toy()` — generate synthetic UKB-like data for development and testing
- `ops_na()` — summarise missing values (NA and `""`) across all columns
- `ops_snapshot()` — record pipeline checkpoints and track dataset changes
- `ops_snapshot_cols()` — retrieve column list from a saved snapshot
- `ops_snapshot_diff()` — compare columns between two snapshots
- `ops_snapshot_remove()` — remove columns added after a given snapshot
- `ops_set_safe_cols()` — define protected columns that ops_snapshot_remove will not drop
- `ops_withdraw()` — exclude UKB withdrawn participants from a cohort

</details>

<details>
<summary><b>GRS Pipeline</b></summary>

- `grs_check()` — validate SNP weights file
- `grs_bgen2pgen()` — convert BGEN → PGEN on RAP (submits cloud jobs)
- `grs_score()` — score GRS across chromosomes with plink2
- `grs_standardize()` / `grs_zscore()` — Z-score standardisation
- `grs_validate()` — OR/HR per SD, high vs low, trend, AUC/C-index

</details>

---

## Documentation

Full vignettes and function reference:

**[https://evanbio.github.io/ukbflow/](https://evanbio.github.io/ukbflow/)**

---

## Contributing

Bug reports, feature requests, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT License © 2026 [Yibin Zhou](mailto:evanzhou.bio@gmail.com)

---

<div align="center">

**Made with ❤️ by [Yibin Zhou](https://github.com/evanbio)**

[⬆ Back to Top](#ukbflow)

</div>
