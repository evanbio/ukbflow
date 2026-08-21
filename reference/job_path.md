# Get the RAP file path of a completed DNAnexus job output

Returns the absolute `/mnt/project/` path of the CSV produced by
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).
Use this to read the file directly on the RAP without downloading.

## Usage

``` r
job_path(job_id)
```

## Arguments

- job_id:

  (character) Job ID returned by
  [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).

## Value

A character string — the absolute path to the output CSV under
`/mnt/project/`.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- job_path(job_id)
df   <- data.table::fread(path)
} # }
```
