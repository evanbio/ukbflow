# Check the ukbflow operating environment

Runs a four-block health check covering the dx CLI, dxpy (Python), RAP
authentication, and R package dependencies. Designed to be the first
function a new user runs after installation.

## Usage

``` r
ops_setup(
  check_dx = TRUE,
  check_auth = TRUE,
  check_deps = TRUE,
  verbose = TRUE
)
```

## Arguments

- check_dx:

  (logical) Check dx CLI installation (dxpy is implied by dx).

- check_auth:

  (logical) Check RAP login status.

- check_deps:

  (logical) Check R package dependencies.

- verbose:

  (logical) Print the formatted report. Set to `FALSE` for programmatic
  use (results are still returned invisibly).

## Value

An invisible named list with elements `dx`, `dxpy`, `auth`, `deps`, and
`summary`. Each element reflects the result of its respective check
block and can be inspected programmatically.

## Details

The function is **read-only**: it never modifies system state, installs
packages, or authenticates. Auth failures are reported as warnings, not
errors, because the check itself does not require a live RAP connection.

## Examples

``` r
ops_setup(check_dx = FALSE, check_auth = FALSE)
#> ── ukbflow environment check ───────────────────────────────────────────────────
#> ℹ ukbflow 0.3.3 | R 4.5.3 | 2026-04-01
#> ── 3. R packages ───────────────────────────────────────────────────────────────
#> ✔ cli  3.6.5  [core]
#> ✔ data.table  1.18.2.1  [core]
#> ✔ processx  3.8.6  [core]
#> ✔ rlang  1.1.7  [core]
#> ✔ tools  4.5.3  [core]
#> ✔ curl  7.0.0  [extract / fetch]
#> ✔ jsonlite  2.0.0  [extract / fetch]
#> ✔ survival  3.8.6  [assoc_coxph]
#> ✔ dplyr  1.2.0  [assoc / derive]
#> ✔ tidyselect  1.2.1  [assoc / derive]
#> ✔ forestploter  1.1.3  [plot_forest]
#> ✔ broom  1.0.12  [plot_tableone]
#> ✔ gt  1.3.0  [plot_tableone]
#> ✔ gtsummary  2.5.0  [plot_tableone]
#> ✔ pROC  1.19.0.1  [assoc (optional)]
#> ✔ knitr  1.51  [vignettes]
#> ✔ rmarkdown  2.31  [vignettes]
#> ────────────────────────────────────────────────────────────────────────────────
#> ✔ 17 passed

result <- ops_setup(check_dx = FALSE, check_auth = FALSE, verbose = FALSE)
result$summary$fail == 0
#> [1] TRUE
```
