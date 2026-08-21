# Deriving Disease Phenotypes from UKB Data

## Overview

The `derive_*` functions convert raw UKB columns into analysis-ready
variables. This vignette covers the disease phenotype derivation
pipeline:

| Step | Function(s) | Purpose |
|----|----|----|
| 1 | [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md) | Handle “Do not know” / “Prefer not to answer” |
| 2 | [`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md) | Convert types; summarise covariates |
| 3 | [`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md) | Bin continuous variables into groups |
| 4 | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) | Self-reported disease status + date |
| 5 | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) / [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) / [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) / [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) / [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) | HES inpatient (ICD-10 / ICD-9 diagnoses, OPCS-4 procedures) + GP primary-care (Read v2 / CTV3) status + date |
| 6 | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) | First Occurrence field status + date |
| 7 | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) / [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) | Cancer registry ICD-10 / ICD-9 status + date |
| 8 | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) | Death registry ICD-10 status + date |
| 9 | [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md) | Algorithmically-defined outcome (ADO) status + date, self-contained |
| 10 | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) / [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md) | Combine any subset of ICD-10 / ICD-9 sources (wrappers) |
| 11 | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) | Merge self-report + ICD-10 + optional ICD-9 / OPCS-4 / GP (Read v2 / CTV3) into final case definition |
| 12 | [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md) | Run a bundled phenotype recipe end-to-end (steps 4-11 in one call) |

Current phenotype-source support is intentionally scoped to the common
UKB sources below:

| Source | Code system / field type | Main function(s) |
|----|----|----|
| Self-reported illness / cancer | UKB fields `20002` / `20001` | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) |
| HES inpatient diagnoses | ICD-10 diagnoses; `position` selects any-position (`41270`) or main/primary (`41202`) | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) |
| HES inpatient diagnoses (ICD-9) | Legacy minority code system; `41271` / `41281` (any), `41203` / `41263` (main) | [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) |
| HES inpatient procedures (OPCS-4) | `41272` / `41282` (any), `41200` / `41260` (main) | [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) |
| GP primary care (Read v2) | `gp_clinical` record table, `read_2` column (fetch with [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)) | [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) |
| GP primary care (CTV3 / Read v3) | `gp_clinical` record table, `read_3` column (fetch with [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)) | [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) |
| First Occurrence fields | UKB precomputed `p131xxx` dates | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) |
| Cancer registry | ICD-10, histology, behaviour, diagnosis date | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) |
| Cancer registry (ICD-9) | ICD-9 code (`40013`), sharing histology/behaviour/date with the ICD-10 arm | [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) |
| Death registry | ICD-10 primary / secondary cause of death | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) |
| Algorithmically-defined outcome (ADO) | UKB Category 42 adjudicated Date fields, e.g. `42018` (dementia), `42006` (stroke) | [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md) |
| Multi-source ICD-10 phenotype | HES, death, First Occurrence, cancer registry | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) |
| Multi-source ICD-9 phenotype | HES (ICD-9), cancer registry (ICD-9) | [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md) |
| Final case definition | Self-report plus ICD-10-derived plus optional ICD-9-, OPCS-4- and GP (Read v2 / CTV3)-derived status/date | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) |

GP prescriptions (`gp_scripts`) and numeric measurement values
(`value1`-`value3`) are not part of the current public API. UKB’s death
registry and First Occurrence fields have no ICD-9 or OPCS-4 counterpart
to expose (see Step 10 below for why).

All functions accept a `data.frame` or `data.table` and return a
`data.table`. For `data.table` input, new columns are added **by
reference** (no copy); `data.frame` input is converted to `data.table`
internally before modification.

Every `derive_*()` returns its result **invisibly**, so calling one
without assigning prints nothing but the one-line summary of how many
cases and dates were found. Assign the result back —
`df <- derive_hes(df, ...)` — which is also what `data.frame` input
requires, since there the new columns land only on the returned object.

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

By default (`position = "any"`)
[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
uses field 41270, which contains ICD-10 codes recorded in any diagnosis
position, so any matching code counts as a case. Pass
`position = "main"` to restrict to primary diagnoses (fields 41202 /
41262). Secondary-only selection is not offered because UKB provides no
aligned per-code date field for secondary diagnoses (field 41204).

``` r

# Prefix match: codes starting with "I10" (hypertension)
df <- derive_hes(df, name = "htn", icd10 = "I10")

# Exact match
df <- derive_hes(df, name = "dm_hes", icd10 = "E11", match = "exact")

# Regex: E10 and E11 simultaneously
df <- derive_hes(df, name = "dm_broad", icd10 = "^E1[01]", match = "regex")
```

The `match` argument controls how codes are compared:

| `match` | Behaviour | Example |
|----|----|----|
| `"prefix"` (default) | Code starts with pattern | `"E11"` matches `"E110"`, `"E119"` |
| `"exact"` | Full 3- or 4-digit match | `"E11"` matches only `"E11"` |
| `"regex"` | Full regular expression | `"^E1[01]"` |

### ICD-9 variant: `derive_hes_icd9()`

A minority of HES records — mostly older Scottish records that predate
the UK-wide transition to ICD-10 — are coded in ICD-9.
[`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md)
is the ICD-9 counterpart of
[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
with the identical field structure shifted to the parallel ICD-9 fields:
`41271` / `41281` for any-position diagnoses, `41203` / `41263` for
main-diagnosis-only. Same `match` and `position` arguments, same
semantics.

``` r

df <- derive_hes_icd9(df, name = "dem9", icd9 = c("331.0", "290.4"))
```

Output columns are named `dem9_hes_icd9` / `dem9_hes_icd9_date` — a
separate suffix from
[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)’s
`_hes` / `_hes_date` — so an ICD-10 and an ICD-9 call for the same
phenotype `name` can both run without one overwriting the other’s
columns.

### OPCS-4 procedures: `derive_opcs()`

HES also records **operations and procedures** in OPCS-4, on a parallel
field pair to the diagnosis fields: `41272` / `41282` for any-position
codes, `41200` / `41260` for the main procedure only.
[`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md)
is the OPCS-4 counterpart of
[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
with the same `match` and `position` arguments and semantics. OPCS-4
codes are stored in **dotted** format, like ICD-10 (e.g. `K40`,
`K23.4`), so transcribe them from a paper as written — under
`match = "prefix"` a 3-character category such as `K40` matches all its
children (`K40.1`, `K40.2`, …).

``` r

# Coronary revascularisation procedures (the K40 category matches K40.1, etc.)
df <- derive_opcs(df, name = "cabg", opcs = c("K40", "K41", "K44", "K45"))
```

Output columns are named `cabg_opcs` / `cabg_opcs_date`, a separate
suffix again, so a diagnosis and a procedure call for the same `name`
coexist.

### GP primary care: `derive_gp_read2()` / `derive_gp_ctv3()`

Primary-care (GP) clinical events live in the **`gp_clinical`** record
table (UKB Record Table 1060), *not* in participant fields — one row per
coded event, ~118M rows across ~45% of the cohort. It carries **two**
coding systems in two columns: Read v2 in `read_2` (England Vision,
Scotland, Wales) and CTV3 / Read v3 in `read_3` (England TPP). These are
separate coding systems — like ICD-10 vs ICD-9 for HES — so they are
handled by two functions with their own code lists:
[`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
and
[`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md).

Because `gp_clinical` is a separate long table, you pass it in as `gp`
(loaded once with
[`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md),
reused across calls). Read v2 codes are 5-character, dot-padded and
**case-sensitive**; CTV3 codes are opaque identifiers, so both default
to `match = "exact"` (a prefix is meaningful for Read v2’s positional
hierarchy but not for CTV3).

`ops_toy(scenario = "gp")` returns a synthetic table with the same
columns, so the GP path can be exercised offline. Use the same `n` and
`seed` as the cohort call so the `eid` values line up:

``` r

# gp is the gp_clinical long table: eid, data_provider, read_2, read_3, event_dt
# Same n and seed as the ops_toy(n = 500) cohort above, so the eids line up
gp <- ops_toy(scenario = "gp", n = 500)

df <- derive_gp_read2(df, name = "t2d", read2 = c("C1041", "C10F6"), gp = gp)
df <- derive_gp_ctv3 (df, name = "t2d", ctv3  = "XaELQ",             gp = gp)
```

On the RAP the same calls take the real table from
[`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md):

``` r

gp <- extract_gp()   # load gp_clinical once, reuse across calls
df <- derive_gp_read2(df, name = "t2d", read2 = c("C10F.", "C10F0"), gp = gp)
df <- derive_gp_ctv3 (df, name = "t2d", ctv3  = "XaELP",             gp = gp)
```

Output columns are `t2d_gp_read2` / `t2d_gp_ctv3` (plus `_date`). UKB
placeholder event dates (Coding 819: 1901-01-01, 1902-02-02, …) still
count for status but never supply a date.

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

### ICD-9 variant: `derive_cancer_registry_icd9()`

A minority of cancer registrations (older records) are coded in ICD-9
(field `40013`) instead of ICD-10 (`40006`).
[`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md)
matches against `40013` but reuses the *same* histology (`40011`),
behaviour (`40012`), and diagnosis-date (`40005`) fields as the ICD-10
arm — a given registration instance carries a code in either `40006` or
`40013`, never both, and its date/histology/behaviour live in the shared
fields at that same instance number. `40013` has fewer instances than
`40006` (it is the smaller, legacy minority), but instances are matched
by registration number rather than array position, so this size
difference causes no misalignment.

``` r

df <- derive_cancer_registry_icd9(df,
  name      = "skin_cancer9",
  icd9      = "^173",
  behaviour = 3L
)
```

Output columns are `skin_cancer9_cancer_icd9` /
`skin_cancer9_cancer_icd9_date` — separate from
[`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)’s
`_cancer` / `_cancer_date` suffix, for the same reason as the HES pair
above.

------------------------------------------------------------------------

## Step 8: Death Registry

[`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
searches primary (field 40001) and secondary (field 40002) causes of
death for ICD-10 codes. By default (`cause = "any"`) a match in either
position counts; pass `cause = "primary"` to restrict to the underlying
cause of death only, or `cause = "secondary"` for contributory causes.

``` r

df <- derive_death_registry(df, name = "mi",   icd10 = "I21")
df <- derive_death_registry(df, name = "dm",   icd10 = "E11")
df <- derive_death_registry(df, name = "lung", icd10 = "C34")
```

------------------------------------------------------------------------

## Step 9: Algorithmically-Defined Outcomes with `derive_algorithm()`

Some phenotypes are best ascertained not from raw codes but from UK
Biobank’s **algorithmically-defined outcomes** (ADOs, Category 42):
adjudicated *Date* fields — e.g. `42018` (all-cause dementia), `42006`
(stroke), `42016` (COPD) — that UKB has already reconciled across
self-report, HES, and death records.
[`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md)
reads one such Date field and produces a `{name}_alg` status flag and a
`{name}_alg_date`.

[`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
ships `p42018` (all-cause dementia), including a few rows carrying the
`1900-01-01` sentinel — a self-report-only case with unknown onset year.
The sentinel is deliberately filtered to `NA` and does **not** count as
a case, so that every positive case carries a usable date:

``` r

derive_algorithm(df, name = "dementia", field = 42018L)
#> ✔ derive_algorithm (dementia): 79 cases with valid date.
#> ℹ   4 self-report-only records with unknown onset year (1900-01-01) set to NA (not counted as cases).

df[!is.na(p42018), .(eid, p42018, dementia_alg, dementia_alg_date)][1:4]
#>         eid     p42018 dementia_alg dementia_alg_date
#>       <int>     <char>       <lgcl>            <IDat>
#> 1: 10000016 2007-03-09         TRUE        2007-03-09
#> 2: 10000021 2004-04-28         TRUE        2004-04-28
#> 3: 10000022 1900-01-01        FALSE              <NA>
#> 4: 10000027 1900-01-01        FALSE              <NA>
```

An ADO is **self-contained**: `{name}_alg` / `{name}_alg_date` already
*is* the final case definition, because the adjudication reconciles the
sources internally. Feed these two columns straight into `assoc_*` via
`outcome_col` / `time_col`. Do **not** route an ADO through
[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
or pass it to
[`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
(it is not an ICD-10 code source), and do not pair it with a separate
[`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
for the same phenotype — that would double-count self-report and admit a
date the algorithm deliberately excluded.

------------------------------------------------------------------------

## Step 10: Combine Sources with `derive_icd10()`

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

### ICD-9 variant: `derive_icd9()`

[`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)
is the ICD-9 counterpart, combining
[`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md)
and
[`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).
Only two sources are offered — `"hes"` and `"cancer_registry"` — because
UKB’s death registry (ICD-10 only since 2001) and First Occurrence
fields (a UKB-computed reconciliation across sources) have no ICD-9
counterpart to expose.

``` r

df <- derive_icd9(df,
  name  = "dem9",
  icd9  = c("331.0", "290.4"),
  source = c("hes", "cancer_registry")
)
```

| Column | Type | Description |
|----|----|----|
| `dem9_icd9` | logical | `TRUE` if positive in any specified ICD-9 source |
| `dem9_icd9_date` | IDate | Earliest date across all ICD-9 sources |
| `dem9_hes_icd9` | logical | HES (ICD-9) status |
| `dem9_hes_icd9_date` | IDate | HES (ICD-9) date |
| `dem9_cancer_icd9` | logical | Cancer registry (ICD-9) status |
| `dem9_cancer_icd9_date` | IDate | Cancer registry (ICD-9) date |

------------------------------------------------------------------------

## Step 11: Final Case Definition

[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
applies an any-source reconciliation rule by default. The final status
is `TRUE` if any of the ICD-10-derived, ICD-9-derived, OPCS-4-derived,
GP (Read v2 / CTV3)-derived, or self-report status is `TRUE`; this is an
OR rule, not a medical-record confirmation rule. The final date is the
earliest available date across the included sources, computed with
[`pmin()`](https://rdrr.io/r/base/Extremes.html). The optional ICD-9,
OPCS-4 and GP arms are folded in only when their columns are present.

Use `derive_icd10(source = ...)` to control which medical / registry
sources enter the ICD-10-derived status before calling
[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md).
If only one of `{name}_icd10` or `{name}_selfreport` is present,
[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
uses that available source alone and prints a warning.

``` r

df <- derive_case(df, name = "dm")
```

Single-source case definitions are also possible. For an ICD-10-derived
medical / registry definition, run
[`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
for a distinct `name` and do not create the matching self-report
columns:

``` r

df <- derive_icd10(df,
  name   = "dm_medical",
  icd10  = "E11",
  source = c("hes", "death", "first_occurrence"),
  fo_col = "p131742"
)
df <- derive_case(df, name = "dm_medical")
```

For a self-report-only definition, run
[`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
for a distinct `name` and do not create the matching ICD-10-derived
columns:

``` r

df <- derive_selfreport(df,
  name  = "dm_selfonly",
  regex = "type 2 diabetes"
)
df <- derive_case(df, name = "dm_selfonly")
```

### Folding in an ICD-9 arm

When
[`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)
has also been run for the same `name`, its output (`{name}_icd9` /
`{name}_icd9_date`) is picked up automatically as a third source — no
extra argument needed. This is opt-in and silent: most phenotypes have
no ICD-9 arm, so its absence is the expected case and does not trigger
the “only one status column found” warning.

``` r

df <- derive_icd10(df, name = "dem", icd10 = "F00",  source = "hes")
df <- derive_icd9(df,  name = "dem", icd9  = "290.0", source = "hes")
df <- derive_case(df, name = "dem")   # ORs in dem_icd10, dem_icd9, dem_selfreport
```

Output columns:

| Column | Type | Description |
|----|----|----|
| `dm_status` | logical | `TRUE` if positive in self-report, ICD-10, or (when present) ICD-9 |
| `dm_date` | IDate | **Earliest** date across all sources (`pmin`) |

> **Why the earliest date matters**: `dm_date` is the direct input to
> [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
> [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md),
> and
> [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
> — it is the chronological anchor of every downstream survival
> analysis. See
> [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md).

------------------------------------------------------------------------

## Step 12: Run a Bundled Recipe End-to-End

Steps 4-11 above are what you write by hand for a phenotype you define
yourself. When the definition already exists as a bundled, citable
recipe
([`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)),
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
runs that whole chain in one call — dispatching every source rule to the
matching `derive_*` function above and combining the results per the
recipe’s `logic`:

``` r

df <- derive_recipe(df, id = "type_2_diabetes", name = "t2d")
```

Unlike steps 4-11, which each add named intermediate columns,
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
only ever adds two: `t2d_status` (logical) and `t2d_date` (IDate) —
every source- and rule-level contribution is reported via `cli` as the
recipe runs, not retained as extra columns. See
[`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md)
for the recipe library itself and the rule-to-`derive_*` mapping
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
follows internally.

------------------------------------------------------------------------

## Getting Help

- [`?derive_missing`](https://evanbio.github.io/ukbflow/reference/derive_missing.md),
  [`?derive_covariate`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md),
  [`?derive_cut`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
- [`?derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md),
  [`?derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
  [`?derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md),
  [`?derive_opcs`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md),
  [`?derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md),
  [`?derive_gp_ctv3`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md),
  [`?derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md)
- [`?derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md),
  [`?derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md),
  [`?derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
- [`?derive_algorithm`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md),
  [`?derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md),
  [`?derive_icd9`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md),
  [`?derive_case`](https://evanbio.github.io/ukbflow/reference/derive_case.md),
  [`?derive_recipe`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
- [`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md)
  — the phenotype recipe library
- [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md)
  — timing, age at event, follow-up
- [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md)
  — decoding column names and values
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
