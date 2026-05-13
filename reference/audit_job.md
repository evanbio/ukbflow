# Record a DNAnexus job in an audit manifest

Records a DNAnexus job ID and, when available, lightweight metadata from
`dx describe job-XXXX --json`. The function is best-effort: if the job
cannot be described in the current environment, the job ID is still
recorded and metadata fields are set to `NA`. Cost is not estimated.

## Usage

``` r
audit_job(audit, job_id, label = NULL)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- job_id:

  (character) DNAnexus job ID, e.g. `"job-XXXX"`.

- label:

  (character or NULL) Optional label for this job record. Default:
  `NULL`, which creates `"job_N"`.

## Value

The updated `ukbflow_audit` object.

## Examples

``` r
aud <- audit_start("example_analysis")
if (FALSE) { # \dontrun{
job_id <- extract_batch(c(31, 53, 21022))
aud <- audit_job(aud, job_id, "phenotype_extraction")
} # }
```
