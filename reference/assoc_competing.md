# Fine-Gray competing risks association analysis

Fits a Fine-Gray subdistribution hazard model (via
[`survival::finegray()`](https://rdrr.io/pkg/survival/man/finegray.html) +
weighted `coxph()`) for each exposure variable and returns a tidy result
table with subdistribution hazard ratios (SHR).

## Usage

``` r
assoc_competing(
  data,
  outcome_col,
  time_col,
  exposure_col,
  compete_col = NULL,
  event_val = 1L,
  compete_val = 2L,
  covariates = NULL,
  base = TRUE,
  conf_level = 0.95
)

assoc_fg(
  data,
  outcome_col,
  time_col,
  exposure_col,
  compete_col = NULL,
  event_val = 1L,
  compete_val = 2L,
  covariates = NULL,
  base = TRUE,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Primary event column. In Mode A: a multi-value column (any
  integer or character codes). In Mode B: a 0/1 binary column.

- time_col:

  (character) Follow-up time column (numeric, e.g. years).

- exposure_col:

  (character) One or more exposure variable names.

- compete_col:

  (character or NULL) Mode B only: name of the 0/1 competing event
  column. When `NULL` (default), Mode A is used.

- event_val:

  Scalar value in `outcome_col` indicating the primary event (Mode A
  only). Default: `1L`.

- compete_val:

  Scalar value in `outcome_col` indicating the competing event (Mode A
  only). Default: `2L`.

- covariates:

  (character or NULL) Covariate names for the Fully adjusted model. When
  `NULL`, only Unadjusted (and Age/sex adjusted if `base = TRUE`) are
  run.

- base:

  (logical) Whether to auto-detect age and sex columns and include an
  Age and sex adjusted model. Default: `TRUE`.

- conf_level:

  (numeric) Confidence level for SHR intervals. Default: `0.95`.

## Value

A `data.table` with one row per exposure \\\times\\ term \\\times\\
model combination:

- `exposure`:

  Exposure variable name.

- `term`:

  Coefficient name as returned by `coxph`.

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `n`:

  Participants in the model (after NA removal).

- `n_events`:

  Primary events in the analysis set.

- `n_compete`:

  Competing events in the analysis set.

- `SHR`:

  Subdistribution hazard ratio.

- `CI_lower`:

  Lower CI bound.

- `CI_upper`:

  Upper CI bound.

- `p_value`:

  Robust z-test p-value from weighted Cox.

- `SHR_label`:

  Formatted string, e.g. `"1.23 (1.05-1.44)"`.

## Details

Two input modes are supported depending on how the outcome is coded in
your dataset:

- **Mode A - single multi-value column**:

  `compete_col = NULL` (default). `outcome_col` contains all event codes
  in one column (e.g. `0`/`1`/`2`/`3`). Use `event_val` and
  `compete_val` to identify the event of interest and the competing
  event; all other values are treated as censored. Example: UKB
  `censoring_type` where 1 = event, 2 = death (competing), 0/3 =
  censored.

- **Mode B - dual binary columns**:

  `compete_col` is the name of a separate 0/1 column for the competing
  event. `outcome_col` is a 0/1 column for the primary event. When both
  are 1 for the same participant, the primary event takes priority.
  Example: `outcome_col = "copd_status"`,
  `compete_col = "death_status"`.

Internally both modes are converted to a three-level factor
`c("censor", "event", "compete")` before being passed to `finegray()`.

Three adjustment models are produced (where data allow):

- **Unadjusted** - always included.

- **Age and sex adjusted** - when `base = TRUE` and age/sex columns are
  detected.

- **Fully adjusted** - when `covariates` is non-NULL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Mode A: single multi-value column (0 = censored, 1 = event, 2 = competing)
assoc_competing(
  data         = cohort,
  outcome_col  = "censoring_type",
  time_col     = "followup_years",
  exposure_col = "exposure",
  event_val    = 1L,
  compete_val  = 2L,
  covariates   = c("tdi", "smoking")
)

# Mode B: separate 0/1 columns for primary and competing events
assoc_competing(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = c("exposure", "bmi_category"),
  compete_col  = "death_status",
  covariates   = c("tdi", "smoking")
)
} # }
```
