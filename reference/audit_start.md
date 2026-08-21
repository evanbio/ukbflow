# Start a ukbflow audit record

Creates an S3 audit object for one analysis with a fixed skeleton: a
`schema_version`, a `meta` block (analysis name, start time, ukbflow and
R versions, platform, R session information, and the current DNAnexus
user / project when available), and the empty record layers `fields`,
`recipes`, `snapshots`, `phenotypes`, `models`, and `jobs`. Later audit
helpers append records to these layers; the skeleton is present from the
start so the object shape is stable and predictable.

## Usage

``` r
audit_start(name, check_dx = TRUE)

# S3 method for class 'ukbflow_audit'
print(x, ...)

# S3 method for class 'ukbflow_audit'
summary(object, ...)
```

## Arguments

- name:

  (character) User-defined analysis name, e.g. `"ad_nmsc_analysis"`.
  This is not a DNAnexus project ID.

- check_dx:

  (logical) Capture the current DNAnexus user and project. Set to
  `FALSE` to avoid calling the dx CLI. The corresponding metadata fields
  are recorded as `NA`. Default: `TRUE`.

- x:

  A `ukbflow_audit` object.

- ...:

  Ignored.

- object:

  A `ukbflow_audit` object.

## Value

An S3 object with class `c("ukbflow_audit", "list")`.

## Details

DNAnexus context is captured opportunistically. If the dx CLI is
unavailable, the user is not logged in, or no project is selected, the
corresponding fields are recorded as `NA` without failing.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
aud
#> 
#> ── ukbflow audit ───────────────────────────────────────────────────────────────
#> name: "example_analysis"
#> start_time: "2026-08-21T07:32:33+0000"
#> ukbflow_version: "0.4.0"
#> dx_user: "NA"
#> dx_project: "NA"
#> fields: 0
#> recipes: 0
#> snapshots: 0
#> phenotypes: 0
#> models: 0
#> jobs: 0
#> session_info: recorded
```
