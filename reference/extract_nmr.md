# Export the UK Biobank Nightingale NMR metabolomics data

Exports the 249 Nightingale NMR metabolic biomarkers for one assessment
instance from the RAP, as ordinary participant fields (like
[`extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)),
returning the raw wide table for downstream decoding and QC. **Runs on
the RAP.**

## Usage

``` r
extract_nmr(
  instance = 0,
  fields = NULL,
  dataset = NULL,
  instance_type = "mem1_ssd1_v2_x16",
  priority = c("low", "high"),
  wait = TRUE
)
```

## Arguments

- instance:

  (numeric) Assessment instance: `0` (baseline, default) or `1` (repeat
  assessment).

- fields:

  (integer or NULL) NMR field IDs to export. `NULL` (default) uses the
  249 biomarker fields `23400:23648`. Supply a subset (e.g.
  `c(23400, 23407)`) to export only those.

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

When `wait = TRUE`, a `data.table` with `eid` and one column per
exported biomarker at the requested instance. When `wait = FALSE`, the
submitted job ID (invisibly).

## Details

The 249 biomarkers (168 absolute measures + 81 ratios) are UK Biobank
fields `23400`-`23648` (contiguous), instanced (`_i0` baseline, `_i1`
repeat). The default exports exactly these at instance 0. The two
early-release technical fields (`20280` glucose-lactate, `20281`
spectrometer-corrected alanine) and the per-biomarker QC-flag fields
(`23700`-`23948`) are **not** exported - those are QC concerns for a
downstream step, not part of this raw export.

Columns come back with their raw UKB names (`p23400_i0`, ...); decode
them to biomarker titles with
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md).

Must be run inside the RAP environment.

## See also

[`extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
for arbitrary participant fields,
[`extract_olink`](https://evanbio.github.io/ukbflow/reference/extract_olink.md)
for the Olink proteomics entity.
