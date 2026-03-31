# Generate toy UKB-like data for testing and development

Creates a small, synthetic dataset that mimics the structure of UK
Biobank phenotype data on the RAP. Useful for developing and testing
`derive_*`, `assoc_*`, and `plot_*` functions without requiring real UKB
data access.

## Usage

``` r
ops_toy(scenario = "cohort", n = 1000L, seed = 42L)
```

## Arguments

- scenario:

  (character) Data structure to generate:

  - `"cohort"`: wide participant-level table for the full `derive_*` →
    `assoc_*` → `plot_*` pipeline.

  - `"forest"`: association results table matching
    [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
    output, for testing
    [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md).
    `n` = number of exposures (default 8).

- n:

  (integer) Number of participants. Default `1000L`.

- seed:

  (integer or NULL) Random seed for reproducibility. Pass `NULL` for a
  different dataset on every call. Default `42L`.

## Value

A `data.table` with UKB-style column names. See Details for the columns
included in each scenario.

## Details

This dataset is entirely synthetic. Column names follow RAP conventions
(e.g. `p41270`, `p20002_i0_a0`).

### scenario = "cohort"

Includes the following column groups:

- **Demographics**: `eid`, `p31`, `p34`, `p53_i0`, `p21022`

- **Covariates**: `p21001_i0`, `p20116_i0`, `p1558_i0`, `p21000_i0`,
  `p22189`, `p54_i0`

- **Genetic PCs**: `p22009_a1` – `p22009_a10`

- **Self-report disease**: `p20002_i0_a0–a4`, `p20008_i0_a0–a4`

- **Self-report cancer**: `p20001_i0_a0–a4`, `p20006_i0_a0–a4`

- **HES**: `p41270` (JSON array), `p41280_a0–a8`

- **Cancer registry**: `p40006_i0–i2`, `p40011_i0–i2`, `p40012_i0–i2`,
  `p40005_i0–i2`

- **Death registry**: `p40001_i0`, `p40002_i0_a0–a2`, `p40000_i0`

- **First occurrence**: `p131742`

- **GRS**: `grs_bmi`, `grs_raw`, `grs_finngen`

- **Messy columns**: `messy_allna`, `messy_empty`, `messy_label`

## Examples

``` r
if (FALSE) { # \dontrun{
dt <- ops_toy()
dt <- ops_toy(n = 500, seed = 1)

# Dynamic dataset (different every call)
dt <- ops_toy(seed = NULL)

# Feed directly into derive pipeline
dt <- ops_toy()
dt <- derive_missing(dt)
} # }
```
