# Publication-Ready Visualisation

## Overview

Four functions produce publication-ready figures and tables with minimal
post-processing:

| Function | Output | Typical use |
|----|----|----|
| [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md) | Forest plot (PNG / PDF / JPG / TIFF) | Regression results from `assoc_*()` |
| [`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md) | Kaplan-Meier curve (PNG / PDF / JPG / TIFF) | Unadjusted survival by group |
| [`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md) | Spline dose-response curve (PNG / PDF / JPG / TIFF) | Non-linear dose-response from [`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md) |
| [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md) | Table 1 (DOCX / HTML / PDF / PNG) | Baseline characteristics |

When `save = TRUE`, these functions write all supported formats in a
single call and return the plot/table object invisibly for further
customisation.

------------------------------------------------------------------------

## `plot_forest()` — Forest Plot

### Minimal example

[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
takes a data frame whose **first column** is the row label, plus any
additional display columns. The CI graphic and formatted `OR (95% CI)`
text column are inserted automatically.

``` r

library(ukbflow)

df <- data.frame(
  item      = c("Exposure vs. control", "Unadjusted", "Fully adjusted"),
  `Cases/N` = c("", "89 / 4 521", "89 / 4 521"),
  p_value   = c(NA_real_, 0.001, 0.006),
  check.names = FALSE
)

p <- plot_forest(
  data      = df,
  est       = c(NA,   1.52, 1.43),
  lower     = c(NA,   1.18, 1.11),
  upper     = c(NA,   1.96, 1.85),
  ci_column = 3L,
  indent    = c(0L,   1L,   1L),
  p_cols    = "p_value",
  xlim      = c(0.5,  3.0)
)
plot(p)
```

### Straight from `assoc_*()` results

The fastest path is to pass an
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
/
[`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
/
[`assoc_linear()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
result table directly. When `est` / `lower` / `upper` are omitted,
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
derives the estimate and CI columns (`HR` / `OR` / `beta` + `CI_lower` /
`CI_upper`), reference line, display columns, header, and x-axis range
automatically:

``` r

dt  <- ops_toy(scenario = "association")
dt  <- dt[dm_timing != 1L]

res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0")
)

plot(plot_forest(res))
```

Rows are grouped by exposure contrast. A binary exposure shows one row
per model; a categorical exposure (like `p20116_i0`: Never / Previous /
Current) keeps each level’s models together — all models for *Previous*,
then all for *Current* — with a `Term` column added so no row is
ambiguous.

Anything you pass explicitly still wins, so you can override just the
pieces you care about (e.g. a fixed axis or a custom column selection):

``` r

plot(plot_forest(
  res,
  show_cols = c("n_events", "person_years", "p_value"),
  xlim      = c(0.5, 2.5)
))
```

### Full manual control

For bespoke layouts (custom row labels, spacer/header rows, hand-picked
columns), build the display frame yourself and supply `est` / `lower` /
`upper` as vectors:

``` r

res_df <- as.data.frame(res)

# Reshape: one row per model, label column first
df2 <- data.frame(
  item    = c("Smoking status", as.character(res_df$model)),
  `N`     = c("", paste0(res_df$n, " / ", res_df$n_events)),
  p_value = c(NA_real_, res_df$p_value),
  check.names = FALSE
)

p <- plot_forest(
  data      = df2,
  est       = c(NA,   res_df$HR),
  lower     = c(NA,   res_df$CI_lower),
  upper     = c(NA,   res_df$CI_upper),
  ci_column = 3L,
  indent    = c(0L,   rep(1L, nrow(res_df))),
  p_cols    = "p_value",
  xlim      = c(0.5,  2.5)
)
plot(p)
```

### Key parameters

**CI appearance**

``` r

# uses df, est, lower, upper from the minimal example above
p <- plot_forest(
  data      = df,
  est       = est, lower = lower, upper = upper,
  ci_column = 3L,
  ci_col    = c("grey50", "steelblue", "steelblue"),  # per-row colours
  ci_sizes  = 0.5,       # point size
  ci_Theight = 0.15,     # cap height
  ref_line  = 1,         # reference line (use 0 for beta coefficients)
  xlim      = c(0.2, 5), ticks_at = c(0.5, 1, 2, 3)
)
```

**Row labels and indentation**

``` r

# indent = 0 → bold parent row; indent >= 1 → indented sub-row (plain)
p <- plot_forest(
  data       = df,
  est        = est, lower = lower, upper = upper,
  ci_column  = 3L,
  indent     = c(0L, 1L, 1L),        # parent + 2 sub-rows
  bold_label = c(TRUE, FALSE, FALSE)  # explicit control (overrides indent default)
)
```

**P-value formatting**

``` r

# p_cols: column names in data that contain raw numeric p-values.
# Values < 10^(-p_digits) are displayed as e.g. "<0.001".
# bold_p = TRUE bolds all p < p_threshold (default 0.05).
p <- plot_forest(
  data        = df,
  est         = est, lower = lower, upper = upper,
  ci_column   = 3L,
  p_cols      = "p_value",
  p_digits    = 3L,
  bold_p      = TRUE,
  p_threshold = 0.05
)
```

**Column headers and alignment**

`header` renames all columns in the *final* rendered table. The final
table always has `ncol(data) + 2` columns: the original columns, plus
the `gap_ci` graphic column and the auto-generated `OR (95% CI)` text
column. Pass `""` for the gap column position.

``` r

# data has 3 columns → final table has 5 columns (original 3 + gap_ci + OR label)
# Layout with ci_column = 3L: item | Cases/N | gap_ci | OR (95% CI) | p_value
p <- plot_forest(
  data      = df,
  est       = est, lower = lower, upper = upper,
  ci_column = 3L,
  header    = c("Comparison", "Cases / N", "", "HR (95% CI)", "P-value")
  #             col 1          col 2        gap  OR label       col 5
)
```

`align` controls per-column text alignment across all `ncol(data) + 2`
columns: `-1` = left, `0` = centre, `1` = right. `NULL` (default)
left-aligns column 1 and centres the rest.

``` r

p <- plot_forest(
  data      = df,
  est       = est, lower = lower, upper = upper,
  ci_column = 3L,
  align     = c(-1L, 0L, 0L, 0L, 1L)   # label left | Cases/N centre | gap | OR centre | p right
)
```

**Background and borders**

``` r

p <- plot_forest(
  data       = df,
  est        = est, lower = lower, upper = upper,
  ci_column  = 3L,
  background = "zebra",       # "zebra" | "bold_label" | "none"
  bg_col     = "#F0F0F0",     # shading colour
  border     = "three_line",  # "three_line" | "none"
  border_width = 3            # scalar or length-3 vector (top / mid / bottom)
)
```

**Layout and saving**

``` r

# uses df, est, lower, upper from the minimal example above
p <- plot_forest(
  data        = df,
  est         = est, lower = lower, upper = upper,
  ci_column   = 3L,
  row_height  = NULL,   # auto (8 / 12 / 10 / 15 mm); or scalar/vector
  col_width   = NULL,   # auto (rounds up to nearest 5 mm)
  save        = TRUE,
  dest        = "forest_main",   # extension ignored; all 4 formats saved
  save_width  = 20,              # cm
  save_height = NULL             # auto: nrow(data) * 0.9 + 3 cm
)
```

> All four formats (PNG, PDF, JPG, TIFF) are written at **300 dpi** with
> a white background. The function returns the plot object invisibly;
> display with `plot(p)` or `grid::grid.draw(p)`.

------------------------------------------------------------------------

## `plot_tableone()` — Baseline Characteristics Table

### Minimal example

``` r

library(gtsummary)
data(trial)   # built-in gtsummary dataset

plot_tableone(
  data   = trial,
  vars   = c("age", "marker", "grade"),
  strata = "trt",
  save   = FALSE
)
```

### With SMD, custom labels, and export

``` r

plot_tableone(
  data    = trial,
  vars    = c("age", "marker", "grade", "stage"),
  strata  = "trt",
  label   = list(age ~ "Age (years)", marker ~ "Marker level (ng/mL)"),
  add_p   = TRUE,    # Wilcoxon / chi-squared p-values; formatted as <0.001
  add_smd = TRUE,
  overall = TRUE,
  dest    = "table1",
  save    = TRUE
)
```

### Key parameters

**Variable types and statistics**

``` r

dt <- as.data.frame(ops_toy(scenario = "association"))

plot_tableone(
  data      = dt,
  vars      = c("p21022", "p21001_i0", "p31", "p20116_i0"),
  strata    = "dm_status",
  type      = list(p21022 = "continuous2"),   # show median + IQR
  statistic = list(
    all_continuous()  ~ "{mean} ({sd})",
    all_categorical() ~ "{n} ({p}%)"
  ),
  digits    = list(p21022 ~ 1, p21001_i0 ~ 1),
  missing   = "ifany",   # show missing counts when present
  save      = FALSE
)
```

**SMD column**

The SMD column summarises covariate balance between groups: - Continuous
variables: Cohen’s *d* (pooled-SD formula) - Categorical variables: RMSD
of group proportions

``` r

plot_tableone(
  data    = dt,
  vars    = c("p21022", "p21001_i0", "p31"),
  strata  = "dm_status",
  add_smd = TRUE,
  save    = FALSE
)
```

**Excluding rows**

Use `exclude_labels` to remove specific level rows from the rendered
table (e.g. a redundant reference category or an “Unknown” level):

``` r

plot_tableone(
  data           = dt,
  vars           = c("p31", "p20116_i0"),
  strata         = "dm_status",
  exclude_labels = "Never",   # e.g. remove reference category from display
  save           = FALSE
)
```

**Themes**

`theme = "default"` (the default) renders a clean three-line table with
no cell shading — the safe choice for journal submission.
`theme = "lancet"` adds alternating pink row shading and a shaded
header. Both keep bold variable labels, three-line borders, and a 15 px
font.

``` r

plot_tableone(
  data   = trial,
  vars   = c("age", "marker", "grade"),
  strata = "trt",
  theme  = "lancet",   # or "default" (no shading)
  save   = FALSE
)
```

**Export formats**

When `save = TRUE`, four files are written simultaneously:

| Format | Tool | Notes |
|----|----|----|
| `.docx` | [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html) | Ready for Word submission |
| `.html` | [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html) | Interactive preview |
| `.pdf` | [`pagedown::chrome_print()`](https://rdrr.io/pkg/pagedown/man/chrome_print.html) | Requires Chrome / Chromium |
| `.png` | [`webshot2::webshot()`](https://rstudio.github.io/webshot2/reference/webshot.html) | 2x zoom, table element only |

> PDF and PNG rendering requires `pagedown` and `webshot2` respectively.
> Install with `install.packages(c("pagedown", "webshot2"))`.

------------------------------------------------------------------------

## `plot_survival()` — Kaplan-Meier Curve

[`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md)
draws a publication-ready Kaplan-Meier curve. It takes the analysis data
plus a follow-up-time column and an event-status column (and optionally
a grouping column); the `survfit` model is fitted internally, so no
[`Surv()`](https://rdrr.io/pkg/survival/man/Surv.html) object is needed.
The interface mirrors
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
and the inputs are exactly what
[`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
and
[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
produce.

This is a **non-parametric, unadjusted** estimate computed straight from
the three columns — it does not use a Cox model or covariates. For
adjusted hazard ratios, use
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
on an
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
result instead.

[`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md)
builds on **ggsurvfit** (a `Suggests` dependency); install it with
`install.packages(c("ggsurvfit", "ggplot2"))`.

### Minimal example

``` r

library(survival)

lung2 <- lung
lung2$sex <- factor(lung2$sex, levels = c(1, 2), labels = c("Male", "Female"))

plot_survival(
  data       = lung2,
  time_col   = "time",
  status_col = "status",   # 1/2 coding -> auto-normalised to 0/1
  strata     = "sex",
  xlab       = "Time (days)"
)
```

By default the figure includes a confidence-interval ribbon, a
numbers-at-risk table, and a log-rank p-value. With no `strata`, a
single overall curve is drawn and the p-value is omitted.

### Curve type

`type` switches between the descending survival curve and the ascending
cumulative views:

``` r

# Cumulative incidence (1 - S)
plot_survival(lung2, "time", "status", strata = "sex", type = "risk")

# Cumulative hazard
plot_survival(lung2, "time", "status", strata = "sex", type = "cumhaz")
```

### Elements and styling

Toggle the optional layers with the `add_*` switches, and adjust the
axis, labels, palette, and legend:

``` r

plot_survival(
  lung2, "time", "status", strata = "sex",
  add_median  = TRUE,          # median-survival reference line
  add_censor  = TRUE,          # censoring marks
  ticks_at    = seq(0, 1000, 250),
  palette     = c("#3C5488", "#F39B7F"),
  legend_labs = c("Male", "Female"),
  title       = "Overall survival by sex"
)
```

The `theme` preset (`"default"`) controls the overall look — fonts,
legend, colour palette, and the risk-table styling — as one coherent
design. The default palette is used only when it has a colour for every
group; with more groups than colours it falls back to ggsurvfit’s
palette.

### Saving

``` r

# Writes <dest>.png / .pdf / .jpg / .tiff at 300 dpi
plot_survival(lung2, "time", "status", strata = "sex",
              save = TRUE, dest = "km_lung_by_sex")
```

------------------------------------------------------------------------

## `plot_rcs()` — Restricted Cubic Spline Curve

[`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md)
draws the dose-response curve produced by
[`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md):
the fitted effect (hazard ratio, odds ratio, or mean difference) across
the range of a continuous exposure, with a confidence band, relative to
the analysis reference value. It reads the effect measure, reference,
and exposure name from the result’s attributes, so `plot_rcs(res)` just
works.

[`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md)
builds on **ggplot2** (a `Suggests` dependency); install it with
`install.packages("ggplot2")`. Unlike the other plot functions it
returns the `ggplot` object **visibly**, so a bare `plot_rcs(res)` call
draws the curve.

### Minimal example

``` r

res <- assoc_rcs(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p21001_i0",          # BMI (continuous)
  method       = "coxph",
  base         = FALSE,                # a single, fully-adjusted curve
  covariates   = "tdi_cat"
)

plot_rcs(res)
```

The null-effect line (HR / OR = 1, or 0 for a mean difference) is drawn
automatically, the y-axis is log-scaled for ratio measures, and the
overall and non-linearity p-values are annotated in the corner as
`P-overall` / `P-nonlinear`. The panel uses a clean framed style with a
light horizontal grid.

### Clinical reference lines

`vline` and `hline` add user-supplied reference lines at clinically
meaningful exposure or effect values — dashed grey, in the spirit of
threshold lines on a GWAS plot:

``` r

plot_rcs(
  res,
  vline = c(18.5, 25, 30),   # clinical BMI cut-points (x-axis)
  hline = 1.5,               # an effect threshold (y-axis)
  p_pos = "topleft",         # move the p-value annotation
  title = "BMI and incident diabetes"
)
```

### Multiple models

When the
[`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md)
result holds more than one adjustment model (the default `base = TRUE`),
the curves are overlaid and coloured by model, with a legend at the
bottom; the p-value annotation then reports the most-adjusted model:

``` r

res_multi <- assoc_rcs(
  dt, "dm_status", "dm_followup_years", "p21001_i0",   # BMI
  method = "coxph", covariates = "tdi_cat"
)

plot_rcs(res_multi, vline = c(18.5, 25, 30))
```

### Saving

``` r

# Writes <dest>.png / .pdf / .jpg / .tiff at 300 dpi
plot_rcs(res, save = TRUE, dest = "rcs_bmi_dm")
```

------------------------------------------------------------------------

## Getting Help

- [`?plot_forest`](https://evanbio.github.io/ukbflow/reference/plot_forest.md),
  [`?plot_survival`](https://evanbio.github.io/ukbflow/reference/plot_survival.md),
  [`?plot_rcs`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md),
  [`?plot_tableone`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
- [`vignette("assoc")`](https://evanbio.github.io/ukbflow/articles/assoc.md)
  — association analysis producing forest plot inputs
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
