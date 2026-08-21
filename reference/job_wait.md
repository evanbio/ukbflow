# Wait for a DNAnexus job to finish

Polls
[`job_status()`](https://evanbio.github.io/ukbflow/reference/job_status.md)
at regular intervals until the job reaches a terminal state (`"done"`,
`"failed"`, or `"terminated"`). Stops with an error if the job fails, is
terminated, or times out.

## Usage

``` r
job_wait(job_id, interval = 30, timeout = Inf, verbose = TRUE)
```

## Arguments

- job_id:

  (character) Job ID returned by
  [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).

- interval:

  (integer) Polling interval in seconds. Default: `30`.

- timeout:

  (numeric) Maximum wait time in seconds. Default: `Inf` (wait
  indefinitely). On UKB RAP, jobs can stay in `"runnable"` for several
  hours during peak times — set a finite value (e.g. `7200`) only if you
  need a hard deadline.

- verbose:

  (logical) Print state and elapsed time at each poll. Default: `TRUE`.

## Value

Invisibly returns the final state string (`"done"`).

## Examples

``` r
if (FALSE) { # \dontrun{
job_id <- extract_batch(c(31, 53, 21022))
job_wait(job_id)

# Read result immediately after completion (RAP only)
job_wait(job_id)
df <- job_result(job_id)
} # }
```
