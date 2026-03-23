# List recent DNAnexus jobs in the current project

Returns a summary of the most recent jobs, optionally filtered by state.
Useful for quickly reviewing which jobs have completed, failed, or are
still running.

## Usage

``` r
job_ls(n = 20, state = NULL)
```

## Arguments

- n:

  (integer) Maximum number of recent jobs to return. Must be a single
  positive integer. Default: `20`.

- state:

  (character) Filter by state(s). Must be `NULL` or a character vector
  of valid states: `"idle"`, `"runnable"`, `"running"`, `"done"`,
  `"failed"`, `"terminated"`. Default: `NULL` (return all).

## Value

A data.frame with columns:

- job_id:

  Job ID string, e.g. `"job-XXXX"`.

- name:

  Job name (typically `"Table exporter"`).

- state:

  Current job state.

- created:

  Job creation time (`POSIXct`).

- runtime:

  Runtime string (e.g. `"0:04:36"`), `NA` if still running.

## Examples

``` r
if (FALSE) { # \dontrun{
job_ls()
job_ls(n = 5)
job_ls(state = "failed")
job_ls(state = c("done", "failed"))
} # }
```
