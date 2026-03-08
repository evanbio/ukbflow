# Submit a large-scale phenotype extraction job via table-exporter

Submits an asynchronous table-exporter job on the DNAnexus Research
Analysis Platform for large-scale phenotype extraction. Use this instead
of
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
when extracting many fields (e.g. 50+).

## Usage

``` r
extract_batch(
  field_id,
  dataset = NULL,
  file = NULL,
  instance_type = NULL,
  priority = c("low", "high")
)
```

## Arguments

- field_id:

  (integer) Vector of UKB Field IDs to extract. `eid` is always included
  automatically.

- dataset:

  (character) Dataset file name. Default: `NULL` (auto-detect from
  project root).

- file:

  (character) Output file name on the cloud (without extension), e.g.
  `"ad_cscc_pheno"`. Default: `NULL` (auto-generate as
  `"ukb_pheno_YYYYMMDD_HHMMSS"` to avoid same-day collisions).

- instance_type:

  (character) DNAnexus instance type, e.g. `"mem1_ssd1_v2_x32"`.
  Default: `NULL` (auto-select: `x8` for up to 20 cols, `x16` for up to
  100 cols, `x32` for more than 100 cols).

- priority:

  (character) Job scheduling priority. `"low"` (recommended, cheaper) or
  `"high"` (faster queue). Default: `"low"`.

## Value

Invisibly returns the job ID string (e.g. `"job-XXXX"`).

## Details

The job runs on the cloud and typically completes in 20-40 minutes.
Monitor progress and retrieve results using the `job_` series.

## Examples

``` r
if (FALSE) { # \dontrun{
job_id <- extract_batch(core_field_ids)
job_id <- extract_batch(core_field_ids, file = "ad_cscc_pheno")
job_id <- extract_batch(core_field_ids, priority = "high")
# Monitor: job_status(job_id)
# Download: job_result(job_id, dest = "data/pheno.csv")
} # }
```
