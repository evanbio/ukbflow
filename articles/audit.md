# Analysis Audit and Reproducibility

## Overview

The `audit_*` functions create a lightweight analysis manifest. They are
not a workflow engine: the goal is to add small audit records at natural
points in an ordinary ukbflow analysis, using objects that already exist
in the script.

A typical audit captures:

- the analysis name, ukbflow version, session information, and optional
  RAP context;
- the UKB field IDs requested for extraction;
- dataset snapshots at key stages, including row count, column count,
  missingness count, object size, and complete column names;
- derived phenotype summaries from standard `derive_*` column names;
- association result tables returned by `assoc_*`;
- DNAnexus job IDs and lightweight job metadata when available;
- a JSON manifest that can be saved with the analysis outputs.

The examples below use synthetic data from
[`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
and can be developed without RAP access. In a real RAP project, the same
audit calls sit next to
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
[`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md),
`derive_*()`, and `assoc_*()` calls.

------------------------------------------------------------------------

## Start an Audit

Start one audit object near the beginning of the analysis.

``` r

library(ukbflow)

aud <- audit_start("smoking_lung_cancer")
aud
```

[`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
records the analysis name, start time, ukbflow version, R session
information, and current DNAnexus user/project when available. If the dx
CLI or RAP context is unavailable, those fields are recorded as `NA`
without failing.

------------------------------------------------------------------------

## Record Field IDs

Field IDs are usually already stored in a vector before extraction.
Reuse that object directly in the audit.

``` r

fields <- c(
  31, 53, 21022, 21001, 20116, 1558, 22189, 54,
  22009, 20001, 20006, 40006, 40011, 40012, 40005, 40000
)

aud <- audit_fields(aud, fields, label = "analysis_fields")

# In a RAP workflow this same vector can be used for extraction:
# job_id <- extract_batch(field_id = fields, file = "lung_analysis_pheno")
# aud <- audit_job(aud, job_id, "phenotype_extraction")
```

The manifest stores the declared field IDs, an optional dataset name, a
label, the number of fields, and a timestamp.

[`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
records the DNAnexus job ID and any lightweight metadata available from
`dx describe job-XXXX --json`, such as job state and output file ID. It
does not estimate RAP cost; use the DNAnexus / RAP billing interface for
cost review.

------------------------------------------------------------------------

## Snapshot Data States

Use snapshots at points where the dataset changes meaningfully: raw
data, after phenotype derivation, after exclusions, and immediately
before modelling.

``` r

data <- ops_toy(scenario = "cohort", n = 1000, seed = 2026)
aud <- audit_snapshot(aud, data, "raw")

data <- derive_missing(data)
aud <- audit_snapshot(aud, data, "after_missing")
```

Each audit snapshot stores the full column names. Retrieve them by label
when you need to inspect or compare the data structure recorded in the
manifest.

``` r

raw_cols <- audit_cols(aud, "raw")
head(raw_cols)
```

------------------------------------------------------------------------

## Record Phenotype Summaries

After running `derive_*` functions,
[`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
can summarise phenotype columns that follow ukbflow’s standard naming
convention. It only needs the audit object, the data, and the phenotype
prefix.

``` r

data <- derive_selfreport(
  data,
  name  = "lung_cancer",
  regex = "lung cancer",
  field = "cancer"
)

data <- derive_icd10(
  data,
  name      = "lung",
  icd10     = "^C3[34]",
  match     = "regex",
  source    = "cancer_registry",
  behaviour = 3L
)

data <- derive_case(
  data,
  name                = "lung",
  selfreport_col      = "lung_cancer_selfreport",
  selfreport_date_col = "lung_cancer_selfreport_date"
)

data <- derive_timing(data, name = "lung", baseline_col = "p53_i0")

data <- derive_followup(
  data,
  name         = "lung",
  event_col    = "lung_date",
  baseline_col = "p53_i0",
  censor_date  = as.Date("2022-10-31"),
  death_col    = "p40000_i0",
  lost_col     = FALSE
)

aud <- audit_pheno(aud, data, "lung")
aud <- audit_snapshot(aud, data, "after_phenotype")
```

[`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
records whichever components exist: self-report, ICD-10, per-source
ICD-10 columns, combined status/date, timing, and follow-up. Missing
components are marked as not present rather than treated as errors.

------------------------------------------------------------------------

## Record Cohort Assembly

Audit snapshots work well for cohort exclusions because they record row
count, column count, missingness count, and column names at each stage.

``` r

aud <- audit_snapshot(aud, data, "before_exclusions")

data <- data[lung_timing != 1L | is.na(lung_timing)]
aud <- audit_snapshot(aud, data, "after_excluding_prevalent")

data[, smoking_ever := factor(
  ifelse(p20116_i0 == "Never", "Never", "Ever"),
  levels = c("Never", "Ever")
)]

data <- data[
  !is.na(smoking_ever) &
    !is.na(p31) &
    !is.na(p21022) &
    !is.na(p1558_i0) &
    !is.na(p54_i0)
]

aud <- audit_snapshot(aud, data, "analysis_ready")
```

For UKB withdrawal files, run
[`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
early in the pipeline and then record an audit snapshot.
[`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
itself records before/after snapshots in the session-level
[`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
history.

``` r

withdraw_file <- tempfile(fileext = ".csv")
writeLines(as.character(data$eid[1:3]), withdraw_file)

data <- ops_withdraw(data, file = withdraw_file)
aud <- audit_snapshot(aud, data, "after_withdraw")
```

------------------------------------------------------------------------

## Record Model Results

Association result tables are usually small and already contain the most
useful model summary.
[`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
stores the result table directly. If the covariate vector already exists
in your script, pass it along.

``` r

covars <- c(
  "p21022",
  "p31",
  "p1558_i0",
  "p54_i0"
)

res <- assoc_coxph(
  data         = data,
  outcome_col  = "lung_status",
  time_col     = "lung_followup_years",
  exposure_col = "smoking_ever",
  covariates   = covars
)

aud <- audit_model(
  aud,
  result     = res,
  label      = "smoking_lung_cox",
  covariates = covars
)
```

The model record stores the full result table, inferred method,
exposures, model labels, optional covariates, and a timestamp.

------------------------------------------------------------------------

## Review and Write the Manifest

Use [`summary()`](https://rdrr.io/r/base/summary.html) for a short
directory-style overview.

``` r

summary(aud)
```

Write the manifest as JSON alongside the analysis outputs.

``` r

audit_write(aud, "ukbflow-audit.json", overwrite = TRUE)
```

The resulting JSON contains the audit metadata, extraction field
records, snapshots, phenotype summaries, model result records, and
session information.

------------------------------------------------------------------------

## Suggested Audit Points

For most analyses, these are enough:

1.  [`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
    after loading ukbflow.
2.  [`audit_fields()`](https://evanbio.github.io/ukbflow/reference/audit_fields.md)
    next to the field vector used for extraction.
3.  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
    after loading raw data.
4.  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
    and
    [`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
    after phenotype derivation.
5.  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
    after each major cohort exclusion.
6.  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
    immediately before modelling.
7.  [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
    after each main association result.
8.  [`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
    next to long-running RAP jobs when a job ID is available.
9.  [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
    at the end of the script.

Keep the audit close to the real workflow. Do not duplicate logic just
for the manifest; record objects that already exist in the analysis.
