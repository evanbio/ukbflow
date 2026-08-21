# Extract a UK Biobank primary-care (GP) record table

Exports a GP record table – `gp_clinical` (default), `gp_scripts`, or
`gp_registrations` – from the UKB Research Analysis Platform to CSV via
a table-exporter job, then reads it into a `data.table`. Unlike
[`extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
/
[`extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
which extract participant-level *fields*, GP data lives in separate
record-table *entities* (one row per event), so this exports the whole
entity's columns directly – there is no field-ID matching.

## Usage

``` r
extract_gp(
  table = c("gp_clinical", "gp_scripts", "gp_registrations"),
  columns = NULL,
  dataset = NULL,
  instance_type = "mem1_ssd1_v2_x16",
  priority = c("low", "high"),
  wait = TRUE
)
```

## Arguments

- table:

  (character) GP record table to export: `"gp_clinical"` (default),
  `"gp_scripts"`, or `"gp_registrations"`.

- columns:

  (character or NULL) Columns to export. `NULL` selects a sensible
  default for `table`; for `gp_clinical` that is `eid`, `data_provider`,
  `read_2`, `read_3`, `event_dt` – the `value1`-`value3` measurement
  columns are omitted (large and unused for diagnosis phenotyping).

- dataset:

  (character) Dataset file name. Default `NULL` (auto-detect from
  project root).

- instance_type:

  (character) Worker instance for the table-exporter job. Default
  `"mem1_ssd1_v2_x16"`.

- priority:

  (character) Job scheduling priority: `"low"` (default, cheaper) or
  `"high"`.

- wait:

  (logical) When `TRUE` (default), wait for the job, read the output
  from RAP project storage, and return the `data.table`. When `FALSE`,
  submit and return the job ID (retrieve later with
  [`job_wait`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
  /
  [`job_result`](https://evanbio.github.io/ukbflow/reference/job_result.md)).

## Value

When `wait = TRUE`, a `data.table` with one row per GP record (raw,
unprocessed). When `wait = FALSE`, the job ID string (invisibly).

## Details

The output is the **raw** long table: no date parsing, code matching, or
filtering. Turning it into phenotypes is the job of
[`derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
/
[`derive_gp_ctv3`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md),
which take the returned table as their `gp` argument. Load it once and
reuse it across derive calls.

The export runs as a cloud table-exporter job on its own worker instance
(`instance_type`); the calling RStudio session only submits it. For
`gp_clinical` (~118M rows, ~3 GB) this typically takes 10-15 minutes.
Must be run inside the RAP environment.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load gp_clinical once, then derive many phenotypes from it
gp <- extract_gp()
cohort <- derive_gp_read2(cohort, "t2d", read2 = "C10F.", gp = gp)
cohort <- derive_gp_ctv3(cohort, "t2d", ctv3 = "XaELP",  gp = gp)

# Async: submit only, retrieve later
job_id <- extract_gp(wait = FALSE)
job_wait(job_id)
gp <- job_result(job_id)
} # }
```
