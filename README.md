<div align="center">

<img src="man/figures/logo.png" width="160" alt="ukbflow logo" />

# ukbflow

### *RAP-Native R Workflow for UK Biobank Analysis*

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
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

# Authenticate and extract
auth_login()
df <- extract_pheno(c(31, 21022, 53, 20116, 41270, 41280)) |>
  decode_values() |>
  decode_names()

# Derive disease phenotype
df <- df |>
  derive_missing() |>
  derive_icd10(name = "outcome", icd10 = "E11",
               source = c("hes", "first_occurrence")) |>
  derive_followup(name = "outcome", event_col = "outcome_date",
                  baseline_col = "date_baseline",
                  censor_date  = as.Date("2022-06-01"))

# Association analysis → forest plot
res <- assoc_coxph(df, outcome_col = "outcome_status",
                   time_col = "outcome_followup_years",
                   exposure_col = "exposure_status",
                   covariates = c("age_at_recruitment", "sex", "tdi"))
plot_forest(res)
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
| **Utilities** | `ops_setup`, `ops_toy`, `ops_na`, `ops_snapshot` | Environment check, synthetic data, and pipeline diagnostics |

---

## Function Reference

<details>
<summary><b>Auth & Fetch</b></summary>

- `auth_login()`, `auth_status()`, `auth_select_project()` — RAP authentication
- `fetch_ls()`, `fetch_tree()`, `fetch_url()`, `fetch_file()` — RAP file system
- `fetch_metadata()`, `fetch_field()` — UKB metadata shortcuts

</details>

<details>
<summary><b>Extract & Decode</b></summary>

- `extract_pheno()`, `extract_batch()` — phenotype extraction
- `decode_values()` — integer codes → human-readable labels
- `decode_names()` — field IDs → snake_case column names

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
