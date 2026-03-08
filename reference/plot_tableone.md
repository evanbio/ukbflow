# Publication-ready Table 1 (Baseline Characteristics)

Generates a publication-quality baseline-characteristics table (Table 1)
using gtsummary, with optional SMD column, *Lancet*-style theming, and
automatic export to four formats.

## Usage

``` r
plot_tableone(
  data,
  vars,
  strata = NULL,
  type = NULL,
  label = NULL,
  statistic = NULL,
  digits = NULL,
  percent = "column",
  missing = "no",
  add_p = TRUE,
  add_smd = FALSE,
  overall = FALSE,
  exclude_labels = NULL,
  theme = "lancet",
  label_width = 200,
  stat_width = 140,
  pvalue_width = 100,
  row_height = 8,
  save = FALSE,
  dest = NULL
)
```

## Arguments

- data:

  data.frame. Input data containing all variables.

- vars:

  Character vector. Variable names to display in the table.

- strata:

  Character scalar. Column name for the grouping/stratification
  variable. `NULL` produces an unstratified overall summary.

- type:

  Named list or `NULL`. Variable type overrides passed directly to
  [`tbl_summary`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html).
  E.g. `list(age = "continuous2")`.

- label:

  Named list / formula list or `NULL`. Label overrides. E.g.
  `list(age ~ "Age (years)", sex ~ "Sex")`.

- statistic:

  Named list or `NULL`. Statistic format strings. E.g.
  `list(all_continuous() ~ "{mean} ({sd})")`.

- digits:

  Named list or `NULL`. Decimal place overrides. E.g. `list(age ~ 1)`.

- percent:

  Character. Percentage base for categorical variables: `"column"`
  (default), `"row"`, or `"cell"`.

- missing:

  Character. Display of missing counts: `"no"` (default), `"ifany"`, or
  `"always"`.

- add_p:

  Logical. Add a p-value column. Default `TRUE`; silently disabled if
  `strata` is `NULL`.

- add_smd:

  Logical. Add a standardised mean difference (SMD) column. Continuous
  variables use Cohen's *d*; categorical variables use root-mean-square
  deviation (RMSD) of group proportions. SMD is shown only on label
  rows. Default `FALSE`; silently disabled if `strata` is `NULL`.

- overall:

  Logical. Add an Overall column when `strata` is set. Default `FALSE`.

- exclude_labels:

  Character vector or `NULL`. Row labels to remove from the rendered
  table, matched exactly against the `label` column in the gtsummary
  table body. E.g. `c("Unknown", "Missing")`.

- theme:

  Character. Visual theme preset. Only `"lancet"` (default) is currently
  supported. Controls alternating row shading (`#f8e8e7` / white),
  three-line borders, and 15 px font size.

- label_width:

  Integer. Label column width in pixels. Default `200`.

- stat_width:

  Integer. Statistics column(s) width in pixels. Default `140`.

- pvalue_width:

  Integer. P-value and SMD column width in pixels. Default `100`.

- row_height:

  Integer. Data row padding (top + bottom) in pixels. Default `8`.

- save:

  Logical. Export the table to files. Default `TRUE`.

- dest:

  Character or `NULL`. File path without extension. When `save = TRUE`,
  four files are written: `<dest>.docx`, `<dest>.html`, `<dest>.pdf`,
  `<dest>.png`. Required when `save = TRUE`.

## Value

A gt table object, returned invisibly.

## Details

The following behaviours are fixed (not exposed as parameters):

- Variable labels are **bold**
  ([`bold_labels()`](https://www.danieldsjoberg.com/gtsummary/reference/bold_italicize_labels_levels.html)).

- P-values are formatted as `<0.001` or to 3 decimal places.

- Significant p-values (\\p \< 0.05\\) are **bold**.

- The p-value column header is rendered as *P*-value.

- The table uses a three-line (booktabs) border.

- Saving always exports **word**, **html**, **pdf**, and **png**.

## Examples

``` r
if (FALSE) { # \dontrun{
library(gtsummary)
data(trial)

# Basic stratified table
plot_tableone(
  data   = trial,
  vars   = c("age", "marker", "grade"),
  strata = "trt",
  save   = FALSE
)

# With SMD, custom labels, exclude Unknown level
plot_tableone(
  data           = trial,
  vars           = c("age", "marker", "grade", "stage"),
  strata         = "trt",
  label          = list(age ~ "Age (years)", marker ~ "Marker level"),
  add_smd        = TRUE,
  exclude_labels = "Unknown",
  dest           = "table1",
  save           = TRUE
)
} # }
```
