# Deriving Disease Phenotypes from UKB Data

## Overview

The `derive_*` functions convert raw, decoded UKB columns into
analysis-ready variables. This vignette covers the disease phenotype
derivation pipeline:

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

> **Prerequisite**: data should have been extracted with
> [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
> or
> [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
> then decoded with
> [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
> and
> [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md).
> See
> [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md).

------------------------------------------------------------------------

## Extracting the Required Fields

The field IDs below are standard UKB field identifiers; actual
availability depends on your project approvals. Include the fields
relevant to your analysis:

``` r
library(ukbflow)

df <- extract_pheno(c(
  31,      # sex
  21022,   # age at recruitment
  53,      # date of baseline assessment (all visit instances)
  20116,   # smoking status
  # --- self-reported non-cancer illness ---
  20002,   # illness codes
  20008,   # year of diagnosis
  # --- self-reported cancer ---
  20001,   # cancer codes
  20006,   # year of cancer diagnosis
  # --- HES inpatient ---
  41270,   # ICD-10 code array
  41280,   # diagnosis date array
  # --- cancer registry ---
  40006,   # ICD-10 type
  40005,   # date of cancer diagnosis
  40011,   # histology
  40012,   # behaviour
  # --- death registry ---
  40001,   # primary cause of death
  40002,   # secondary cause of death
  40000,   # date of death
  # --- censoring / competing events ---
  191      # date lost to follow-up
)) |>
  decode_values() |>
  decode_names()

# Rename the verbose baseline date column to a shorter study-specific alias.
# This is optional but keeps downstream code concise; any name works as long
# as you pass the same name to baseline_col throughout.
names(df)[names(df) == "date_of_attending_assessment_centre_i0"] <- "date_baseline"
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
#> ✔ derive_missing: replaced 4 219 values across 5 columns (action = "na").
```

> **Performance**:
> [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
> uses
> [`data.table::set()`](https://rdrr.io/pkg/data.table/man/assign.html)
> for in-place replacement — no column copies are made regardless of
> dataset size. Processing 500 000 rows typically completes in under a
> second with negligible memory overhead.

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
converts character-encoded numeric columns to `numeric` and categorical
columns to `factor`, printing a distribution summary for each.

``` r
df <- derive_covariate(df,
  as_numeric = "body_mass_index_bmi_i0",
  as_factor  = c("sex", "smoking_status_i0"),
  factor_levels = list(
    smoking_status_i0 = c("Never", "Previous", "Current")
  )
)
#> ── Numeric ──────────────────────────────────────────────────────────────────
#>   body_mass_index_bmi_i0: mean=27.4, median=26.8, sd=4.9, Q1=24.1, Q3=30.1, NA=0.9% (n=4512)
#> ── Factor ───────────────────────────────────────────────────────────────────
#>   sex [2 levels]
#>     Female: n=273 029 (54.4%)
#>     Male:   n=229 068 (45.6%)
#>   smoking_status_i0 [3 levels]
#>     Never:    n=271 400 (54.1%)
#>     Previous: n=150 736 (30.0%)
#>     Current:  n=79 867 (15.9%)
```

------------------------------------------------------------------------

## Step 3: Bin Continuous Variables

[`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
creates a new factor column by binning a continuous variable into
quantile-based or custom groups.

``` r
# Equal-frequency tertiles (automatic breakpoints)
df <- derive_cut(df, col = "age_at_recruitment", n = 3)
# → adds age_at_recruitment_tri with levels Q1 / Q2 / Q3
```

``` r
# Custom breakpoints with meaningful labels
df <- derive_cut(df,
  col    = "age_at_recruitment",
  n      = 3,
  breaks = c(50, 60),
  labels = c("<50", "50–59", "≥60"),
  name   = "age_group"
)
```

------------------------------------------------------------------------

## Step 4: Self-Reported Disease

[`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
searches UKB self-reported non-cancer illness (field 20002) or cancer
(field 20001) columns for a disease label matching a regex, then returns
binary status and the earliest report date.

``` r
# Non-cancer illness example
df <- derive_selfreport(df,
  name  = "disease",
  regex = "your disease name|synonym"
)
#> ✔ derive_selfreport (disease): 8104 cases, 8104 with date.

# Cancer illness example (field = "cancer")
df <- derive_selfreport(df,
  name  = "cancer_outcome",
  regex = "your cancer name",
  field = "cancer"
)
```

This adds two columns:

| Column                    | Type    | Description                    |
|---------------------------|---------|--------------------------------|
| `disease_selfreport`      | logical | `TRUE` if any instance matched |
| `disease_selfreport_date` | IDate   | Earliest report date           |

------------------------------------------------------------------------

## Step 5: HES Inpatient Records

[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
scans UKB Hospital Episode Statistics ICD-10 codes (field 41270, stored
as a JSON array per participant) and matches the earliest corresponding
date from field 41280.

``` r
# Prefix match: codes starting with "E11" (e.g. E110, E119)
df <- derive_hes(df, name = "disease", icd10 = "E11")

# Exact match: only "E11" itself
df <- derive_hes(df, name = "disease", icd10 = "E11", match = "exact")

# Regex: full control over the pattern
df <- derive_hes(df, name = "disease", icd10 = "^E1[01]", match = "regex")
```

The `match` argument controls how codes are compared:

| `match`              | Behaviour                | Example                            |
|----------------------|--------------------------|------------------------------------|
| `"prefix"` (default) | Code starts with pattern | `"E11"` matches `"E110"`, `"E119"` |
| `"exact"`            | Full 3- or 4-digit match | `"E11"` matches only `"E11"`       |
| `"regex"`            | Full regular expression  | `"^E1[01]"`                        |

`match = "regex"` accepts full Perl-compatible regular expressions,
making it straightforward to capture related ICD-10 codes across
chapters or subcategories in a single call (e.g. `"^E1[01]"` captures
both E10 and E11 simultaneously).

------------------------------------------------------------------------

## Step 6: First Occurrence Fields

UKB First Occurrence fields (p131xxx) record the earliest date a
condition was observed across **all linked sources** — self-report, HES
inpatient, GP records, and death registry — pre-integrated by UKB. If
your disease has a corresponding 131xxx field, this is usually the
fastest and most comprehensive single-source case definition. Look up
your disease in the [UKB Field
Finder](https://biobank.ndph.ox.ac.uk/showcase/search.cgi).

``` r
# Look up your disease's First Occurrence field ID in the UKB Field Finder,
# then replace fo_field_id accordingly.
fo_field_id <- 131000L   # <-- replace with your field ID

df <- derive_first_occurrence(df, name = "disease", field = fo_field_id)
#> ✔ derive_first_occurrence (disease): 12043 cases with valid date.
```

------------------------------------------------------------------------

## Step 7: Cancer Registry

[`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
searches the cancer registry ICD-10 field (40006) and optionally filters
by histology (field 40011) and behaviour (field 40012).

``` r
# ICD-10 only — no histology/behaviour filter
df <- derive_cancer_registry(df,
  name  = "cancer_outcome",
  icd10 = "^C50"   # breast cancer example
)
#> ✔ derive_cancer_registry (cancer_outcome): 2 318 cases.

# With histology and behaviour filters
df <- derive_cancer_registry(df,
  name      = "cancer_outcome",
  icd10     = "^C44",
  histology = c(8070, 8071, 8072),   # specify relevant morphology codes
  behaviour = 3L                      # 3 = malignant
)
```

------------------------------------------------------------------------

## Step 8: Death Registry

[`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
searches primary (field 40001) and secondary (field 40002) causes of
death for ICD-10 codes.

``` r
df <- derive_death_registry(df, name = "disease", icd10 = "E11")
#> ✔ derive_death_registry (disease): 312 cases, 312 with date.
```

------------------------------------------------------------------------

## Step 9: Combine Sources with `derive_icd10()`

[`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
is a high-level wrapper that calls any combination of the
source-specific functions above and merges their outputs into a single
status column and earliest date.

``` r
# Non-cancer disease: HES + death + First Occurrence
df <- derive_icd10(df,
  name     = "disease",
  icd10    = "E11",
  source   = c("hes", "death", "first_occurrence"),
  fo_field = fo_field_id   # defined above
)
#> ✔ derive_icd10 (disease): 14 287 cases across 3 sources, 14 287 with date.

# Cancer outcome: HES + cancer registry + death
df <- derive_icd10(df,
  name   = "cancer_outcome",
  icd10  = "^C50",
  match  = "regex",
  source = c("hes", "death", "cancer_registry")
)
```

Intermediate source columns are retained alongside the combined result:

| Column               | Type    | Description                                |
|----------------------|---------|--------------------------------------------|
| `disease_icd10`      | logical | `TRUE` if positive in any specified source |
| `disease_icd10_date` | IDate   | Earliest date across all sources           |
| `disease_hes`        | logical | HES status                                 |
| `disease_hes_date`   | IDate   | HES date                                   |
| `disease_fo`         | logical | First Occurrence status                    |
| `disease_fo_date`    | IDate   | First Occurrence date                      |
| `disease_death`      | logical | Death registry status                      |
| `disease_death_date` | IDate   | Death registry date                        |

------------------------------------------------------------------------

## Step 10: Final Case Definition

[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
merges the self-report and ICD-10 flags into a unified case status, with
the earliest date across both sources taken via
[`pmin()`](https://rdrr.io/r/base/Extremes.html).

``` r
df <- derive_case(df, name = "disease")
#> ✔ derive_case (disease): 15 902 cases, 15 902 with date.
#>   Both sources (disease_icd10 & disease_selfreport): 6 218
```

Output columns:

| Column           | Type    | Description                                   |
|------------------|---------|-----------------------------------------------|
| `disease_status` | logical | `TRUE` if positive in self-report OR ICD-10   |
| `disease_date`   | IDate   | **Earliest** date across all sources (`pmin`) |

> **Why the earliest date matters**: `disease_date` captures the
> earliest available date across contributing sources, regardless of
> which source recorded it first. Sources that are status-positive but
> date-missing do not contribute a date. This column is the direct input
> to
> [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
> [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md),
> and
> [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
> — it is the chronological anchor of every downstream survival
> analysis.

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
