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
- the versioned phenotype recipes a definition came from;
- association result tables returned by `assoc_*`;
- DNAnexus job IDs and lightweight job metadata when available;
- a JSON manifest that can be saved with the analysis outputs.

The audit object has a fixed structure from the moment it is created: a
`schema_version`, a `meta` block (analysis name, ukbflow and R versions,
platform, session information, and DNAnexus context), and the record
layers `fields`, `recipes`, `snapshots`, `phenotypes`, `models`, and
`jobs`. Each helper appends to one of these layers; the object is
validated against this schema before the manifest is written, so a
structurally broken audit fails loudly rather than producing a corrupt
file.

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

aud <- audit_start("smoking_lung_cancer", check_dx = FALSE)
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
`dx describe job-XXXX --json`, such as job name, state, creation time,
and failure message. It does not estimate RAP cost; use the DNAnexus /
RAP billing interface for cost review.

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
records whichever components exist: self-report, ICD-10, ICD-9,
algorithmically defined outcome, per-source columns (HES, HES ICD-9,
death registry, first occurrence, cancer registry, cancer registry
ICD-9), combined status/date, timing, and follow-up. Missing components
are marked as not present rather than treated as errors.

------------------------------------------------------------------------

## Record the Phenotype Definition

Where
[`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
summarises the *result* of a phenotype in your data,
[`audit_recipe()`](https://evanbio.github.io/ukbflow/reference/audit_recipe.md)
records the *definition* it came from. Pass a recipe id (see
[`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md));
the record captures the recipe id and version plus a self-contained
snapshot of the definition (sources, logic, and notes), stored in its
own `recipes` layer.

``` r

aud <- audit_recipe(aud, "cscc")
```

Keeping the definition separate from the realised summary means the
manifest can reproduce *how* a phenotype was specified — independent of
any dataset, and even if the bundled recipe library later changes.

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
stores the result table directly. When `result` comes straight from an
`assoc_*` call, the outcome column, time column, covariates, exposure
reference levels, and other call details are picked up automatically
from a hidden attribute that `assoc_*` attaches to its own return value
– nothing needs to be re-typed, and the result table itself is
unaffected (it prints and plots exactly as before).

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

aud <- audit_model(aud, result = res, label = "smoking_lung_cox")
```

The model record stores the full result table, the inferred method,
exposures (with reference levels), model labels, the outcome/time
columns and covariates picked up from `res`, and a timestamp. If
`result` does not carry this attribute (e.g. a hand-built data.frame),
the corresponding fields are recorded as `NA` or empty rather than
failing.

------------------------------------------------------------------------

## Compare Snapshots, Fields, or Models

[`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
walks an ordered sequence of labels within one layer and reports what
changed between each consecutive pair. It is read-only: it does not
append anything to `aud`.

``` r

audit_diff(aud, layer = "snapshots")
```

For `layer = "snapshots"` and `layer = "fields"`, each step reports the
added and removed columns (or field IDs). For `layer = "models"`, each
step reports covariate and exposure changes, plus a term-aligned
side-by-side of the most-adjusted model’s effect estimate and p-value –
useful for sensitivity analyses where the same exposure/outcome is
re-run with a different covariate set.

``` r

aud <- audit_model(aud, result = res_minimal, label = "smoking_lung_minimal")
aud <- audit_model(aud, result = res_full, label = "smoking_lung_full")
audit_diff(aud, layer = "models", label = c("smoking_lung_minimal", "smoking_lung_full"))
```

No delta is computed automatically between the two effect estimates:
HR/OR/SHR are ratio-scale and beta is difference-scale, so a single
formula would not suit both.

------------------------------------------------------------------------

## Export a Cohort Flowchart Table

[`audit_flowchart()`](https://evanbio.github.io/ukbflow/reference/audit_flowchart.md)
turns the `snapshots` layer into a data.frame in the shape a flowchart
renderer expects — five columns, `id`/`parent`/`n`/`label`/`type` —
without committing to any particular renderer. It only produces the
data; it does not render anything itself.

The same `id` on several rows is a **merge** (each row contributes one
upstream node); the same `parent` on several rows is a **branch**.
`label` stays plain text and the count stays in `n`, so the renderer
composes `"(n = 1,272)"` once, in whatever style the figure calls for.

``` r

audit_flowchart(aud)
```

By default each snapshot’s parent is the previous label in recording
order – a simple linear attrition chain – and a row count decrease
between parent and child is inserted as a sibling `type = "exclusion"`
row (even when the decrease is zero), matching the convention where an
exclusion box sits alongside the continuing step rather than replacing
it.

For a genuine branch (e.g. randomisation into two arms), declare the
second and later branches’ true parent with `parent`, since the default
assumption (“parent = previous label”) is wrong for anything but the
first branch:

``` r

aud <- audit_snapshot(aud, vaccine_arm_data, "vaccine_arm", verbose = FALSE)
aud <- audit_snapshot(aud, placebo_arm_data, "placebo_arm", verbose = FALSE)
audit_flowchart(aud, parent = c(placebo_arm = "randomized"))
```

A branch never gets an automatic exclusion row (a split is not an
exclusion), but its children’s counts are checked against the parent’s
and a warning is issued if they do not sum to it – likewise if a single
child’s count is somehow larger than its parent’s, since that is not a
valid exclusion either.

------------------------------------------------------------------------

## Review and Write the Manifest

Use [`summary()`](https://rdrr.io/r/base/summary.html) for a
directory-style overview of every layer (record counts plus a one-line
preview of each record’s content), or
[`print()`](https://rdrr.io/r/base/print.html) for a lighter skeleton
view (just the record counts).

``` r

summary(aud)
print(aud)
```

Write the manifest as JSON alongside the analysis outputs.

``` r

audit_write(aud, "ukbflow-audit.json", overwrite = TRUE)
```

The resulting JSON mirrors the audit schema: a `schema_version`, a
`meta` block, and the `fields`, `recipes`, `snapshots`, `phenotypes`,
`models`, and `jobs` record layers.
[`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
validates the object before serialising, so the manifest is either
complete and well-formed or not written at all.

------------------------------------------------------------------------

## Read Back a Saved Manifest

[`audit_read()`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
parses a manifest written by
[`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
back into a usable `ukbflow_audit` object – the same class
[`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
produces – so a past analysis’s audit trail can be inspected, or
compared, without re-running the analysis.

``` r

aud_reloaded <- audit_read("ukbflow-audit.json")
audit_cols(aud_reloaded, "raw")
```

Restoration is exact for the `fields`, `snapshots`, `models`, and `jobs`
layers and the `meta` block. The `recipes` and `phenotypes` layers are
passed through without this per-field restoration, since neither is
currently read by
[`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
or
[`audit_cols()`](https://evanbio.github.io/ukbflow/reference/audit_cols.md).

------------------------------------------------------------------------

## Compare Two Analyses

Passing a second audit object as `audit2` switches
[`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
into a different mode: instead of walking labels within one object, it
summarises `meta` and all six record layers for both objects side by
side. This does not attempt to match or diff individual records across
the two objects – there is no reliable way to tell which record in one
audit “corresponds to” which in the other – it only shows what each
object contains, reusing the same per-record summaries
[`summary()`](https://rdrr.io/r/base/summary.html) prints, so you can
eyeball the difference.

``` r

aud_paper <- audit_read("published_study_manifest.json")
audit_diff(aud, audit2 = aud_paper)
```

`audit2` must always be passed by name. Sides are labelled by each
object’s `meta$name` when both are present and distinct, falling back to
`"audit1"`/`"audit2"` otherwise. This is the natural way to check “what
does my reproduction of a published phenotype/model actually differ on”
against a manifest saved from an earlier analysis.

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
5.  [`audit_recipe()`](https://evanbio.github.io/ukbflow/reference/audit_recipe.md)
    for each recipe-based phenotype definition used.
6.  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
    after each major cohort exclusion.
7.  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
    immediately before modelling.
8.  [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
    after each main association result.
9.  [`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
    next to long-running RAP jobs when a job ID is available.
10. [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
    at the end of the script.
11. [`audit_read()`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
    and
    [`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
    when checking a saved manifest against the current analysis, or
    against a manifest from a previous run.

Keep the audit close to the real workflow. Do not duplicate logic just
for the manifest; record objects that already exist in the analysis.
