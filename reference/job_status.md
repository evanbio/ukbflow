# Check the current state of a DNAnexus job

Returns the current state of a job submitted by
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).
For failed jobs, the failure message is attached as an attribute.

## Usage

``` r
job_status(job_id)
```

## Arguments

- job_id:

  (character) Job ID returned by
  [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
  e.g. `"job-XXXX"`.

## Value

A named character string — the job state. Possible values:

- `"idle"`:

  Queued, waiting to be scheduled.

- `"runnable"`:

  Resources being allocated.

- `"running"`:

  Actively executing.

- `"done"`:

  Completed successfully.

- `"failed"`:

  Failed; see `attr(result, "failure_message")`.

- `"terminated"`:

  Manually terminated.

## Examples

``` r
if (FALSE) { # \dontrun{
job_id <- extract_batch(c(31, 53, 21022))
job_status(job_id)

s <- job_status(job_id)
if (s == "failed") cli::cli_inform(attr(s, "failure_message"))
} # }
```
