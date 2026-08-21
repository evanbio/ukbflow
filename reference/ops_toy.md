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
    for the full `derive_*` -\> `assoc_*` -\> `plot_*` pipeline.

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

  (integer) Number of participants – or of exposures for `"forest"`, and
  of participants in the matching cohort for `"gp"`, where the table
  returned has many more rows than `n`. Default `1000L` for `"cohort"`,
  `2000L` for `"association"`, `8L` for `"forest"`, `1000L` for `"gp"`.

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

- **Genetic PCs**: `p22009_a1` - `p22009_a10`

- **Self-report disease**: `p20002_i0_a0-a4`, `p20008_i0_a0-a4`

- **Self-report cancer**: `p20001_i0_a0-a4`, `p20006_i0_a0-a4`

- **HES (any position)**: `p41270` (JSON array), `p41280_a0-a8`

- **HES ICD-9 (any position)**: `p41271` (JSON array), `p41281_a0-a2`

- **HES OPCS-4 (any position)**: `p41272` (JSON array), `p41282_a0-a2`

- **HES (main position)**: `p41202` / `p41262_a0-a8` (ICD-10), `p41203`
  / `p41263_a0-a2` (ICD-9), `p41200` / `p41260_a0-a2` (OPCS-4). Each is
  generated as a subset of the matching any-position field, so
  `derive_hes(position = "main")` always returns a subset of
  `derive_hes(position = "any")`.

- **Cancer registry**: `p40006_i0-i2`, `p40011_i0-i2`, `p40012_i0-i2`,
  `p40005_i0-i2`

- **Death registry**: `p40001_i0`, `p40002_i0_a0-a2`, `p40000_i0`

- **Follow-up censoring**: `p191` (date lost to follow-up)

- **First occurrence**: `p131742`

- **Algorithmic outcome**: `p42018` (dementia). Correlated with the HES
  and self-report dementia records but deliberately not reducible to
  them: the algorithm rejects some code-positive participants and admits
  some code-negative ones, and includes UKB's `1900-01-01` sentinel.

- **GRS**: `grs_bmi`, `grs_raw`, `grs_finngen`

- **Messy columns**: `messy_allna`, `messy_empty`, `messy_label`

Disease codes are sampled with roughly equal frequency, so event rates
in the toy data run well above their real-world prevalence and rare
conditions are no rarer than common ones. This is deliberate: at
realistic prevalence a toy cohort of a few hundred yields too few events
for `assoc_*` to fit without unstable or non-estimable coefficients. Use
the toy data to check that a pipeline runs, never to read anything into
the effect sizes.

### scenario = "association"

Analysis-ready table. All derive inputs (raw arrays, HES JSON, registry
fields) are omitted; derive outputs are pre-computed with internally
consistent relationships:

- **Demographics**: `eid`, `p31` (factor), `p53_i0` (IDate), `p21022`

- **Covariates**: `p21001_i0`, `bmi_cat` (factor, derived from
  `p21001_i0`), `p20116_i0` (factor), `p1558_i0` (factor), `p21000_i0`
  (factor), `p22189`, `tdi_cat` (factor, derived from `p22189`
  quartiles), `p54_i0` (factor)

- **Genetic PCs**: `p22009_a1` - `p22009_a10`

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

### scenario = "gp"

A primary-care long table with one row per clinical event, matching the
columns `extract_gp(table = "gp_clinical")` returns: `eid`,
`data_provider`, `read_2`, `read_3`, `event_dt`. Pass it as the `gp`
argument of
[`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md),
[`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md)
or
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md).

Unlike the other scenarios, `n` is the number of participants in the
matching cohort, not the number of rows returned: roughly 45% of them
have linked primary-care data and each of those contributes several
events, so [`nrow()`](https://rdrr.io/r/base/nrow.html) exceeds `n`. Use
the same `n` and `seed` as the `"cohort"` call it will be joined to, so
the `eid` values line up.

`data_provider` decides which code column a row populates – England
(TPP) records CTV3 in `read_3`, the other providers record Read v2 in
`read_2` – so the two coding systems never appear on the same row. Event
dates include the UKB Coding 819 placeholders (`1900-01-01` and
friends), which count towards status but are excluded from the
earliest-event date.

Codes are synthetic. Codes that match a shipped recipe are taken from
that recipe's code list so
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
returns real cases; the background codes are fabricated in the correct
shape and are not a curated code list.

## Examples

``` r
# cohort: raw UKB-style columns, feed into derive pipeline
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
dt <- derive_missing(dt)
#> ✔ derive_missing: replaced 48 values across 3 columns (action = "na").

# association: analysis-ready, feed directly into assoc_* functions
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]   # exclude prevalent cases

# forest: results table for plot_forest()
dt <- ops_toy(scenario = "forest")
#> ✔ ops_toy: 24 rows | 11 columns | scenario = "forest" | seed = 42

# gp: primary-care long table, matched to a cohort by n and seed
dt <- ops_toy(n = 200, seed = 1)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 1
gp <- ops_toy(scenario = "gp", n = 200, seed = 1)
#> ✔ ops_toy: 83 linked participants | 952 records | 5 columns | scenario = "gp" | seed = 1
dt <- derive_gp_read2(dt, "t2d", read2 = c("C1041", "C10F6"), gp = gp)
#> ✔ derive_gp_read2 (t2d): 2 cases, 2 with date.
```
