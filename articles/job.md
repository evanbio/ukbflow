# Monitoring and Retrieving Extraction Jobs

## Overview

When
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
submits a table-exporter job, it runs asynchronously on the RAP cloud.
The `job_*` functions let you monitor progress, inspect job history, and
load results once the job completes.

------------------------------------------------------------------------

## Typical Workflow

``` r
library(ukbflow)

# 1. Submit extraction job
job_id <- extract_batch(c(31, 53, 21022, 22189), file = "ukb_demographics")

# 2. Wait for completion
job_wait(job_id)

# 3. Load result (RAP only)
df <- job_result(job_id)
```

------------------------------------------------------------------------

## Monitoring a Job

### Check status

[`job_status()`](https://evanbio.github.io/ukbflow/reference/job_status.md)
returns the current state of a job:

``` r
job_status(job_id)
#> job-XXXXXXXXXXXX
#>            done
```

Possible states:

| State        | Meaning                         |
|--------------|---------------------------------|
| `idle`       | Queued, waiting to be scheduled |
| `runnable`   | Resources being allocated       |
| `running`    | Actively executing              |
| `done`       | Completed successfully          |
| `failed`     | Failed — see failure message    |
| `terminated` | Manually terminated             |

For failed jobs, the error message is accessible via:

``` r
s <- job_status(job_id)
if (s == "failed") cli::cli_inform(attr(s, "failure_message"))
```

### Wait for completion

[`job_wait()`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
polls at regular intervals until the job reaches a terminal state:

``` r
job_wait(job_id)                    # wait indefinitely (default)
job_wait(job_id, interval = 60)     # poll every 60 seconds
job_wait(job_id, timeout = 7200)    # give up after 2 hours
```

[`job_wait()`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
stops with an error if the job fails or is terminated, so you can safely
chain it with
[`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md):

``` r
job_wait(job_id)
df <- job_result(job_id)
```

------------------------------------------------------------------------

## Retrieving Results

### Get the file path

[`job_path()`](https://evanbio.github.io/ukbflow/reference/job_path.md)
returns the `/mnt/project/` path of the output CSV on RAP:

``` r
path <- job_path(job_id)
#> "/mnt/project/results/ukb_demographics.csv"
```

Use this to read the file directly or pass it to other tools:

``` r
df <- data.table::fread(job_path(job_id))
```

### Load into R

[`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md)
combines
[`job_path()`](https://evanbio.github.io/ukbflow/reference/job_path.md)
and `fread()` in one step. Must be run inside the RAP environment:

``` r
df <- job_result(job_id)
# returns a data.table, e.g. 502353 rows x 5 cols (incl. eid)
```

------------------------------------------------------------------------

## Browsing Job History

[`job_ls()`](https://evanbio.github.io/ukbflow/reference/job_ls.md)
returns a summary of recent jobs:

``` r
job_ls()          # last 20 jobs
job_ls(n = 5)     # last 5 jobs

# Filter by state
job_ls(state = "failed")
job_ls(state = c("done", "failed"))
```

The result is a data.frame with columns:

| Column    | Description                                            |
|-----------|--------------------------------------------------------|
| `job_id`  | Job ID, e.g. `job-XXXXXXXXXXXX`                        |
| `name`    | Job name (typically `Table exporter`)                  |
| `state`   | Current state                                          |
| `created` | Job creation time (`POSIXct`)                          |
| `runtime` | Runtime string, e.g. `0:04:36` (`NA` if still running) |

------------------------------------------------------------------------

## Getting Help

- [`?job_status`](https://evanbio.github.io/ukbflow/reference/job_status.md),
  [`?job_wait`](https://evanbio.github.io/ukbflow/reference/job_wait.md),
  [`?job_path`](https://evanbio.github.io/ukbflow/reference/job_path.md),
  [`?job_result`](https://evanbio.github.io/ukbflow/reference/job_result.md),
  [`?job_ls`](https://evanbio.github.io/ukbflow/reference/job_ls.md)
- [`vignette("extract")`](https://evanbio.github.io/ukbflow/articles/extract.md)
  — submitting extraction jobs
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
