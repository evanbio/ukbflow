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

A character string – the absolute path to the output CSV under
`/mnt/project/`.

## Details

Must be run inside the RAP environment: the path it returns lives under
the `/mnt/project` mount, which exists only there.
[`job_status`](https://evanbio.github.io/ukbflow/reference/job_status.md),
[`job_wait`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
and [`job_ls`](https://evanbio.github.io/ukbflow/reference/job_ls.md)
query the DNAnexus API rather than the mount and carry no such
requirement.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- job_path(job_id)
df   <- data.table::fread(path)
} # }
```
