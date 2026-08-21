# Export the UK Biobank Olink proteomics data

Exports the Olink NPX (normalised protein expression) data from the RAP
for one assessment instance, mirroring
[`extract_gp`](https://evanbio.github.io/ukbflow/reference/extract_gp.md):
a clean `table-exporter` export of a whole record-table entity,
returning the raw table for downstream decoding and QC. **Runs on the
RAP.**

## Usage

``` r
extract_olink(
  instance = 0,
  columns = NULL,
  dataset = NULL,
  instance_type = "mem1_ssd1_v2_x16",
  priority = c("low", "high"),
  wait = TRUE
)
```

## Arguments

- instance:

  (numeric) Assessment instance: `0` (baseline, default), `2`, or `3`
  (imaging visits). Selects the `olink_instance_{instance}` entity.

- columns:

  (character or NULL) Columns to export. `NULL` (default) exports every
  column of the entity (`eid` + all proteins). Supply a subset (e.g.
  `c("eid", "crp", "il6")`) to export only those.

- dataset:

  (character or NULL) Dataset to export from. `NULL` (default)
  auto-detects the dataset in the current project.

- instance_type:

  (character) DNAnexus instance type for the table-exporter job.
  Default: `"mem1_ssd1_v2_x16"`.

- priority:

  (character) Job priority: `"low"` (default) or `"high"`.

- wait:

  (logical) If `TRUE` (default), wait for the job and return the
  exported table. If `FALSE`, submit and return the job ID.

## Value

When `wait = TRUE`, a `data.table` with `eid` first and one column per
exported protein (NPX values). When `wait = FALSE`, the submitted job ID
(invisibly).

## Details

The Olink data lives in the `olink_instance_{0,2,3}` entities (baseline
and the two imaging visits). Each is a wide table: one column per
protein (~2900, named by assay, e.g. `a1bg`) plus `eid`, with cells
holding the NPX value. `extract_olink()` discovers the entity's columns
(the protein names are not hardcoded) and exports them all, returning
the raw wide table unchanged apart from moving `eid` to the first
column.

**Prerequisite**: field `30900` ("Number of proteins measured") must be
in the RAP basket to unlock the Olink entities. Per-sample QC fields
(`p30901` plate, `p30902` well) are ordinary participant fields; pull
them with
[`extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
if needed. Mapping the assay columns and any batch/LOD adjustment are
downstream (decode / derive) steps, not part of this raw export.

Must be run inside the RAP environment.

## See also

[`extract_gp`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)
for the same export mechanism on GP record tables,
[`extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
for participant fields.
