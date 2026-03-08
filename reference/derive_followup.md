# Compute follow-up end date and follow-up time for survival analysis

Adds two columns to `data`:

- `{name}_followup_end` (IDate) - the earliest of the outcome event
  date, death date, lost-to-follow-up date, and the administrative
  censoring date.

- `{name}_followup_years` (numeric) - time in years from `baseline_col`
  to `{name}_followup_end`.

## Usage

``` r
derive_followup(
  data,
  name,
  event_col,
  baseline_col,
  censor_date,
  death_col = NULL,
  lost_col = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix, e.g. `"cscc"` produces
  `cscc_followup_end` and `cscc_followup_years`.

- event_col:

  (character) Name of the outcome event date column (e.g.
  `"cscc_date"`).

- baseline_col:

  (character) Name of the baseline date column (e.g. `"date_baseline"`).

- censor_date:

  (Date or character) Scalar administrative censoring date, e.g.
  `as.Date("2022-06-01")`. A character string in `"YYYY-MM-DD"` format
  is also accepted.

- death_col:

  (character or NULL) Name of the death date column (UKB field 40000).
  `NULL` (default) triggers auto-detection via the
  [`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
  cache; pass `FALSE` to explicitly disable death as a competing
  end-point.

- lost_col:

  (character or NULL) Name of the lost-to-follow-up date column (UKB
  field 191). `NULL` (default) triggers auto-detection; pass `FALSE` to
  explicitly disable.

## Value

The input `data` with two new columns added in-place:
`{name}_followup_end` (IDate) and `{name}_followup_years` (numeric).

## Details

**data.table pass-by-reference**: when the input is a `data.table`, new
columns are added in-place via `:=`.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- derive_followup(df,
  name         = "outcome",
  event_col    = "outcome_date",
  baseline_col = "date_baseline",
  censor_date  = as.Date("2022-06-01"),
  death_col    = "date_death",
  lost_col     = "date_lost_followup")
# → df$outcome_followup_end    IDate
# → df$outcome_followup_years  numeric
} # }
```
