# Publication-ready forest plot

Produces a publication-ready forest plot with UKB-standard styling. The
user supplies a data frame whose first column is the row label (`item`),
plus any additional display columns (e.g. `Cases/N`). The gap column and
the auto-formatted `OR (95% CI)` text column are inserted automatically
at `ci_column`. Numeric p-value columns declared via `p_cols` are
formatted in-place.

## Usage

``` r
plot_forest(
  data,
  est = NULL,
  lower = NULL,
  upper = NULL,
  ci_column = NULL,
  ref_line = NULL,
  xlim = NULL,
  ticks_at = NULL,
  arrow_lab = c("Lower risk", "Higher risk"),
  header = NULL,
  label_col = NULL,
  show_cols = NULL,
  indent = NULL,
  bold_label = NULL,
  ci_col = "black",
  ci_sizes = 0.6,
  ci_Theight = 0.2,
  ci_digits = 2L,
  ci_sep = ", ",
  p_cols = NULL,
  p_digits = 3L,
  bold_p = TRUE,
  p_threshold = 0.05,
  align = NULL,
  background = "zebra",
  bg_col = "#F0F0F0",
  border = "three_line",
  border_width = 3,
  row_height = NULL,
  col_width = NULL,
  save = FALSE,
  dest = NULL,
  save_width = 20,
  save_height = NULL,
  theme = "default"
)
```

## Arguments

- data:

  data.frame. First column must be the label column (`item`). Additional
  columns are displayed as-is (character) or formatted if named in
  `p_cols` (must be numeric). Column order is preserved. May also be an
  `assoc_*()` result table (see *Result-table shortcut*).

- est:

  Numeric vector. Point estimates (`NA` = no CI drawn). `NULL` (default)
  = derive from an `assoc_*()` result in `data`; required otherwise.

- lower:

  Numeric vector. Lower CI bounds (same length as `est`). `NULL`
  (default) = derive from an `assoc_*()` result.

- upper:

  Numeric vector. Upper CI bounds (same length as `est`). `NULL`
  (default) = derive from an `assoc_*()` result.

- ci_column:

  Integer. Column position in the final rendered table where the gap/CI
  graphic is placed. Must be between `2` and `ncol(data) + 1`
  (inclusive). `NULL` (default) = `2L`, or auto-placed on the
  result-table shortcut.

- ref_line:

  Numeric. Reference line. `NULL` (default) = `1` (HR/OR), or `0` for
  beta coefficients on the result-table shortcut.

- xlim:

  Numeric vector of length 2. X-axis limits. `NULL` (default) uses
  `c(0, 2)`, or a data-driven range on the result-table shortcut.

- ticks_at:

  Numeric vector. Tick positions. `NULL` (default) = 5 evenly spaced
  ticks across `xlim`.

- arrow_lab:

  Character vector of length 2. Directional labels. Default:
  `c("Lower risk", "Higher risk")`. `NULL` = none.

- header:

  Character vector of length `ncol(data) + 2`. Column header labels for
  the final rendered table (original columns + gap_ci + OR label).
  `NULL` (default) = use column names from `data` plus `"gap_ci"` and
  `"OR (95% CI)"`. Pass `""` for the gap column position.

- label_col:

  Character. Result-table shortcut only: which result column becomes the
  row label. `NULL` (default) = `"model"` for a single-exposure table,
  otherwise `"term"`. Ignored on the base path.

- show_cols:

  Character vector. Result-table shortcut only: which result columns to
  display alongside the label (besides the auto CI graphic). `NULL`
  (default) = the primary count column (`n_events`/`n_cases`/`n`) plus
  `p_value`. Ignored on the base path.

- indent:

  Integer vector (length = `nrow(data)`). Indentation level of the label
  column: each unit adds two leading spaces. Default: all zeros.

- bold_label:

  Logical vector (length = `nrow(data)`). Which rows to bold in the
  label column. `NULL` (default) = auto-derive from `indent`: rows where
  `indent == 0` are bolded (parent rows), indented sub-rows are plain.

- ci_col:

  Character scalar or vector (length = `nrow(data)`). CI colour(s). `NA`
  rows are skipped automatically. Default: `"black"`.

- ci_sizes:

  Numeric. Point size. Default: `0.6`.

- ci_Theight:

  Numeric. CI cap height. Default: `0.2`.

- ci_digits:

  Integer. Decimal places for the auto-generated `OR (95% CI)` column.
  Default: `2L`.

- ci_sep:

  Character. Separator between lower and upper CI in the label, e.g.
  `", "` or `" - "`. Default: `", "`.

- p_cols:

  Character vector. Names of numeric p-value columns in `data`. These
  are formatted to `p_digits` decimal places with `"<0.001"`-style
  clipping. `NULL` = none.

- p_digits:

  Integer. Decimal places for p-value formatting. Default: `3L`.

- bold_p:

  `TRUE` (bold all non-NA p below `p_threshold`), `FALSE` (no bolding),
  or a logical vector (per-row control). Default: `TRUE`.

- p_threshold:

  Numeric. P-value threshold for bolding when `bold_p = TRUE`. Default:
  `0.05`.

- align:

  Integer vector of length `ncol(data) + 2`. Alignment per column: `-1`
  left, `0` centre, `1` right. Must cover all final columns (original +
  gap_ci + OR label). `NULL` = auto (column 1 left, all others centre).

- background:

  Character. Row background style: `"zebra"`, `"bold_label"` (shade rows
  where `bold_label = TRUE`), or `"none"`. Default: `"zebra"`.

- bg_col:

  Character. Shading colour for backgrounds (scalar), or a per-row
  vector of length `nrow(data)` (overrides style). Default: `"#F0F0F0"`.

- border:

  Character. Border style: `"three_line"` or `"none"`. Default:
  `"three_line"`.

- border_width:

  Numeric. Border line width(s). Scalar = all three lines same width;
  length-3 vector = top-of-header, bottom-of-header, bottom-of-body.
  Default: `3`.

- row_height:

  `NULL` (auto), numeric scalar, or numeric vector (length = total
  gtable rows including margins). Auto sets 8 / 12 / 10 / 15 mm for top
  / header / data / bottom respectively.

- col_width:

  `NULL` (auto), numeric scalar, or numeric vector (length = total
  gtable columns). Auto rounds each default width up so the adjustment
  is in \\\[5, 10)\\ mm.

- save:

  Logical. Save output to files? Default: `FALSE`.

- dest:

  Character. Destination file path (extension ignored; all four formats
  are saved). Required when `save = TRUE`.

- save_width:

  Numeric. Output width in cm. Default: `20`.

- save_height:

  Numeric or `NULL`. Output height in cm. `NULL` =
  `nrow(data) * 0.9 + 3`.

- theme:

  Character preset (`"default"`) or a
  [`forestploter::forest_theme`](https://rdrr.io/pkg/forestploter/man/forest_theme.html)
  object. Default: `"default"`.

## Value

A forestploter plot object (gtable), returned invisibly. Display with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) or
[`grid::grid.draw()`](https://rdrr.io/r/grid/grid.draw.html).

## Details

**Result-table shortcut.** If `est`, `lower`, and `upper` are all
omitted and `data` is a result table from
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
[`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md),
[`assoc_linear`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md),
or
[`assoc_competing`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md),
the estimate/CI columns (`HR`/`OR`/`beta`/`SHR` +
`CI_lower`/`CI_upper`), reference line, display columns, header, and
x-axis range are derived automatically, so `plot_forest(res)` works out
of the box. Rows are grouped by exposure contrast: a binary exposure
shows one row per model, while a categorical exposure keeps each level's
models together (e.g. all models for *Previous*, then all for *Current*)
with a `Term` column added so no row is ambiguous. Use `label_col` /
`show_cols` to steer multi-exposure tables. Any argument you pass
explicitly overrides the auto-derived value. Tables from
[`assoc_subgroup`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md)
and
[`assoc_trend`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
carry extra dimensions and are *not* auto-laid-out; build the display
frame manually for those.

## Examples

``` r
# --- Result-table shortcut: pass an assoc_*() result straight in ----------
dt  <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt  <- dt[dm_timing != 1L]
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat")
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models = 3 Cox regressions
#> ℹ Input cohort: 463 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: HR 0.39 (0.13-1.16), p = 0.0905
#> ✔   Unadjusted | p20116_i0Current: HR 0.41 (0.10-1.77), p = 0.233
#> ✔   Age and sex adjusted | p20116_i0Previous: HR 0.40 (0.14-1.20), p = 0.102
#> ✔   Age and sex adjusted | p20116_i0Current: HR 0.43 (0.10-1.85), p = 0.255
#> ✔   Fully adjusted | p20116_i0Previous: HR 0.39 (0.13-1.16), p = 0.0918
#> ✔   Fully adjusted | p20116_i0Current: HR 0.41 (0.09-1.77), p = 0.232
#> ✔ Done: 6 result rows across 1 exposure and 3 models.
plot(plot_forest(res))   # est/CI/ref/columns all auto-derived
#> ✔ plot_forest: detected HR result: 6 rows, reference line at 1.


# --- Base path: full manual control ---------------------------------------
df <- data.frame(
  item      = c("Exposure vs. control", "Unadjusted", "Fully adjusted"),
  `Cases/N` = c("", "89/4521", "89/4521"),
  p_value   = c(NA_real_, 0.001, 0.006),
  check.names = FALSE
)

p <- plot_forest(
  data       = df,
  est        = c(NA, 1.52, 1.43),
  lower      = c(NA, 1.18, 1.11),
  upper      = c(NA, 1.96, 1.85),
  ci_column  = 2L,
  indent     = c(0L, 1L, 1L),
  bold_label = c(TRUE, FALSE, FALSE),
  p_cols     = "p_value",
  xlim       = c(0.5, 3.0)
)
plot(p)
```
