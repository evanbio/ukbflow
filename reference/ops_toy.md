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

  - `"cohort"`: wide participant-level table with raw UKB field columns
    for the full `derive_*` → `assoc_*` → `plot_*` pipeline.

  - `"association"`: analysis-ready table with covariates already as
    factors, BMI/TDI binned, and two pre-derived disease outcomes
    (`dm_*`, `htn_*`) including status, date, timing, and follow-up
    columns. Use this for `assoc_*` examples and testing without running
    the derive pipeline.

  - `"forest"`: association results table matching
    [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
    output, for testing
    [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md).
    `n` = number of exposures (default 8).

- n:

  (integer) Number of participants (or exposures for `"forest"`).
  Default `1000L` for `"cohort"`, `2000L` for `"association"`, `8L` for
  `"forest"`.

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

### scenario = "association"

Analysis-ready table. All derive inputs (raw arrays, HES JSON, registry
fields) are omitted; derive outputs are pre-computed with internally
consistent relationships:

- **Demographics**: `eid`, `p31` (factor), `p53_i0` (IDate), `p21022`

- **Covariates**: `p21001_i0`, `bmi_cat` (factor, derived from
  `p21001_i0`), `p20116_i0` (factor), `p1558_i0` (factor), `p21000_i0`
  (factor), `p22189`, `tdi_cat` (factor, derived from `p22189`
  quartiles), `p54_i0` (factor)

- **Genetic PCs**: `p22009_a1` – `p22009_a10`

- **GRS**: `grs_bmi` (continuous exposure)

- **DM outcome**: `dm_status`, `dm_date`, `dm_timing`,
  `dm_followup_end`, `dm_followup_years` (type 2 diabetes, ~12%
  prevalence)

- **HTN outcome**: `htn_status`, `htn_date`, `htn_timing`,
  `htn_followup_end`, `htn_followup_years` (hypertension, ~28%
  prevalence)

Internal relationships guaranteed:

- `bmi_cat` is cut from `p21001_i0` (breaks 18.5 / 25 / 30)

- `tdi_cat` is cut from `p22189` quartiles

- `dm_date` is `NA` iff `dm_status = FALSE`

- `dm_timing`: 0 = no disease, 1 = prevalent, 2 = incident, `NA` = no
  date

- `dm_followup_years` is `NA` for prevalent cases (`dm_timing == 1`)

## Examples

``` r
# cohort: raw UKB-style columns, feed into derive pipeline
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
dt <- derive_missing(dt)
#> ✔ derive_missing: replaced 47 values across 3 columns (action = "na").

# association: analysis-ready, feed directly into assoc_* functions
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]   # exclude prevalent cases

# forest: results table for plot_forest()
dt <- ops_toy(scenario = "forest")
#> ✔ ops_toy: 24 rows | 11 columns | scenario = "forest" | seed = 42
```
