# Export a cohort flowchart table from recorded snapshots

Builds a data.frame from the `snapshots` layer in the shape a flowchart
renderer expects. `audit_flowchart()` only produces the data; it does
not render anything itself.

## Usage

``` r
audit_flowchart(audit, label = NULL, parent = NULL)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- label:

  (character or NULL) Ordered snapshot labels to include. Default:
  `NULL`, which uses every label recorded in `audit$snapshots`, in the
  order it was captured.

- parent:

  (named character or NULL) Overrides for the default "parent = previous
  label" assumption, as `c(child_label = parent_label)`. Only needed for
  labels whose true parent is not the immediately preceding label in
  `label` – typically the second and later branches at a split point.
  Default: `NULL`.

## Value

Invisibly, a data.frame with columns `id`, `parent`, `n`, `label`,
`type`.

## Details

The returned table has five columns, which together describe the diagram
without committing to any particular renderer:

- id:

  Node key. The same `id` on several rows means a *merge*: each row
  contributes one upstream node.

- parent:

  The upstream node's `id`; `NA` marks a root. The same `parent` on
  several rows means a *branch*.

- n:

  Row count for that node.

- label:

  Box text. Plain text only – the count is kept in `n` and formatted by
  the renderer, so that `"(n = 1,272)"` appears exactly once and in
  whatever style the figure calls for.

- type:

  `"step"` or `"exclusion"`.

By default, each snapshot's parent is the previous label in `label` (or
the recording order of `audit$snapshots` when `label` is `NULL`) – a
simple linear attrition chain. Use `parent` to declare branch points
(e.g. randomisation into two arms), overriding this default for any
label whose true parent is not the immediately preceding one.

For a label with exactly one child, the row count difference between
parent and child is inserted as a sibling `type = "exclusion"` row (even
when the difference is zero) immediately before the child's own row. The
exclusion is a *sibling* of the continuing step, not its parent, which
is what lets a renderer place the exclusion box beside the trunk rather
than in it. A child count larger than its parent's is not a valid
exclusion and produces a warning instead of an exclusion row.

For a label with two or more children (a genuine branch/split, e.g.
randomisation), no exclusion row is inserted for any of them – a branch
is not an exclusion. If the children's counts do not sum to the parent's
count, a warning is issued, since that usually indicates a real
inconsistency in what was recorded.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
aud <- audit_snapshot(aud, data.frame(eid = 1:1000), "raw", verbose = FALSE)
aud <- audit_snapshot(aud, data.frame(eid = 1:820), "after_exclusions", verbose = FALSE)
audit_flowchart(aud)
#> raw: 1000
#> after_exclusions: 820 (excluded 180)
```
