# Compare recorded audit entries along a chosen sequence, or two audit objects as a whole

Has two mutually exclusive modes, chosen by whether `audit2` is given.

## Usage

``` r
audit_diff(
  audit,
  layer = c("snapshots", "fields", "models"),
  label = NULL,
  audit2 = NULL
)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- layer:

  (character) Single-object mode only. Which audit layer to compare
  across labels: `"snapshots"`, `"fields"`, or `"models"`.

- label:

  (character or NULL) Single-object mode only. An ordered vector of
  labels to walk, e.g. `c("raw", "after_exclusion", "analysis_ready")`.
  Default: `NULL`, which uses every label recorded for `layer`, in the
  order it was captured.

- audit2:

  (`ukbflow_audit` or `NULL`) A second audit object to compare `audit`
  against as a whole. Default: `NULL`, which uses single-object mode.
  When given, `layer` and `label` are ignored. Always pass this by name
  (`audit2 = ...`); it is not in the second positional slot so that
  existing positional calls to `layer` keep working.

## Value

Invisibly, a list. In single-object mode, one element per consecutive
pair in `label`. For `layer = "snapshots"` and `layer = "fields"`, each
element has `from`, `to`, `added`, and `removed` (plus `n_from`, `n_to`,
`n_delta` for snapshots). For `layer = "models"`, each element has
`covariates_added` / `covariates_removed`; `exposures_from` /
`exposures_to`, `outcome_from` / `outcome_to`, `method_from` /
`method_to`; and `effects` – a data.frame comparing the `term`-level
effect estimate and p-value of the most-adjusted model available
(preferring `"Fully adjusted"`) in `from` versus `to`, with no derived
delta computed since HR/OR/SHR are ratio-scale and beta is
difference-scale. In two-object mode, a list with `labels`, a `meta`
list of paired values, and a `layers` list (one element per record
layer, each with `n` and `lines`).

## Details

**Single-object mode** (`audit2 = NULL`, the default): walks an ordered
sequence of labels within one audit layer and reports what changed
between each consecutive pair. This is a read-only view over records
already captured by functions such as
[`audit_snapshot`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
and
[`audit_fields`](https://evanbio.github.io/ukbflow/reference/audit_fields.md).

**Two-object mode** (`audit2` given): `layer` and `label` are ignored,
and instead every layer – `meta` plus all six record layers – is
summarised for `audit` and `audit2` side by side, reusing the exact same
per-record one-line summaries that
[`summary.ukbflow_audit`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
prints. This does not attempt to match or diff individual records across
the two objects (there is no reliable way to tell which record in one
audit "corresponds to" which in the other); it only shows what each
object contains, so you can eyeball the difference. Sides are labelled
by each object's `meta$name` when both are present and distinct, falling
back to `"audit1"`/`"audit2"` otherwise.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
aud <- audit_snapshot(aud, data.frame(eid = 1:5, x = 1:5), "raw", verbose = FALSE)
aud <- audit_snapshot(
  aud,
  data.frame(eid = 1:3, x = 1:3, y = 1:3),
  "analysis_ready",
  verbose = FALSE
)
audit_diff(aud, "snapshots")
#> raw -> analysis_ready: n 5 -> 3 (-2)
#> added (1): "y"
#> removed (0):

aud <- audit_fields(aud, c(31, 53), label = "core_fields")
aud <- audit_fields(aud, c(31, 41270, 41280), label = "hes_fields")
audit_diff(aud, "fields")
#> core_fields -> hes_fields:
#> added (2): 41270 and 41280
#> removed (1): 53

aud2 <- audit_start("other_analysis", check_dx = FALSE)
aud2 <- audit_fields(aud2, c(31, 53), label = "core_fields")
audit_diff(aud, audit2 = aud2)
#> meta:
#> name: example_analysis "example_analysis" other_analysis "other_analysis"
#> start_time: example_analysis "2026-08-21T07:32:30+0000" other_analysis
#> "2026-08-21T07:32:30+0000"
#> ukbflow_version: example_analysis "0.4.0" other_analysis "0.4.0"
#> dx_user: example_analysis "NA" other_analysis "NA"
#> dx_project: example_analysis "NA" other_analysis "NA"
#> 
#> fields (example_analysis: 2, other_analysis: 1):
#> example_analysis:
#> - core_fields: 2 fields (no dataset): 31, 53
#> - hes_fields: 3 fields (no dataset): 31, 41270, 41280
#> other_analysis:
#> - core_fields: 2 fields (no dataset): 31, 53
#> 
#> recipes (example_analysis: 0, other_analysis: 0):
#> example_analysis:
#> (none)
#> other_analysis:
#> (none)
#> 
#> snapshots (example_analysis: 2, other_analysis: 0):
#> example_analysis:
#> - raw: 5 rows x 2 cols: eid, x
#> - analysis_ready: 3 rows x 3 cols: eid, x, y
#> other_analysis:
#> (none)
#> 
#> phenotypes (example_analysis: 0, other_analysis: 0):
#> example_analysis:
#> (none)
#> other_analysis:
#> (none)
#> 
#> models (example_analysis: 0, other_analysis: 0):
#> example_analysis:
#> (none)
#> other_analysis:
#> (none)
#> 
#> jobs (example_analysis: 0, other_analysis: 0):
#> example_analysis:
#> (none)
#> other_analysis:
#> (none)
```
