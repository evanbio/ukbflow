# Compute age at event for one or more UKB outcomes

For each name in `name`, adds one column `age_at_{name}` (numeric,
years) computed as: \$\$age\\at\\event = age\\col + (event\\date -
baseline\\date) / 365.25\$\$

## Usage

``` r
derive_age(
  data,
  name,
  baseline_col,
  age_col,
  date_cols = NULL,
  status_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) One or more output prefixes, e.g.
  `c("disease", "disease_icd10", "outcome")`. Each produces
  `age_at_{name}`.

- baseline_col:

  (character) Name of the baseline date column (e.g. `"date_baseline"`).

- age_col:

  (character) Name of the age-at-baseline column (e.g.
  `"age_recruitment"`).

- date_cols:

  (character or NULL) Named character vector mapping each name to its
  event date column, e.g.
  `c(disease = "disease_date", outcome = "outcome_date")`. `NULL`
  (default) triggers auto-detection as `{name}_date`.

- status_cols:

  (character or NULL) Named character vector mapping each name to its
  status column. `NULL` (default) triggers auto-detection.

## Value

The input `data` with one new `age_at_{name}` column per entry in
`name`, added in-place.

## Details

The value is `NA` for participants who did not experience the event
(status is `FALSE` / `0`) or who lack an event date.

**Auto-detection per name** (when `date_cols` / `status_cols` are
`NULL`):

- `date_col` - looked up as `{name}_date`.

- `status_col` - looked up first as `{name}_status`, then as `{name}`
  (logical column); if neither exists all rows with a non-`NA` date are
  treated as cases.

**data.table pass-by-reference**: new columns are added in-place.

## Examples

``` r
if (FALSE) { # \dontrun{
# Process multiple events in one call - auto-detects {name}_date and
# {name}_status for each
df <- derive_age(df,
  name         = c("exposure", "exposure_icd10", "outcome"),
  baseline_col = "date_baseline",
  age_col      = "age_at_recruitment")
# → age_at_exposure, age_at_exposure_icd10, age_at_outcome
} # }
```
