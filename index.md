# ukbflow

> RAP-native R workflow for UK Biobank analysis

[![CRAN
status](https://www.r-pkg.org/badges/version/ukbflow)](https://CRAN.R-project.org/package=ukbflow)
[![R-CMD-check](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evanbio/ukbflow/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/evanbio/ukbflow/branch/main/graph/badge.svg)](https://app.codecov.io/gh/evanbio/ukbflow?branch=main)
[![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)

------------------------------------------------------------------------

> \[!NOTE\] 🎉 **2026-04 — ukbflow is now available on CRAN!** Install
> with `install.packages("ukbflow")`.

## Overview

**ukbflow** is an R-native, RAP-aware workflow system for UK Biobank
controlled-data analysis. It provides a coherent workflow layer for
phenotype extraction, disease derivation, association analysis,
reproducible phenotype recipes, audit records, and publication-quality
outputs. It is designed to support workflows on the [UK Biobank Research
Analysis Platform (RAP)](https://ukbiobank.dnanexus.com) under the 2024+
data policy requiring individual-level data to remain in the cloud;
users remain responsible for ensuring that only permitted summary-level
outputs are downloaded.

## Installation

``` r

# From CRAN (recommended)
install.packages("ukbflow")

# Latest development version from GitHub
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

GRS workflows additionally require `plink2` availability in the RAP job
environment.

## Key Features

**Connection** — Authenticate to RAP via dx-toolkit and manage project
selection (`auth_login`, `auth_select_project`)

**Data Access** — Retrieve phenotype, primary-care, proteomic and
metabolomic data from UKB dataset on RAP; monitor asynchronous jobs
(`extract_batch`, `extract_gp`, `extract_olink`, `extract_nmr`,
`job_wait`, `job_result`)

**Data Processing** — Harmonize multi-source records and derive
analysis-ready cohort: decode field IDs and value codes, build ICD-10
case definitions, compute follow-up time (`decode_names`,
`decode_values`, `derive_icd10`, `derive_followup`, `derive_case`)

**Association Analysis** — Cox, logistic, and linear regression with
automatic three-model adjustment framework; subgroup analysis,
categorical and spline dose-response, Fine-Gray competing risks, and
E-value sensitivity to unmeasured confounding (`assoc_coxph`,
`assoc_logistic`, `assoc_subgroup`, `assoc_rcs`, `assoc_evalue`)

**Genomic Scoring** — Distributed plink2 scoring on RAP worker nodes:
BGEN → PGEN conversion, multi-chromosome GRS computation, and
standardization (`grs_bgen2pgen`, `grs_score`, `grs_standardize`)

**Visualization** — Publication-ready forest plots, Kaplan-Meier curves,
spline dose-response curves, and Table 1 outputs in common manuscript
formats (`plot_forest`, `plot_survival`, `plot_rcs`, `plot_tableone`)

**Utilities** — Verify environment before analysis; search approved
project fields, and look up field IDs offline — common fields plus the
blood count, blood biochemistry and NMR panels in full; find the field
IDs behind a First Occurrence or algorithmically-defined outcome; browse
common covariate presets as decoded column names; generate synthetic
UKB-like data for development; diagnose missing values; track cohort
changes across pipeline steps; exclude withdrawn participants
(`ops_setup`, `ops_fields`, `ops_fields_common`, `ops_fo`, `ops_alg`,
`ops_covariates`, `ops_toy`, `ops_na`, `ops_snapshot`, `ops_withdraw`)

**Phenotype Recipes** — Browse, inspect, and flatten a versioned library
of reproducible phenotype definitions, each recording how a phenotype
was operationally defined (sources, codes, logic, caveats); apply one to
a cohort in a single call, and author a new definition without
hand-writing YAML (`recipe_list`, `recipe_get`, `recipe_sources`,
`derive_recipe`, `recipe_rule`, `recipe_new`, `recipe_write`)

**Analysis Audit** — Create lightweight JSON manifests for
reproducibility: field IDs, dataset snapshots, derived phenotype
summaries, versioned phenotype recipes, model result tables, RAP jobs,
and session metadata; read a manifest back and compare labelled records
or two whole audit objects; export a cohort attrition table for a
flowchart-rendering package (`audit_start`, `audit_fields`,
`audit_snapshot`, `audit_pheno`, `audit_recipe`, `audit_model`,
`audit_job`, `audit_write`, `audit_read`, `audit_diff`,
`audit_flowchart`)

## Supported Phenotype Sources

`ukbflow` currently focuses on common UK Biobank disease-phenotype
sources that are routinely available in phenotype extraction workflows:

| Source | Code system / field type | Main function(s) |
|----|----|----|
| Self-reported illness / cancer | UKB fields `20002` / `20001` | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) |
| HES inpatient diagnoses | ICD-10 diagnoses; `position` selects any-position (`41270`) or main/primary (`41202`) | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) |
| HES inpatient diagnoses (ICD-9) | Legacy minority code system; `41271`/`41281` (any), `41203`/`41263` (main) | [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) |
| HES inpatient procedures (OPCS-4) | `41272`/`41282` (any), `41200`/`41260` (main) | [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) |
| GP primary care (Read v2) | `gp_clinical` record table, `read_2` column (fetch with [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)) | [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) |
| GP primary care (CTV3) | `gp_clinical` record table, `read_3` column (fetch with [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)) | [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) |
| First Occurrence fields | UKB precomputed `p131xxx` dates | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) |
| Algorithmically-defined outcomes | UKB Category 42 adjudicated date fields, e.g. `42018` (dementia); self-contained, not routed through [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) | [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md) |
| Cancer registry | ICD-10, histology, behaviour, diagnosis date | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) |
| Cancer registry (ICD-9) | ICD-9 code (`40013`), sharing histology/behaviour/date with the ICD-10 arm | [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) |
| Death registry | ICD-10 underlying / contributory cause of death; `cause` selects primary, secondary, or either | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) |
| Multi-source ICD-10 phenotype | HES, death, First Occurrence, cancer registry | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) |
| Multi-source ICD-9 phenotype | HES (ICD-9), cancer registry (ICD-9) | [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md) |
| Final case definition | Self-report plus ICD-10-derived plus optional ICD-9-, OPCS-4- and GP (Read v2 / CTV3)-derived status/date | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) |

GP prescriptions (`gp_scripts`) and numeric measurement values are not
part of the current public API. UKB’s death registry and First
Occurrence fields have no ICD-9 or OPCS-4 counterpart.

## Limitations

`ukbflow` is a workflow system, not a replacement for the underlying RAP
and statistical tools. It orchestrates and records common analysis steps
around dx-toolkit / DNAnexus jobs, R modelling functions, plotting
packages, and PLINK2-based GRS workflows. It does not provide a general
DAG scheduler, estimate RAP costs, replace the DNAnexus interface, or
determine study design, covariate choice, phenotype validity, or causal
interpretation. Current public phenotype helpers focus on the UKB
sources listed above, including primary-care diagnoses (Read v2 / CTV3);
GP prescriptions and numeric measurements are not covered.

## Quick Start

``` r

library(ukbflow)

# Open an audit manifest: it records what the analysis did as it runs
aud <- audit_start("smoking_lung_cancer")

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

# Forest plot — pass the result straight in; est/CI/columns auto-derived
plot_forest(res)

# Record the model and write the manifest: field IDs, cohort snapshots,
# phenotype summaries, model results and session metadata, as JSON
aud <- audit_model(aud, res)
audit_write(aud, "smoking_lung_cancer_audit.json")
```

## Documentation

- **[Get
  Started](https://evanbio.github.io/ukbflow/articles/get-started.md)**
  — Installation and end-to-end workflow
- **[Phenotype
  Recipes](https://evanbio.github.io/ukbflow/articles/recipe.md)** —
  Reproducible, versioned phenotype definitions
- **[One Phenotype, Many
  Definitions](https://evanbio.github.io/ukbflow/articles/phenotype-reproducibility.md)**
  — Case study on how published UK Biobank phenotype definitions diverge
- **[Analysis
  Audit](https://evanbio.github.io/ukbflow/articles/audit.md)** —
  Lightweight manifests for reproducible analyses
- **[Function
  Reference](https://evanbio.github.io/ukbflow/reference/index.md)** —
  Complete API documentation
- **[Vignettes](https://evanbio.github.io/ukbflow/articles/index.md)** —
  Module-by-module tutorials

## Visual Resources

- **[Tessera](https://folio.evanzhou.org/tessera)** — Browse palettes,
  example datasets, and reproducible R figure recipes.
- **[Palette Lab](https://folio.evanzhou.org/apps/palette-lab)** —
  Compare palettes across a consistent set of graphical displays.

## Getting Help

- Browse the [function
  reference](https://evanbio.github.io/ukbflow/reference/index.md) for
  detailed documentation
- Read [vignettes](https://evanbio.github.io/ukbflow/articles/index.md)
  for step-by-step examples
- Report issues on [GitHub](https://github.com/evanbio/ukbflow/issues)

## License

MIT License © 2026 Yibin Zhou
