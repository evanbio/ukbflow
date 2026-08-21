# Extracting Phenotype Data

## Overview

UKB phenotype data is stored in a proprietary `.dataset` format on the
RAP and cannot be read directly. The `extract_*` functions provide R
interfaces for discovering approved fields and extracting phenotype data
via the DNAnexus `dx extract_dataset` and `table-exporter` tools.

Five workflows are available:

| Function | Mode | Scale | Output |
|----|----|----|----|
| [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md) | Async job | Large / production (typically 50+ fields) | job ID → CSV on RAP cloud |
| [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md) | Synchronous | Small (quick checks) | data.table in memory |
| [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md) | Async job (waits by default) | GP record tables (`gp_clinical`, etc.) | data.table in memory |
| [`extract_olink()`](https://evanbio.github.io/ukbflow/reference/extract_olink.md) | Async job (waits by default) | Olink proteomics entity (~2900 proteins) | data.table in memory |
| [`extract_nmr()`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md) | Async job (waits by default) | 249 Nightingale NMR biomarkers | data.table in memory |

**[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
is the recommended approach** for any serious analysis.
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
is provided for quick interactive inspection inside the RAP environment
only.

The distinction that decides which function you need is **fields versus
record-table entities**:

- [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
  [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
  and
  [`extract_nmr()`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md)
  pull participant-level **fields** (`p31`, `p53_i0`, `p23400_i0`, …),
  matched by field ID.
- [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)
  and
  [`extract_olink()`](https://evanbio.github.io/ukbflow/reference/extract_olink.md)
  export a whole **record-table entity** — `gp_clinical`,
  `olink_instance_0` — whose columns are not participant fields at all,
  so there is no field-ID matching to do.

NMR sits on the field side despite being an assay panel: each of the 249
biomarkers is an ordinary instanced field. Olink does not, which is why
it needs its own function rather than a long
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
call.

------------------------------------------------------------------------

## Prerequisites

Ensure you are authenticated and have selected your project:

``` r

library(ukbflow)

auth_login()
auth_select_project("project-XXXXXXXXXXXX")
```

------------------------------------------------------------------------

## Step 1: Browse Available Fields

Before extracting, use
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
to explore what fields are approved for your project:

``` r

# List all approved fields (cached after first call)
extract_ls()

# Search by keyword
extract_ls(pattern = "cancer")
extract_ls(pattern = "p31|p53|p21022")

# Force refresh after switching projects or datasets
extract_ls(refresh = TRUE)
```

The result is a data.frame with two columns:

| Column       | Example                                             |
|--------------|-----------------------------------------------------|
| `field_name` | `participant.p53_i0`                                |
| `title`      | `Date of attending assessment centre \| Instance 0` |

> Fields reflect your project’s approved data only — not all UKB fields
> are present.

------------------------------------------------------------------------

## Step 2: Extract Data

### Recommended: `extract_batch()`

For large-scale or production extractions, submit an asynchronous
table-exporter job on the RAP cloud:

``` r

# Submit extraction job
job_id <- extract_batch(c(31, 53, 21022, 22189))

# Custom output name
job_id <- extract_batch(
  field_id = c(31, 53, 21022, 22189),
  file     = "ukb_demographics"
)

# High priority (faster queue, higher cost)
job_id <- extract_batch(
  field_id = c(31, 53, 21022, 22189),
  priority = "high"
)
```

The job runs asynchronously on the RAP cloud. The output CSV is saved to
your RAP project and can be monitored with the `job_` series:

``` r

job_status(job_id)        # check progress
job_path(job_id)          # get cloud file path once complete
job_result(job_id)        # read result as data.table (inside RAP only)
```

#### Instance type

[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
automatically selects an appropriate instance based on the number of
columns:

| Columns | Instance           |
|---------|--------------------|
| ≤ 20    | `mem1_ssd1_v2_x4`  |
| ≤ 100   | `mem1_ssd1_v2_x8`  |
| ≤ 500   | `mem1_ssd1_v2_x16` |
| \> 500  | `mem1_ssd1_v2_x36` |

You can override this with the `instance_type` argument if needed.

------------------------------------------------------------------------

### Quick inspection: `extract_pheno()`

For small-scale interactive checks **inside the RAP RStudio
environment**:

``` r

df <- extract_pheno(c(31, 53, 21022))
```

> [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
> is restricted to the RAP environment and returns data in memory only.
> For any analysis intended to be saved or reproduced, use
> [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).

Note:
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
returns **raw coded values** (e.g. `1`/`0` for Sex, numeric codes for
diseases). Use the `decode_*` series to convert codes to human-readable
labels.

### Primary care (GP) records: `extract_gp()`

Primary-care data is not a set of participant fields — it lives in
separate **record-table entities** (`gp_clinical`, `gp_scripts`,
`gp_registrations`), one row per clinical event.
[`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)
exports a whole entity via a table-exporter job and returns the **raw**
long table (no date parsing, code matching, or filtering — that is
[`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
/
[`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md)’s
job). It runs inside the RAP environment; the export runs on its own
worker instance (default `mem1_ssd1_v2_x16`), which for `gp_clinical`
(~118M rows, ~3 GB) typically takes 10-15 minutes.

``` r

# Load gp_clinical once (default columns: eid, data_provider, read_2, read_3,
# event_dt; value1-value3 omitted), then derive many phenotypes from it
gp <- extract_gp()

cohort <- derive_gp_read2(cohort, "t2d", read2 = "C10F.", gp = gp)
cohort <- derive_gp_ctv3(cohort,  "t2d", ctv3  = "XaELP", gp = gp)

# Async: submit only, retrieve later with job_wait() / job_result()
job_id <- extract_gp(wait = FALSE)
```

### Olink proteomics: `extract_olink()`

The Olink NPX data lives in the `olink_instance_{0,2,3}` entities —
baseline and the two imaging visits. Each is a wide record table: one
column per protein (~2900, named by assay, e.g. `a1bg`) plus `eid`.
[`extract_olink()`](https://evanbio.github.io/ukbflow/reference/extract_olink.md)
discovers the entity’s columns rather than hardcoding the protein names,
exports them all, and returns the raw wide table with `eid` moved to the
front.

**Prerequisite**: field `30900` (“Number of proteins measured”) must be
in the project basket to unlock the Olink entities. The per-sample QC
fields (`p30901` plate, `p30902` well) are ordinary participant fields —
pull them with
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
if you need them.

``` r

# Whole baseline panel (~2900 proteins)
olink <- extract_olink()

# One of the imaging visits
olink_i2 <- extract_olink(instance = 2)

# A named subset, skipping column discovery
inflam <- extract_olink(columns = c("eid", "crp", "il6"))
```

### Nightingale NMR metabolomics: `extract_nmr()`

The 249 Nightingale biomarkers (168 absolute measures + 81 ratios) are
UK Biobank fields `23400`-`23648`, instanced `_i0` (baseline) and `_i1`
(repeat assessment).
[`extract_nmr()`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md)
matches them like any other field and keeps only the requested
instance’s column for each.

Columns come back with their raw UKB names (`p23400_i0`, …). Look a
field ID up offline with `ops_fields_common(group = "nmr")`, or decode a
whole extract to biomarker titles with
[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md).

``` r

# All 249 biomarkers at baseline
nmr <- extract_nmr()

# Repeat assessment — a ~20,000-participant subset
nmr_i1 <- extract_nmr(instance = 1)

# A named subset
nmr_lipids <- extract_nmr(fields = c(23400,   # Total Cholesterol
                                     23406,   # HDL Cholesterol
                                     23407))  # Total Triglycerides
```

Both functions return the **raw** table. Mapping assay columns, batch
and limit-of-detection adjustment, and the per-biomarker QC-flag fields
(`23700`-`23948`) are downstream concerns, not part of the export.

------------------------------------------------------------------------

## A Note on Column Names

Column naming differs between the two extraction methods:

**[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)**
— no prefix:

| Column         | Meaning                          |
|----------------|----------------------------------|
| `eid`          | Participant ID                   |
| `p31`          | Field 31 (Sex)                   |
| `p53_i0`       | Field 53, Instance 0             |
| `p20002_i0_a0` | Field 20002, Instance 0, Array 0 |

**[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)**
— `participant.` prefix:

| Column                     | Meaning                          |
|----------------------------|----------------------------------|
| `participant.eid`          | Participant ID                   |
| `participant.p31`          | Field 31 (Sex)                   |
| `participant.p53_i0`       | Field 53, Instance 0             |
| `participant.p20002_i0_a0` | Field 20002, Instance 0, Array 0 |

------------------------------------------------------------------------

## Getting Help

- [`?extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md),
  [`?extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md),
  [`?extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
  [`?extract_gp`](https://evanbio.github.io/ukbflow/reference/extract_gp.md),
  [`?extract_olink`](https://evanbio.github.io/ukbflow/reference/extract_olink.md),
  [`?extract_nmr`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md)
- [`vignette("auth")`](https://evanbio.github.io/ukbflow/articles/auth.md)
  — authentication setup
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
