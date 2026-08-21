# Operational Utilities: Setup, Diagnostics, and Pipeline Tracking

## Overview

The `ops_*` functions are a set of lightweight utilities that sit
outside the main analysis pipeline. They help you verify your
environment before starting, explore data quality, and track how your
cohort changes at each processing step.

| Function | Purpose |
|----|----|
| [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md) | Check dx CLI, RAP authentication, and R package dependencies |
| [`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md) | Search the approved UKB fields in the active RAP project |
| [`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md) | Offline field reference: common fields, plus the blood count, blood biochemistry and NMR panels in full |
| [`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md) | Look up the date and source field IDs of a First Occurrence outcome |
| [`ops_alg()`](https://evanbio.github.io/ukbflow/reference/ops_alg.md) | Look up the date and source field IDs of an algorithmically-defined outcome |
| [`ops_covariates()`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md) | Look up common covariate presets as decoded column names |
| [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md) | Generate synthetic UKB-like data for development and testing |
| [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md) | Summarise missing values (NA and `""`) across all columns |
| [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md) | Record pipeline checkpoints and track dataset changes |

[`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
and
[`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
query the RAP (dx CLI / project field list); everything else operates
entirely locally.
[`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md),
[`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md),
[`ops_alg()`](https://evanbio.github.io/ukbflow/reference/ops_alg.md),
[`ops_covariates()`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md),
[`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md),
and [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
are read-only offline lookups or diagnostics;
[`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
and its companions track and optionally clean up columns;
[`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
removes withdrawn participants in-place. None of them write to RAP
storage.

------------------------------------------------------------------------

## `ops_setup()` — Environment Health Check

Run
[`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
once after installing ukbflow to confirm that all required components
are in place before starting a real analysis.

``` r

library(ukbflow)

ops_setup()
#> ── ukbflow environment check ──────────────────────────────────────────────
#> ℹ ukbflow 0.3.4  |  R 4.5.1  |  2026-08-11
#> ── 1. dx-toolkit ──────────────────────────────────────────────────────────
#> ✔ dx: /usr/local/bin/dx  (dx-toolkit v0.375.0)
#> ── 2. RAP authentication ───────────────────────────────────────────────────
#> ✔ user: evan.zhou
#> ✔ project: project-GXk9...
#> ── 3. R packages ───────────────────────────────────────────────────────────
#> ✔ cli  3.6.3  [core]
#> ✔ data.table  1.15.4  [core]
#> ✔ survival  3.7.0  [assoc_coxph]
#> ✔ forestploter  1.1.1  [plot_forest]
#> ...
#> ───────────────────────────────────────────────────────────────────────────
#> ✔ 15 passed
#> ! 2 optional / warning
```

For programmatic use (e.g. inside scripts or CI), set `verbose = FALSE`
and inspect the returned list:

``` r

result <- ops_setup(verbose = FALSE)
result$summary
#> $pass
#> [1] 15
#> $warn
#> [1] 2
#> $fail
#> [1] 0

# Gate the rest of your script on a clean environment
stopifnot(result$summary$fail == 0)
```

Individual checks can be disabled when only a subset is needed:

``` r

# Check R package dependencies only (skip dx and RAP auth)
ops_setup(check_dx = FALSE, check_auth = FALSE)
```

------------------------------------------------------------------------

## `ops_fields()` — Search Approved Project Fields

Before extraction,
[`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
searches the field list of the **active RAP project** — the fields
actually approved and available to you — and summarises matches at the
UKB field-ID level. It requires a RAP connection (it calls
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
under the hood, cached after the first call within a session).

By default `pattern` is one or more case-insensitive keywords that must
all appear in the field name or title; set `regex = TRUE` to match a
regular expression instead.

``` r

ops_fields("sex")
#>    field_id title n_cols example_field_name
#>       <int> <char>  <int>             <char>
#> 1:       31    Sex      1  participant.p31

ops_fields("age recruitment")
#>    field_id              title n_cols example_field_name
#>       <int>             <char>  <int>             <char>
#> 1:    21022 Age at recruitment      1  participant.p21022

# Regex, and the raw matching columns instead of the field-level summary:
ops_fields("p22009", regex = TRUE, details = TRUE)
```

Because it reflects the current project,
[`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
is the reliable way to confirm a field is approved and to learn its
exact RAP column names before you call
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).

------------------------------------------------------------------------

## `ops_fields_common()` — Offline Field Reference

[`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md)
is an **offline** reference table of UK Biobank field IDs. It needs no
RAP connection and does not imply a field is approved in your project —
use
[`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
for that.

It returns the full table every time; `group` and `pattern` only subset
it. The console feedback reports what came back, one line per group when
unfiltered:

``` r

ops_fields_common()
#> ── ukbflow common fields ──────────────────────────────
#> demographics: 8
#> genetics: 6
#> self_report: 7
#> hes: 8
#> opcs: 4
#> death: 3
#> cancer_registry: 5
#> lifestyle: 8
#> early_life: 2
#> family_history: 3
#> reproductive: 9
#> blood_count: 31
#> blood_biochemistry: 30
#> nmr: 249
#> total: 373
```

### Hand-picked groups versus whole panels

The two kinds of group behave differently, and the difference matters
when you read a result:

- **Hand-picked** (`demographics`, `genetics`, `self_report`, `hes`,
  `opcs`, `death`, `cancer_registry`, `lifestyle`, `early_life`,
  `family_history`, `reproductive`) — a convenience selection, *not* a
  complete listing of what UK Biobank offers in that area.

- **Whole panels** (`blood_count`, `blood_biochemistry`, `nmr`) — every
  field of a UK Biobank Showcase category, so each *is* a complete
  reference for it:

  | Group                | Fields | IDs                   | Category | Instances |
  |----------------------|--------|-----------------------|----------|-----------|
  | `blood_count`        | 31     | `30000`-`30300` by 10 | 100081   | 0-2       |
  | `blood_biochemistry` | 30     | `30600`-`30890` by 10 | 17518    | 0-1       |
  | `nmr`                | 249    | `23400`-`23648`       | 220      | 0-1       |

``` r

ops_fields_common("sex")
#> ✔ ops_fields_common: 3 fields matching "sex".
#>    field_id       title                            description
#> 1:       31         Sex                       Participant sex.
#> 2:    22001 Genetic sex        Genetic sex from genotype data.
#> 3:    30830        SHBG Sex hormone-binding globulin (nmol/L).
#>                 group structure
#> 1:       demographics    single
#> 2:           genetics    single
#> 3: blood_biochemistry  instance

ops_fields_common(group = "nmr")
#> ✔ ops_fields_common: 249 fields in group "nmr".

# field_id is the column you want for extraction
ops_fields_common(group = "blood_count")$field_id
```

### Titles are verbatim, descriptions carry the unit

Titles are reproduced exactly as
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
returns them, so a title lookup matches. That includes UK Biobank’s own
double-L spelling of the granulocytes (`Eosinophill count`,
`Neutrophill count`, `Basophill count`) — searching for the correctly
spelled `eosinophil` still works, because it matches the description:

``` r

ops_fields_common("eosinophil")
#> ✔ ops_fields_common: 2 fields matching "eosinophil".
#>    field_id                  title                                       description
#> 1:    30150      Eosinophill count         Absolute eosinophil count (10^9 cells/Litre).
#> 2:    30210 Eosinophill percentage Eosinophils as a percentage of white blood cells (percent).
```

Descriptions state the measurement unit, and for NMR the Nightingale
biomarker group and the lipoprotein particle diameter — none of which
can be read off a title. This also makes a keyword search span panels
that a title search would miss: `ops_fields_common("cholesterol")`
returns 71 fields across both `blood_biochemistry` and `nmr`, including
`30780 LDL direct`, whose title does not contain the word at all.

The `structure` column (`single` / `instance` / `array` /
`instance_array`) tells you whether a field expands into instance
(`_i0`) or array (`_a1`) columns — useful when planning which columns to
request or decode.

------------------------------------------------------------------------

## `ops_fo()` — First Occurrence Outcome Fields

UK Biobank derives a First Occurrence field for each of 1,165 health
outcomes defined at the 3-character ICD-10 level (chapters I–XVII,
excluding the cancer chapter, which the cancer registry covers). Each
outcome has a **date** field — the earliest date the condition was
recorded across self-report, primary care, hospital inpatient and death
data — and a paired **source** field naming which of those the earliest
record came from.
[`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md) maps
outcome to field ID offline, so you can find the right field without
searching the Showcase.

Call it with no arguments to see the whole catalogue, reported one line
per ICD-10 chapter:

``` r

ops_fo()
#> ── ukbflow first occurrence outcomes ─────────────────────────────────────
#> Certain infectious and parasitic diseases: 173
#> Blood, blood-forming organs and certain immune disorders: 34
#> Endocrine, nutritional and metabolic diseases: 73
#> ...
#> Congenital disruptions and chromosomal abnormalities: 87
#> total: 1165
```

`pattern` is matched case-insensitively across the ICD-10 code, the
outcome name, and both field IDs, so you can search by whichever you
happen to have:

``` r

ops_fo("I21")
#> ✔ ops_fo: 1 outcome matching "I21".
#>     icd10                        name                      chapter date_field
#> 1:    I21 acute myocardial infarction Circulatory system disorders     131298
#>    source_field
#> 1:       131299

ops_fo("myocardial")               # by name
ops_fo("I2")                       # code stem: every I2x outcome
ops_fo("131298")                   # reverse lookup by field ID
ops_fo(chapter = "circulatory")    # 77 outcomes
```

The `date_field` is what you hand to
[`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md):

``` r

fid <- ops_fo("I21")$date_field
# derive_first_occurrence(dt, field = fid, name = "mi")
```

The underlying code lists are UK Biobank’s own algorithmic mapping and
have not been clinically reviewed or externally validated; treat a First
Occurrence outcome as a first pass at identifying cases.

------------------------------------------------------------------------

## `ops_alg()` — Algorithmically-Defined Outcome Fields

UK Biobank also adjudicates 19 algorithmically-defined outcomes (ADO,
Category 42) across 8 disease groups. Each outcome’s algorithm takes the
earliest recorded date across self-report, hospital inpatient and death
data, and pairs it with a source field.
[`ops_alg()`](https://evanbio.github.io/ukbflow/reference/ops_alg.md) is
the offline catalogue, laid out the same way as
[`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md):

``` r

ops_alg()
#> ── ukbflow algorithmically-defined outcomes ──────────────────────────────
#> Myocardial infarction outcomes: 3
#> Stroke outcomes: 4
#> Asthma outcomes: 1
#> COPD outcomes: 1
#> Dementia outcomes: 4
#> End stage renal disease outcomes: 1
#> Motor neurone disease outcomes: 1
#> Parkinson's disease outcomes: 4
#> total: 19
```

`pattern` searches the outcome name and both field IDs; `category`
filters the disease group:

``` r

ops_alg("dementia")
#> ✔ ops_alg: 3 outcomes matching "dementia".
#>                       name          category date_field source_field
#> 1:      all cause dementia Dementia outcomes      42018        42019
#> 2:       vascular dementia Dementia outcomes      42022        42023
#> 3: frontotemporal dementia Dementia outcomes      42024        42025

ops_alg("42018")                   # reverse lookup by field ID
ops_alg(category = "stroke")       # stroke, ischaemic, ICH, SAH
```

Note that “all cause dementia” matches on `dementia` but “alzheimer’s
disease” does not, even though it sits in the same category — filter by
`category` when you want the whole group.

The `date_field` feeds
[`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md).
The algorithms aim for high positive predictive value; see UK Biobank
Resource 593 for source-specific PPV estimates. An ADO already
reconciles self-report, hospital and death records internally, so it is
a complete case definition on its own and should not be merged again
through
[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md).

------------------------------------------------------------------------

## `ops_covariates()` — Common Covariate Presets

[`ops_covariates()`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md)
is a small offline catalogue of frequently used covariate sets. It is a
convenience reference that shows common conventions — it does **not**
recommend which covariates to adjust for; that remains a study-design
decision you make explicitly.

Call it with no arguments to browse the available presets:

``` r

ops_covariates()
#>                    id                                    description n_vars
#>                <char>                                         <char>  <int>
#> 1:                age                             Age at recruitment      1
#> 2:                sex                                            Sex      1
#> 3:                pcs          First 10 genetic principal components     10
#> 4:            age_sex                                      Age + sex      2
#> 5:        age_sex_pcs                     Age + sex + 10 genetic PCs     12
#> 6:             center                   Assessment centre (baseline)      1
#> 7:     age_sex_center                  Age + sex + assessment centre      3
#> 8: age_sex_center_pcs Age + sex + assessment centre + 10 genetic PCs     13
```

Pass a preset `id` to get its covariate column names, ready to hand
straight to the `covariates` argument of the `assoc_*` functions:

``` r

ops_covariates("age_sex_pcs")
#>  [1] "age_at_recruitment"               "sex"
#>  [3] "genetic_principal_components_a1"  "genetic_principal_components_a2"
#>  ...
#> [11] "genetic_principal_components_a9"  "genetic_principal_components_a10"

# Example: adjust a Cox model for age, sex, and 10 genetic PCs
cov <- ops_covariates("age_sex_pcs")
# assoc_coxph(dt, exposure = "grs_z", covariates = cov)
```

The returned names are in the **decoded** (snake_case) form produced by
[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
— the form used when fitting models — not the raw `pXXXX` field names.
Genetic principal components are fixed to the first ten; if you need a
different number, request those columns directly. For a combination not
included in the catalogue, construct the vector directly, e.g.
`c(ops_covariates("age_sex_pcs"), "body_mass_index_bmi_i0")`.

------------------------------------------------------------------------

## `ops_toy()` — Synthetic UKB Data

[`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
generates a realistic but entirely synthetic dataset that mimics the
structure of UKB phenotype data on the RAP. Use it to develop and test
`derive_*`, `assoc_*`, and `plot_*` functions without needing real UKB
data access.

### Cohort scenario

The default `"cohort"` scenario produces a wide participant-level table
that covers all major UKB data domains:

``` r

dt <- ops_toy()
#> ✔ ops_toy: 1000 participants | 107 columns | scenario = "cohort" | seed = 42

dim(dt)
#> [1] 1000  107

names(dt)
#>  [1] "eid"          "p31"          "p34"          "p53_i0"
#>  [5] "p21022"       "p21001_i0"    "p20116_i0"    "p1558_i0"
#>  ...
```

Column groups included:

| Group | Columns |
|----|----|
| Demographics | `eid`, `p31`, `p34`, `p53_i0`, `p21022` |
| Covariates | `p21001_i0`, `p20116_i0`, `p1558_i0`, `p21000_i0`, `p22189`, `p54_i0` |
| Genetic PCs | `p22009_a1` – `p22009_a10` |
| Self-report disease | `p20002_i0_a0` – `a4`, `p20008_i0_a0` – `a4` |
| Self-report cancer | `p20001_i0_a0` – `a4`, `p20006_i0_a0` – `a4` |
| HES (ICD-10, any position) | `p41270` (JSON array), `p41280_a0` – `a8` |
| HES (ICD-9, any position) | `p41271` (JSON array), `p41281_a0` – `a2` |
| HES (OPCS-4, any position) | `p41272` (JSON array), `p41282_a0` – `a2` |
| HES (ICD-10, main position) | `p41202` (JSON array), `p41262_a0` – `a8` |
| HES (ICD-9, main position) | `p41203` (JSON array), `p41263_a0` – `a2` |
| HES (OPCS-4, main position) | `p41200` (JSON array), `p41260_a0` – `a2` |
| Cancer registry | `p40006_i0` – `i2`, `p40011_i0` – `i2`, `p40012_i0` – `i2`, `p40005_i0` – `i2` |
| Cancer registry (ICD-9) | `p40013_i3`, sharing `p40011_i3`, `p40012_i3`, `p40005_i3` |
| Death registry | `p40001_i0`, `p40002_i0_a0` – `a2`, `p40000_i0` |
| Follow-up censoring | `p191` (date lost to follow-up) |
| First occurrence | `p131742` |
| Algorithmic outcome | `p42018` (dementia) |
| GRS columns | `grs_bmi`, `grs_raw`, `grs_finngen` |
| Messy columns | `messy_allna`, `messy_empty`, `messy_label` |

The messy columns deliberately stress-test
[`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
and [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
against common data quality issues (all-NA columns, empty strings,
non-standard missing labels).

Disease codes are sampled with roughly equal frequency, so event rates
run well above real-world prevalence and rare conditions are no rarer
than common ones. This is deliberate: at realistic prevalence a toy
cohort of a few hundred yields too few events for `assoc_*` to fit
without unstable or non-estimable coefficients. Use the toy data to
check that a pipeline runs — never to read anything into the effect
sizes it produces.

Two relationships in the toy data are worth knowing, because they mirror
constraints that hold in the real data and are what make the toy usable
for checking `derive_*` behaviour:

- The **main-position** fields are generated as a subset of the matching
  any-position field, carrying the same dates.
  `derive_hes(position = "main")` therefore always returns a subset of
  `derive_hes(position = "any")`, as it must on the RAP.
- `p42018` is **correlated with, but not reducible to**, the HES and
  self-report dementia records. The algorithm rejects a share of
  code-positive participants and admits some code-negative ones, and the
  dates it records are close to but rarely identical with the source
  dates. Recipes treat `algorithm` as a source parallel to `hes`, so a
  toy in which the two agreed by construction would hide exactly the
  disagreement worth measuring. The field also contains UKB’s
  `1900-01-01` sentinel, which
  [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md)
  converts to `NA` and reports.

Feed the output directly into the derive pipeline:

``` r

dt <- ops_toy()
dt <- derive_missing(dt)
dt <- derive_covariate(dt,
  as_numeric = "p21001_i0",
  as_factor  = c("p31", "p20116_i0")
)
```

### GP scenario

The `"gp"` scenario returns a **primary-care long table** with one row
per clinical event, matching the columns
`extract_gp(table = "gp_clinical")` returns. Pass it as the `gp`
argument of
[`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md),
[`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md),
or
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md).

Unlike the other scenarios, `n` is the number of participants in the
matching cohort rather than the number of rows returned — around 45% of
them have linked primary-care data, and each of those contributes
several events:

``` r

dt <- ops_toy(n = 1000, seed = 1)
gp <- ops_toy(scenario = "gp", n = 1000, seed = 1)
#> ✔ ops_toy: 459 linked participants | 6085 records | 5 columns |
#>   scenario = "gp" | seed = 1

dt <- derive_gp_read2(dt, "dementia", read2 = c("E001.", "Eu00."), gp = gp)
dt <- derive_gp_ctv3(dt,  "dementia", ctv3  = c("E001.", "Eu00."), gp = gp)
```

Use the **same `n` and `seed`** for both calls so the `eid` values line
up.

`data_provider` decides which code column a row populates: England (TPP)
records CTV3 in `read_3`, the other providers record Read v2 in
`read_2`. The two coding systems never appear on the same row, which is
why
[`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
and
[`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md)
are separate sources rather than one merged lookup. Event dates include
the UKB Coding 819 placeholders (`1900-01-01` and friends), which count
towards status but are excluded from the earliest-event date.

Codes are synthetic. Codes matching a shipped recipe are taken from that
recipe’s code list so
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
returns real cases; the background codes are fabricated in the right
shape and are **not** a curated code list.

### Forest scenario

The `"forest"` scenario returns a results table matching the output of
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
useful for developing and testing
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
without running a real Cox model:

``` r

dt_forest <- ops_toy(scenario = "forest")
#> ✔ ops_toy: 24 rows | 11 columns | scenario = "forest" | seed = 42

# Pass the result table straight to plot_forest(): estimate, CI, columns,
# and axis are auto-derived (one row per exposure here).
plot_forest(dt_forest[model == "Fully adjusted"])
```

### Reproducibility

Results are reproducible by default (`seed = 42`). Pass `seed = NULL`
for a different dataset on every call:

``` r

dt1 <- ops_toy(seed = 1)
dt2 <- ops_toy(seed = 1)
identical(dt1, dt2)   # TRUE

dt_random <- ops_toy(seed = NULL)   # different every call
```

------------------------------------------------------------------------

## `ops_na()` — Missing Value Diagnostics

[`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
scans every column for `NA` **and empty strings (`""`)**, returning
counts and percentages sorted by missingness. Counting `""` as missing
is intentional — UKB exports frequently use empty strings as
placeholders for absent text values, so
[`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
reports *effective* missingness rather than a plain
[`is.na()`](https://rdrr.io/r/base/NA.html) count. It is designed to be
called before
[`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
to understand the data quality profile of a freshly extracted UKB
dataset.

``` r

dt <- ops_toy()
ops_na(dt)
#> ── ops_na ──────────────────────────────────────────────────────────────────
#> ℹ 1000 rows | 65 columns | threshold = 0%
#> ✖ messy_allna   1000 / 1000  (100.00%)
#> ✖ p41280_a4     1000 / 1000  (100.00%)
#> ✖ p20002_i0_a4   976 / 1000  ( 97.60%)
#> ✖ p131742        916 / 1000  ( 91.60%)
#> ...
#> ────────────────────────────────────────────────────────────────────────────
#> ✖ 41 columns ≥ 10% missing
#> ✔ 24 columns complete (0% missing)
```

Columns with ≥ 10% missing are flagged in red (`✖`); those between 0%
and 10% in yellow (`!`). The summary block (totals) is always printed
regardless of the `threshold` setting.

### Controlling CLI output with `threshold`

Use `threshold` to silence low-missingness columns from the per-column
listing when the dataset has many columns. The summary block and
returned data.table are always complete.

``` r

# Only list columns with > 50% missing in the console output
ops_na(dt, threshold = 50)

# Suppress all per-column lines — summary only
ops_na(dt, threshold = 99)
```

### Programmatic use

[`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
returns a `data.table` invisibly, regardless of `threshold`:

``` r

result <- ops_na(dt, verbose = FALSE)
result
#>           column  n_na pct_na
#>           <char> <int>  <num>
#>  1:  messy_allna  1000  100.0
#>  2:    p41280_a4  1000  100.0
#>  ...

# Identify columns to drop before modelling
cols_to_drop <- result[pct_na > 90, column]
dt[, (cols_to_drop) := NULL]
```

------------------------------------------------------------------------

## `ops_snapshot()` — Pipeline Checkpoints

[`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
records a lightweight summary of your dataset at each processing step
and stores it in the session cache. Each subsequent call automatically
computes deltas (Δ) against the previous snapshot, making it easy to
track how rows, columns, and missingness change through the pipeline.

### Recording snapshots

``` r

dt <- ops_toy()
ops_snapshot(dt, label = "raw")
#> ── snapshot: raw ───────────────────────────────────────────────────────────
#>   rows      1,000
#>   cols         65
#>   NA cols      41
#>   size       0.61 MB
#> ────────────────────────────────────────────────────────────────────────────

dt <- derive_missing(dt)
ops_snapshot(dt, label = "after_derive_missing")
#> ── snapshot: after_derive_missing ──────────────────────────────────────────
#>   rows      1,000  (= 0)
#>   cols         65  (= 0)
#>   NA cols      43  (+2)
#>   size       0.61 MB  (= 0)
#> ────────────────────────────────────────────────────────────────────────────

dt <- dt[p31 == "Female"]
ops_snapshot(dt, label = "female_only")
#> ── snapshot: female_only ───────────────────────────────────────────────────
#>   rows        570  (-430)
#>   cols         65  (= 0)
#>   NA cols      43  (= 0)
#>   size       0.36 MB  (-0.25 MB)
#> ────────────────────────────────────────────────────────────────────────────
```

When `label` is omitted, snapshots are named `snapshot_1`, `snapshot_2`,
etc. automatically. Labels should be unique within a session: if the
same label is used twice, the history row is appended again but the
stored column list is overwritten — which can cause
[`ops_snapshot_cols()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md)
and
[`ops_snapshot_diff()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_diff.md)
to behave unexpectedly.

### Viewing the full history

Call
[`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
with no arguments to print and return the complete history data.table:

``` r

ops_snapshot()
#> ── ops_snapshot history ────────────────────────────────────────────────────
#>    idx                label timestamp  nrow  ncol n_na_cols size_mb
#>  1:  1                  raw  14:30:01  1000    65        41    0.61
#>  2:  2 after_derive_missing  14:30:05  1000    65        43    0.61
#>  3:  3          female_only  14:30:08   570    65        43    0.36
#> ────────────────────────────────────────────────────────────────────────────
```

### Silent recording

Set `verbose = FALSE` to record a snapshot without printing anything —
useful inside functions or automated scripts:

``` r

ops_snapshot(dt, label = "pre_assoc", verbose = FALSE)
```

### Resetting history

``` r

ops_snapshot(reset = TRUE)
#> ✔ Snapshot history cleared.
```

> **Session scope**: the snapshot history lives in ukbflow’s session
> cache and is cleared when the R session ends or when
> `ops_snapshot(reset = TRUE)` is called. It is not written to disk.

------------------------------------------------------------------------

## Snapshot Helpers

### `ops_snapshot_cols()` — column names at a checkpoint

Returns the column names recorded at a given snapshot label, minus
protected columns (`eid`, `sex`, `age`, `age_at_recruitment`, and any
registered via
[`ops_set_safe_cols()`](https://evanbio.github.io/ukbflow/reference/ops_set_safe_cols.md)).
The primary use is building a drop vector after the raw columns are no
longer needed.

``` r

raw_cols <- ops_snapshot_cols("raw")
# raw_cols is a character vector of droppable column names
```

Pass `keep` to protect additional columns beyond the defaults:

``` r

raw_cols <- ops_snapshot_cols("raw", keep = "p53_i0")
```

### `ops_snapshot_diff()` — compare two checkpoints

Returns lists of columns added and removed between two snapshots —
useful for auditing what `derive_*` functions produced.

``` r

result <- ops_snapshot_diff("raw", "after_derive_missing")
result$added    # columns added in this step
result$removed  # columns dropped in this step
```

### `ops_snapshot_remove()` — drop raw columns after deriving

Removes the raw columns captured at a snapshot from `data`, keeping any
derived columns added since. Built-in safe columns (`eid`, etc.) and
columns supplied in `keep` are always retained.

``` r

# After deriving, drop the original raw columns
dt <- ops_snapshot_remove(dt, from = "raw")
#> ✔ ops_snapshot_remove: dropped 60 raw columns, 15 remaining.
```

For `data.table` input the operation is by reference (in-place); for
`data.frame` input a new `data.table` is returned and the original is
not modified.

### `ops_set_safe_cols()` — register study-specific protected columns

Adds column names to the session safe list so they are never dropped by
[`ops_snapshot_cols()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md)
or
[`ops_snapshot_remove()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_remove.md).

``` r

ops_set_safe_cols(c("date_baseline", "age_at_recruitment"))

# Clear registered safe cols
ops_set_safe_cols(reset = TRUE)
```

------------------------------------------------------------------------

## `ops_withdraw()` — Exclude Withdrawn Participants

UK Biobank periodically issues withdrawal files listing participants who
have revoked consent.
[`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
reads the headerless single-column CSV supplied by UKB and removes
matching rows from your dataset. Two snapshots (`before_withdraw` /
`after_withdraw`) are recorded automatically.

``` r

dt <- ops_withdraw(dt, file = "withdraw.csv")
#> ── snapshot: before_withdraw ───────────────────────────────────────────────
#>   rows      502,492
#>   ...
#> ── snapshot: after_withdraw ────────────────────────────────────────────────
#>   rows      502,489  (-3)
#>   ...
#> ℹ Withdrawal file: w854944_20260310.csv (312 IDs)
#> ✖ Excluded: 3 participants found in data
#> ✔ Remaining: 502,489 participants
```

Run this immediately after loading your extracted dataset, before any
`derive_*` steps, so withdrawn participants never enter the analysis.

------------------------------------------------------------------------

## Typical Workflow

The four `ops_*` functions form a natural bookend around the core
pipeline:

``` r

library(ukbflow)

# 1. Verify environment before starting
ops_setup()

# 2. Generate test data (or extract real data from RAP)
dt <- ops_toy()

# 3. Inspect data quality before processing
ops_na(dt)

# 4. Run pipeline with checkpoints
ops_snapshot(dt, label = "raw")

dt <- derive_missing(dt)
ops_snapshot(dt, label = "after_derive_missing")

dt <- derive_covariate(dt,
  as_numeric = "p21001_i0",
  as_factor  = c("p31", "p20116_i0")
)
ops_snapshot(dt, label = "after_derive_covariate")

# 5. Review full pipeline history
ops_snapshot()
```

------------------------------------------------------------------------

## Getting Help

- [`?ops_setup`](https://evanbio.github.io/ukbflow/reference/ops_setup.md),
  [`?ops_fields`](https://evanbio.github.io/ukbflow/reference/ops_fields.md),
  [`?ops_fields_common`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md),
  [`?ops_covariates`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md),
  [`?ops_toy`](https://evanbio.github.io/ukbflow/reference/ops_toy.md),
  [`?ops_na`](https://evanbio.github.io/ukbflow/reference/ops_na.md),
  [`?ops_snapshot`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
- [`?ops_snapshot_cols`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md),
  [`?ops_snapshot_diff`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_diff.md),
  [`?ops_snapshot_remove`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_remove.md),
  [`?ops_set_safe_cols`](https://evanbio.github.io/ukbflow/reference/ops_set_safe_cols.md)
- [`?ops_withdraw`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
- [`vignette("get-started")`](https://evanbio.github.io/ukbflow/articles/get-started.md)
  — end-to-end pipeline overview
- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
  — disease phenotype derivation
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
