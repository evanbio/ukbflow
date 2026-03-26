# ukbflow

> RAP-native R workflow for UK Biobank analysis

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://app.codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License:
MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

------------------------------------------------------------------------

## Overview

**ukbflow** provides a streamlined, RAP-native R workflow for UK Biobank
analysis — from phenotype extraction and disease derivation to
association analysis and publication-quality figures. All functions are
designed to run within the [UK Biobank Research Analysis Platform
(RAP)](https://ukbiobank.dnanexus.com), in compliance with the 2024+
data policy requiring individual-level data to remain in the cloud.

## Installation

``` r
# Recommended
pak::pkg_install("evanbio/ukbflow")

# or
remotes::install_github("evanbio/ukbflow")
```

**Requirements:** R ≥ 4.1 ·
[dxpy](https://documentation.dnanexus.com/downloads) (dx-toolkit,
required for RAP interaction)

``` bash
pip install dxpy
```

## Key Features

**Connection** — Authenticate to RAP via dx-toolkit and manage project
selection (`auth_login`, `auth_select_project`)

**Data Access** — Retrieve phenotype data from UKB dataset on RAP;
monitor asynchronous jobs (`fetch_metadata`, `extract_batch`,
`job_wait`)

**Data Processing** — Harmonize multi-source records and derive
analysis-ready cohort: decode field IDs and value codes, build ICD-10
case definitions, compute follow-up time (`decode_names`,
`decode_values`, `derive_icd10`, `derive_followup`, `derive_case`)

**Association Analysis** — Cox, logistic, and linear regression with
automatic three-model adjustment framework; subgroup analysis,
dose-response trend, and Fine-Gray competing risks (`assoc_coxph`,
`assoc_logistic`, `assoc_subgroup`)

**Genomic Scoring** — Distributed plink2 scoring on RAP worker nodes:
BGEN → PGEN conversion, multi-chromosome GRS computation, and
standardisation (`grs_bgen2pgen`, `grs_score`, `grs_standardize`)

**Visualization** — Publication-ready forest plots and Table 1, saved in
all major formats at 300 dpi (`plot_forest`, `plot_tableone`)

**Utilities** — Verify environment before analysis; generate synthetic
UKB-like data for development; diagnose missing values; track cohort
changes across pipeline steps; exclude withdrawn participants
(`ops_setup`, `ops_toy`, `ops_na`, `ops_snapshot`, `ops_withdraw`)

## Quick Start

``` r
library(ukbflow)

# Simulate UKB-style data locally (on RAP: replace with extract_batch() + job_wait())
data <- ops_toy(n = 5000, seed = 2026) |>
  derive_missing()

# Derive lung cancer outcome (ICD-10 C34) and follow-up time
data <- data |>
  derive_icd10(name = "lung", icd10 = "C34",
               source = c("cancer_registry", "hes")) |>
  derive_followup(name         = "lung",
                  event_col    = "lung_icd10_date",
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

## Documentation

- **[Get
  Started](https://evanbio.github.io/ukbflow/articles/get-started.md)**
  — Installation and end-to-end workflow
- **[Function
  Reference](https://evanbio.github.io/ukbflow/reference/index.md)** —
  Complete API documentation
- **[Vignettes](https://evanbio.github.io/ukbflow/articles/index.md)** —
  Module-by-module tutorials

## Getting Help

- Browse the [function
  reference](https://evanbio.github.io/ukbflow/reference/index.md) for
  detailed documentation
- Read [vignettes](https://evanbio.github.io/ukbflow/articles/index.md)
  for step-by-step examples
- Report issues on [GitHub](https://github.com/evanbio/ukbflow/issues)

## License

MIT License © 2026 Yibin Zhou
