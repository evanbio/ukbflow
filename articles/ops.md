# Operational Utilities: Setup, Diagnostics, and Pipeline Tracking

## Overview

The `ops_*` functions are a set of lightweight utilities that sit
outside the main analysis pipeline. They help you verify your
environment before starting, explore data quality, and track how your
cohort changes at each processing step.

| Function                                                                        | Purpose                                                      |
|---------------------------------------------------------------------------------|--------------------------------------------------------------|
| [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)       | Check dx CLI, RAP authentication, and R package dependencies |
| [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)           | Generate synthetic UKB-like data for development and testing |
| [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)             | Summarise missing values (NA and `""`) across all columns    |
| [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md) | Record pipeline checkpoints and track dataset changes        |

None of these functions modify your data or connect to the RAP — they
are entirely read-only diagnostic and utility tools.

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
#> ℹ ukbflow 0.1.0  |  R 4.4.1  |  2026-03-09
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
#> ✔ ops_toy: 1000 participants | 65 columns | scenario = "cohort" | seed = 42

dim(dt)
#> [1] 1000   65

names(dt)
#>  [1] "eid"          "p31"          "p34"          "p53_i0"
#>  [5] "p21022"       "p21001_i0"    "p20116_i0"    "p1558_i0"
#>  ...
```

Column groups included:

| Group               | Columns                                                               |
|---------------------|-----------------------------------------------------------------------|
| Demographics        | `eid`, `p31`, `p34`, `p53_i0`, `p21022`                               |
| Covariates          | `p21001_i0`, `p20116_i0`, `p1558_i0`, `p21000_i0`, `p22189`, `p54_i0` |
| Genetic PCs         | `p22009_a1` – `p22009_a10`                                            |
| Self-report disease | `p20002_i0_a0` – `a4`, `p20008_i0_a0` – `a4`                          |
| HES                 | `p41270` (JSON array), `p41280_a0` – `a8`                             |
| Cancer registry     | `p40006_i0` – `i2`, `p40005_i0` – `i2`, `p40011`, `p40012`            |
| Death registry      | `p40001_i0`, `p40002_i0_a0` – `a2`, `p40000_i0`                       |
| First occurrence    | `p131742`                                                             |
| GRS columns         | `grs_bmi`, `grs_raw`, `grs_finngen`                                   |
| Messy columns       | `messy_allna`, `messy_empty`, `messy_label`                           |

The messy columns deliberately stress-test
[`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
and [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
against common data quality issues (all-NA columns, empty strings,
non-standard missing labels).

Feed the output directly into the derive pipeline:

``` r
dt <- ops_toy()
dt <- derive_missing(dt)
dt <- derive_covariate(dt,
  as_numeric = "p21001_i0",
  as_factor  = c("p31", "p20116_i0")
)
```

### Forest scenario

The `"forest"` scenario returns a results table matching the output of
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
useful for developing and testing
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
without running a real Cox model:

``` r
dt_forest <- ops_toy(scenario = "forest")
#> ✔ ops_toy: 24 rows | 11 columns | scenario = "forest" | seed = 42

plot_forest(
  data  = dt_forest[model == "Fully adjusted"],
  est   = dt_forest[model == "Fully adjusted", HR],
  lower = dt_forest[model == "Fully adjusted", CI_lower],
  upper = dt_forest[model == "Fully adjusted", CI_upper]
)
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
scans every column for `NA` and empty strings (`""`), returning counts
and percentages sorted by missingness. It is designed to be called
before
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
etc. automatically.

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
  [`?ops_toy`](https://evanbio.github.io/ukbflow/reference/ops_toy.md),
  [`?ops_na`](https://evanbio.github.io/ukbflow/reference/ops_na.md),
  [`?ops_snapshot`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
- [`vignette("get-started")`](https://evanbio.github.io/ukbflow/articles/get-started.md)
  — end-to-end pipeline overview
- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
  — disease phenotype derivation
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
