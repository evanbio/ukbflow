# Publication-Ready Visualisation

## Overview

Two functions produce publication-ready figures and tables with minimal
post-processing:

| Function                                                                          | Output                               | Typical use                         |
|-----------------------------------------------------------------------------------|--------------------------------------|-------------------------------------|
| [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)     | Forest plot (PNG / PDF / JPG / TIFF) | Regression results from `assoc_*()` |
| [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md) | Table 1 (DOCX / HTML / PDF / PNG)    | Baseline characteristics            |

Both functions save all formats in a single call and return the
plot/table object invisibly for further customisation.

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
  ci_column = 2L,
  indent    = c(0L,   1L,   1L),
  p_cols    = "p_value",
  xlim      = c(0.5,  3.0)
)
plot(p)
```

### Building the input data frame from `assoc_*()` results

The output of
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
(and siblings) can be reshaped directly into the format expected by
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md):

``` r
res <- assoc_coxph(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "outcome_followup_years",
  exposure_col = "exposure",
  covariates   = c("age_at_recruitment", "sex", "tdi", "smoking_status_i0")
)

# Reshape: one row per model, label column first
df <- data.frame(
  item    = c("Exposure", as.character(res$model)),
  `N`     = c("", paste0(res$n, " / ", res$n_events)),
  p_value = c(NA_real_, res$p_value),
  check.names = FALSE
)

p <- plot_forest(
  data      = df,
  est       = c(NA,   res$HR),
  lower     = c(NA,   res$CI_lower),
  upper     = c(NA,   res$CI_upper),
  ci_column = 2L,
  indent    = c(0L,   rep(1L, nrow(res))),
  p_cols    = "p_value",
  xlim      = c(0.5,  2.5),
  save      = TRUE,
  dest      = "forest_exposure"   # saves .png / .pdf / .jpg / .tiff
)
```

### Key parameters

**CI appearance**

``` r
p <- plot_forest(
  data      = df,
  est       = est, lower = lower, upper = upper,
  ci_column = 2L,
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
  ci_column  = 2L,
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
  ci_column   = 2L,
  p_cols      = "p_value",
  p_digits    = 3L,
  bold_p      = TRUE,
  p_threshold = 0.05
)
```

**Background and borders**

``` r
p <- plot_forest(
  data       = df,
  est        = est, lower = lower, upper = upper,
  ci_column  = 2L,
  background = "zebra",       # "zebra" | "bold_label" | "none"
  bg_col     = "#F0F0F0",     # shading colour
  border     = "three_line",  # "three_line" | "none"
  border_width = 3            # scalar or length-3 vector (top / mid / bottom)
)
```

**Layout and saving**

``` r
p <- plot_forest(
  data        = df,
  est         = est, lower = lower, upper = upper,
  ci_column   = 2L,
  row_height  = NULL,   # auto (8 / 12 / 10 / 15 mm); or scalar/vector
  col_width   = NULL,   # auto (rounds up to nearest 5 mm)
  save        = TRUE,
  dest        = "results/forest_main",   # extension ignored; all 4 formats saved
  save_width  = 20,     # cm
  save_height = NULL    # auto: nrow(data) * 0.9 + 3 cm
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
  add_smd = TRUE,
  overall = TRUE,
  dest    = "results/table1",
  save    = TRUE
)
#> ✔ Saved: results/table1.docx
#> ✔ Saved: results/table1.html
#> ✔ Saved: results/table1.pdf
#> ✔ Saved: results/table1.png
```

### Key parameters

**Variable types and statistics**

``` r
plot_tableone(
  data      = cohort,
  vars      = c("age_at_recruitment", "bmi", "sex", "smoking_status_i0"),
  strata    = "outcome_status",
  type      = list(age_at_recruitment = "continuous2"),   # show median + IQR
  statistic = list(
    all_continuous()  ~ "{mean} ({sd})",
    all_categorical() ~ "{n} ({p}%)"
  ),
  digits    = list(age_at_recruitment ~ 1, bmi ~ 1),
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
  data    = cohort,
  vars    = c("age_at_recruitment", "bmi", "sex"),
  strata  = "outcome_status",
  add_smd = TRUE,
  save    = FALSE
)
```

**Excluding rows**

Use `exclude_labels` to remove specific level rows from the rendered
table (e.g. a redundant reference category or an “Unknown” level):

``` r
plot_tableone(
  data           = cohort,
  vars           = c("sex", "smoking_status_i0"),
  strata         = "outcome_status",
  exclude_labels = "Unknown",
  save           = FALSE
)
```

**Export formats**

When `save = TRUE`, four files are written simultaneously:

| Format  | Tool                                                                               | Notes                       |
|---------|------------------------------------------------------------------------------------|-----------------------------|
| `.docx` | [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html)                     | Ready for Word submission   |
| `.html` | [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html)                     | Interactive preview         |
| `.pdf`  | [`pagedown::chrome_print()`](https://rdrr.io/pkg/pagedown/man/chrome_print.html)   | Requires Chrome / Chromium  |
| `.png`  | [`webshot2::webshot()`](https://rstudio.github.io/webshot2/reference/webshot.html) | 2x zoom, table element only |

> PDF and PNG rendering requires `pagedown` and `webshot2` respectively.
> Install with `install.packages(c("pagedown", "webshot2"))`.

------------------------------------------------------------------------

## Getting Help

- [`?plot_forest`](https://evanbio.github.io/ukbflow/reference/plot_forest.md),
  [`?plot_tableone`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
- [`vignette("assoc")`](https://evanbio.github.io/ukbflow/articles/assoc.md)
  — association analysis producing forest plot inputs
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
