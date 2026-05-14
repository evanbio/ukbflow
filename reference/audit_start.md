# Start a ukbflow audit record

Creates a minimal S3 audit object for one analysis. The object records
only the root metadata needed to identify and reproduce the analysis
context: analysis name, start time, ukbflow version, R session
information, and the current DNAnexus user / project when available.
Later audit helpers can append fields, snapshots, exclusions, models,
and jobs to this object.

## Usage

``` r
audit_start(name)
```

## Arguments

- name:

  (character) User-defined analysis name, e.g. `"ad_nmsc_analysis"`.
  This is not a DNAnexus project ID.

## Value

An S3 object with class `c("ukbflow_audit", "list")`.

## Details

DNAnexus context is captured opportunistically. If the dx CLI is
unavailable, the user is not logged in, or no project is selected, the
corresponding fields are recorded as `NA` without failing.

## Examples

``` r
aud <- audit_start("example_analysis")
aud
#> 
#> ── ukbflow audit ───────────────────────────────────────────────────────────────
#> name: "example_analysis"
#> start_time: "2026-05-14T05:30:16+0000"
#> ukbflow_version: "0.3.4"
#> dx_user: "NA"
#> dx_project: "NA"
#> extraction records: 0
#> snapshots: 0
#> session_info: recorded
```
