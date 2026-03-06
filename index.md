# ukbflow

> RAP-native R workflow for UK Biobank analysis

[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

---

## Overview

**ukbflow** provides a streamlined, RAP-native R workflow for UK Biobank analysis — from phenotype extraction and disease derivation to association analysis and publication-quality figures. All functions are designed to run within the [UK Biobank Research Analysis Platform (RAP)](https://ukbiobank.dnanexus.com), in compliance with the 2024+ data policy requiring individual-level data to remain in the cloud.

## Installation

```r
# Recommended
pak::pkg_install("evanbio/ukbflow")

# or
remotes::install_github("evanbio/ukbflow")
```

**Requirements:** R ≥ 4.1, [dxpy](https://documentation.dnanexus.com/downloads) (local mode only)

## Key Features

**Fetch** — Browse and download files from RAP project storage (`fetch_ls`, `fetch_tree`, `fetch_file`)

**Decode** — Convert raw UKB field IDs and integer codes to human-readable column names and labels (`decode_values`, `decode_names`)

**Derive — Disease Phenotypes** — Build case definitions from HES, cancer registry, self-report, death registry, and First Occurrence fields; merge across sources (`derive_icd10`, `derive_case`)

**Derive — Survival Variables** — Classify prevalent vs. incident disease, compute age at event and follow-up time with competing event support (`derive_timing`, `derive_age`, `derive_followup`)

**Association Analysis** — Cox, logistic, and linear regression with automatic three-model adjustment framework; subgroup analysis, dose-response trend, and Fine-Gray competing risks (`assoc_coxph`, `assoc_subgroup`, `assoc_trend`, `assoc_competing`)

**Visualisation** — Publication-ready forest plots and Table 1, saved in all major formats at 300 dpi (`plot_forest`, `plot_tableone`)

**GRS Pipeline** — End-to-end genetic risk score computation on RAP using plink2: BGEN → PGEN conversion, multi-chromosome scoring, standardisation, and validation (`grs_bgen2pgen`, `grs_score`, `grs_validate`)

## Quick Start

```r
library(ukbflow)

# Authenticate
auth_login()
auth_select_project("project-XXXXXXXXXXXX")

# Extract and decode
df <- extract_pheno(c(31, 21022, 53, 20116, 41270, 41280)) |>
  decode_values() |>
  decode_names()

# Derive disease phenotype + follow-up
df <- df |>
  derive_missing() |>
  derive_icd10(name = "outcome", icd10 = "E11",
               source = c("hes", "first_occurrence")) |>
  derive_followup(name = "outcome", event_col = "outcome_date",
                  baseline_col = "date_baseline",
                  censor_date  = as.Date("2022-06-01"))

# Association analysis
res <- assoc_coxph(df,
  outcome_col  = "outcome_status",
  time_col     = "outcome_followup_years",
  exposure_col = "exposure_status",
  covariates   = c("age_at_recruitment", "sex", "tdi")
)

# Forest plot
plot_forest(res)
```

## Documentation

- **[Get Started](articles/get-started.html)** — Installation and end-to-end workflow
- **[Function Reference](reference/index.html)** — Complete API documentation
- **[Vignettes](articles/index.html)** — Module-by-module tutorials

## Getting Help

- Browse the [function reference](reference/index.html) for detailed documentation
- Read [vignettes](articles/index.html) for step-by-step examples
- Report issues on [GitHub](https://github.com/evanbio/ukbflow/issues)

## License

MIT License © 2026 Evan Zhou
