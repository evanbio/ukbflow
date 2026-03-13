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
if (FALSE) { # \dontrun{
ops_setup()

# Programmatic use — check if environment is ready
result <- ops_setup(verbose = FALSE)
result$summary$fail == 0
} # }
```
