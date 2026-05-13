# ukbflow

> RAP-native R workflow for UK Biobank analysis

[![CRAN status](https://www.r-pkg.org/badges/version/ukbflow)](https://CRAN.R-project.org/package=ukbflow)
[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://app.codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)

---

> [!NOTE]
> 🎉 **2026-04 — ukbflow is now available on CRAN!** Install with `install.packages("ukbflow")`.

## Overview

**ukbflow** provides a streamlined, RAP-native R workflow for UK Biobank analysis — from phenotype extraction and disease derivation to association analysis and publication-quality figures. It is designed to support workflows on the [UK Biobank Research Analysis Platform (RAP)](https://ukbiobank.dnanexus.com) under the 2024+ data policy requiring individual-level data to remain in the cloud; users remain responsible for ensuring that only permitted summary-level outputs are downloaded.

## Installation

```r
# From CRAN (recommended)
install.packages("ukbflow")

# Latest development version from GitHub
pak::pkg_install("evanbio/ukbflow")

# or
remotes::install_github("evanbio/ukbflow")
```

**Requirements:** R ≥ 4.1 · [dxpy](https://documentation.dnanexus.com/downloads) (dx-toolkit, required for RAP interaction)

```bash
pip install dxpy
```

GRS workflows additionally require `plink2` availability in the RAP job environment.

## Key Features

**Connection** — Authenticate to RAP via dx-toolkit and manage project selection (`auth_login`, `auth_select_project`)

**Data Access** — Retrieve phenotype data from UKB dataset on RAP; monitor asynchronous jobs (`fetch_metadata`, `extract_batch`, `job_wait`)

**Data Processing** — Harmonize multi-source records and derive analysis-ready cohort: decode field IDs and value codes, build ICD-10 case definitions, compute follow-up time (`decode_names`, `decode_values`, `derive_icd10`, `derive_followup`, `derive_case`)

**Association Analysis** — Cox, logistic, and linear regression with automatic three-model adjustment framework; subgroup analysis, dose-response trend, and Fine-Gray competing risks (`assoc_coxph`, `assoc_logistic`, `assoc_subgroup`)

**Genomic Scoring** — Distributed plink2 scoring on RAP worker nodes: BGEN → PGEN conversion, multi-chromosome GRS computation, and standardization (`grs_bgen2pgen`, `grs_score`, `grs_standardize`)

**Visualization** — Publication-ready forest plots and Table 1 outputs in common manuscript formats (`plot_forest`, `plot_tableone`)

**Utilities** — Verify environment before analysis; search approved project fields and look up common UKB field IDs; generate synthetic UKB-like data for development; diagnose missing values; track cohort changes across pipeline steps; exclude withdrawn participants (`ops_setup`, `ops_fields`, `ops_fields_common`, `ops_toy`, `ops_na`, `ops_snapshot`, `ops_withdraw`)

**Analysis Audit** — Create lightweight JSON manifests for reproducibility: field IDs, dataset snapshots, derived phenotype summaries, model result tables, and session metadata (`audit_start`, `audit_fields`, `audit_snapshot`, `audit_pheno`, `audit_model`, `audit_write`)

## Supported Phenotype Sources

`ukbflow` currently focuses on common UK Biobank disease-phenotype sources that
are routinely available in phenotype extraction workflows:

| Source | Code system / field type | Main function(s) |
|---|---|---|
| Self-reported illness / cancer | UKB fields `20002` / `20001` | `derive_selfreport()` |
| HES inpatient diagnoses | ICD-10, any-position field `41270` with dates from `41280`; primary/secondary position is not currently configurable | `derive_hes()` |
| First Occurrence fields | UKB precomputed `p131xxx` dates | `derive_first_occurrence()` |
| Cancer registry | ICD-10, histology, behaviour, diagnosis date | `derive_cancer_registry()` |
| Death registry | ICD-10 primary / secondary cause of death | `derive_death_registry()` |
| Multi-source ICD-10 phenotype | HES, death, First Occurrence, cancer registry | `derive_icd10()` |
| Final case definition | Self-report plus ICD-10-derived status/date | `derive_case()` |

ICD-9, OPCS-4, Read v2, CTV3, and other GP / primary-care code systems are not
part of the current public API.

## Quick Start

```r
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

- **[ukbflow Book](https://ukbflow.evanzhou.org)** — Practical RAP-native workflows, examples, and module notes
- **[Get Started](articles/get-started.html)** — Installation and end-to-end workflow
- **[Analysis Audit](articles/audit.html)** — Lightweight manifests for reproducible analyses
- **[Function Reference](reference/index.html)** — Complete API documentation
- **[Vignettes](articles/index.html)** — Module-by-module tutorials

## Getting Help

- Browse the [function reference](reference/index.html) for detailed documentation
- Read [vignettes](articles/index.html) for step-by-step examples
- Report issues on [GitHub](https://github.com/evanbio/ukbflow/issues)

## License

MIT License © 2026 Yibin Zhou
