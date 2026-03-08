# Load the result of a completed DNAnexus job into R

Reads the output CSV produced by
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
directly from RAP project storage and returns a `data.table`. Must be
run inside the RAP environment.

## Usage

``` r
job_result(job_id)
```

## Arguments

- job_id:

  (character) Job ID returned by
  [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).

## Value

A `data.table` with one row per participant.

## Examples

``` r
if (FALSE) { # \dontrun{
job_id <- extract_batch(c(31, 53, 21022))
job_wait(job_id)
df <- job_result(job_id)
} # }
```
