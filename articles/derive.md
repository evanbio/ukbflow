# Deriving Disease Phenotypes from UKB Data

## Overview

The `derive_*` functions convert raw UKB columns into analysis-ready
variables. This vignette covers the disease phenotype derivation
pipeline:

| Step | Function(s)                                                                                           | Purpose                                               |
|------|-------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| 1    | [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)                   | Handle “Do not know” / “Prefer not to answer”         |
| 2    | [`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md)               | Convert types; summarise covariates                   |
| 3    | [`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)                           | Bin continuous variables into groups                  |
| 4    | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)             | Self-reported disease status + date                   |
| 5    | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)                           | HES inpatient ICD-10 status + date                    |
| 6    | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) | First Occurrence field status + date                  |
| 7    | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)   | Cancer registry status + date                         |
| 8    | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)     | Death registry ICD-10 status + date                   |
| 9    | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)                       | Combine any subset of sources (wrapper)               |
| 10   | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)                         | Merge self-report + ICD-10 into final case definition |

All functions accept a `data.frame` or `data.table` and return a
`data.table`. For `data.table` input, new columns are added **by
reference** (no copy); `data.frame` input is converted to `data.table`
internally before modification.

> **In production**, replace
> [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
> with
> [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
> followed by
> [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
> and
> [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md).
> See
> [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md).
> Column names below use the RAP raw format
> (`p{field}_{instance}_{array}`) as returned by
> [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
> and
> [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
> before decoding.

------------------------------------------------------------------------

## Setup

``` r
library(ukbflow)

df <- ops_toy(n = 500)
```

------------------------------------------------------------------------

## Step 1: Handle Informative Missing Labels

UKB uses special labels such as `"Do not know"` and
`"Prefer not to answer"` to distinguish refusal from true missing data.
[`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
converts these to `NA` (default) or retains them as `"Unknown"` for
modelling.

``` r
df <- derive_missing(df)
```

> **Performance**:
> [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
> uses
> [`data.table::set()`](https://rdrr.io/pkg/data.table/man/assign.html)
> for in-place replacement — no column copies are made regardless of
> dataset size.

To keep non-response as a model category:

``` r
df <- derive_missing(df, action = "unknown")
```

To add custom labels beyond the built-in list:

``` r
df <- derive_missing(df, extra_labels = "Not applicable")
```

------------------------------------------------------------------------

## Step 2: Prepare Covariates

[`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md)
converts categorical columns to `factor` and prints a distribution
summary for each.

``` r
df <- derive_covariate(
  df,
  as_factor = c(
    "p31",        # sex
    "p20116_i0",  # smoking_status_i0
    "p1558_i0"    # alcohol_intake_frequency_i0
  ),
  factor_levels = list(
    p20116_i0 = c("Never", "Previous", "Current")
  )
)
```

------------------------------------------------------------------------

## Step 3: Bin Continuous Variables

[`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
creates a new factor column by binning a continuous variable into
quantile-based or custom groups.

``` r
df <- derive_cut(
  df,
  col    = "p21001_i0",                              # body_mass_index_bmi_i0
  n      = 4,
  breaks = c(18.5, 25, 30),
  labels = c("Underweight", "Normal", "Overweight", "Obese"),
  name   = "bmi_cat"
)

df <- derive_cut(
  df,
  col    = "p22189",                                 # townsend_deprivation_index_at_recruitment
  n      = 4,
  labels = c("Q1 (least deprived)", "Q2", "Q3", "Q4 (most deprived)"),
  name   = "tdi_cat"
)
```

------------------------------------------------------------------------

## Step 4: Self-Reported Disease

[`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
searches UKB self-reported non-cancer illness (field 20002) or cancer
(field 20001) columns for a disease label matching a regex, then returns
binary status and the earliest report date. Column detection is
automatic from field IDs.

``` r
# Non-cancer: type 2 diabetes (field 20002)
df <- derive_selfreport(df,
  name  = "dm",
  regex = "type 2 diabetes"
)
```

``` r
# Cancer: lung cancer (field 20001)
df <- derive_selfreport(df,
  name  = "lung_cancer",
  regex = "lung cancer",
  field = "cancer"
)
```

This adds two columns per call:

| Column               | Type    | Description                    |
|----------------------|---------|--------------------------------|
| `dm_selfreport`      | logical | `TRUE` if any instance matched |
| `dm_selfreport_date` | IDate   | Earliest report date           |

------------------------------------------------------------------------

## Step 5: HES Inpatient Records

[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
scans UKB Hospital Episode Statistics ICD-10 codes (field 41270, stored
as a JSON array per participant) and matches the earliest corresponding
date from field 41280.

``` r
# Prefix match: codes starting with "I10" (hypertension)
df <- derive_hes(df, name = "htn", icd10 = "I10")

# Exact match
df <- derive_hes(df, name = "dm_hes", icd10 = "E11", match = "exact")

# Regex: E10 and E11 simultaneously
df <- derive_hes(df, name = "dm_broad", icd10 = "^E1[01]", match = "regex")
```

The `match` argument controls how codes are compared:

| `match`              | Behaviour                | Example                            |
|----------------------|--------------------------|------------------------------------|
| `"prefix"` (default) | Code starts with pattern | `"E11"` matches `"E110"`, `"E119"` |
| `"exact"`            | Full 3- or 4-digit match | `"E11"` matches only `"E11"`       |
| `"regex"`            | Full regular expression  | `"^E1[01]"`                        |

------------------------------------------------------------------------

## Step 6: First Occurrence Fields

UKB First Occurrence fields (p131xxx) record the earliest date a
condition was observed across **all linked sources** — self-report, HES
inpatient, GP records, and death registry — pre-integrated by UKB. Look
up your disease in the [UKB Field
Finder](https://biobank.ndph.ox.ac.uk/showcase/search.cgi).

``` r
# ops_toy includes p131742 as a representative First Occurrence column
df <- derive_first_occurrence(df, name = "htn", field = 131742L, col = "p131742")
```

------------------------------------------------------------------------

## Step 7: Cancer Registry

[`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
searches the cancer registry ICD-10 field (40006) and optionally filters
by histology (field 40011) and behaviour (field 40012).

``` r
# ICD-10 only
df <- derive_cancer_registry(df,
  name  = "skin_cancer",
  icd10 = "^C44"
)

# With histology and behaviour filters
df <- derive_cancer_registry(df,
  name      = "scc",
  icd10     = "^C44",
  histology = c(8070L, 8071L, 8072L),
  behaviour = 3L                        # 3 = malignant
)
```

------------------------------------------------------------------------

## Step 8: Death Registry

[`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
searches primary (field 40001) and secondary (field 40002) causes of
death for ICD-10 codes.

``` r
df <- derive_death_registry(df, name = "mi",   icd10 = "I21")
df <- derive_death_registry(df, name = "dm",   icd10 = "E11")
df <- derive_death_registry(df, name = "lung", icd10 = "C34")
```

------------------------------------------------------------------------

## Step 9: Combine Sources with `derive_icd10()`

[`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
is a high-level wrapper that calls any combination of the
source-specific functions above and merges their outputs into a single
status column and earliest date. This is the recommended approach for
multi-source ascertainment.

``` r
# Non-cancer disease: HES + death + First Occurrence
df <- derive_icd10(df,
  name   = "dm",
  icd10  = "E11",
  source = c("hes", "death", "first_occurrence"),
  fo_col = "p131742"
)

# Cancer outcome: cancer registry
df <- derive_icd10(df,
  name      = "lung",
  icd10     = "^C3[34]",
  match     = "regex",
  source    = "cancer_registry",
  behaviour = 3L
)
```

Intermediate source columns are retained alongside the combined result:

| Column          | Type    | Description                                |
|-----------------|---------|--------------------------------------------|
| `dm_icd10`      | logical | `TRUE` if positive in any specified source |
| `dm_icd10_date` | IDate   | Earliest date across all sources           |
| `dm_hes`        | logical | HES status                                 |
| `dm_hes_date`   | IDate   | HES date                                   |
| `dm_fo`         | logical | First Occurrence status                    |
| `dm_fo_date`    | IDate   | First Occurrence date                      |
| `dm_death`      | logical | Death registry status                      |
| `dm_death_date` | IDate   | Death registry date                        |

------------------------------------------------------------------------

## Step 10: Final Case Definition

[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
merges the self-report and ICD-10 flags into a unified case status, with
the earliest date across both sources taken via
[`pmin()`](https://rdrr.io/r/base/Extremes.html).

``` r
df <- derive_case(df, name = "dm")
```

Output columns:

| Column      | Type    | Description                                   |
|-------------|---------|-----------------------------------------------|
| `dm_status` | logical | `TRUE` if positive in self-report OR ICD-10   |
| `dm_date`   | IDate   | **Earliest** date across all sources (`pmin`) |

> **Why the earliest date matters**: `dm_date` is the direct input to
> [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
> [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md),
> and
> [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
> — it is the chronological anchor of every downstream survival
> analysis. See
> [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md).

------------------------------------------------------------------------

## Getting Help

- [`?derive_missing`](https://evanbio.github.io/ukbflow/reference/derive_missing.md),
  [`?derive_covariate`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md),
  [`?derive_cut`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
- [`?derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md),
  [`?derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
  [`?derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md)
- [`?derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md),
  [`?derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
- [`?derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md),
  [`?derive_case`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
- [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md)
  — timing, age at event, follow-up
- [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md)
  — decoding column names and values
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
