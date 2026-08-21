# Build a phenotype recipe

Assembles a phenotype definition into a validated `ukbflow_recipe`
object, the same shape
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
returns. This is the programmatic alternative to writing a recipe YAML
file by hand: it removes YAML syntax from the task, checks the
definition against the schema, and fails with a pointed message rather
than producing a file that only breaks later. Pair it with
[`recipe_write`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)
to save the result.

## Usage

``` r
recipe_new(
  id,
  label,
  sources = list(),
  short_label = NULL,
  version = 1L,
  created = Sys.Date(),
  updated = created,
  description = NULL,
  logic = list(),
  notes = NULL
)
```

## Arguments

- id:

  (character) Recipe id; globally unique, and the key
  [`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
  matches on. Identifies one *definition*.

- label:

  (character) Human-readable phenotype name. Two recipes that
  operationalise the same phenotype differently share a `label` and are
  told apart by `id`.

- sources:

  (list) Named list of source slots; see Details. Slot names must come
  from the eleven documented in
  [`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md).

- short_label:

  (character) Optional short name for the phenotype.

- version:

  (numeric) Whole number; bump on every change. Default `1`.

- created, updated:

  (Date or "YYYY-MM-DD") Authoring dates. Default is today, with
  `updated` following `created`.

- description:

  (character) Optional free-text summary of the definition.

- logic:

  (list) Optional `list(case=, date=)`; `case` is `"any"`/`"all"` and
  `date` is `"earliest"`/`"latest"`. Defaults to `case = "any"`,
  `date = "earliest"`.

- notes:

  (character) Caveats, one per element. Provenance and any part of the
  definition `derive_*` cannot execute belong here – notes are the only
  channel the recipe object, `print`, and the catalogue can see.

## Value

A `ukbflow_recipe` object, identical in shape to
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)'s.

## Details

`recipe_new` builds and validates a definition; it does not add it to
the bundled library and does not decide whether a definition is
appropriate for a study. A contributed recipe is reviewed before it
becomes part of the library – see the contributing guide.

Each element of `sources` may be given as:

- a bare vector – shorthand for the slot's code field, e.g.
  `hes = c("I21", "I22")` (not available for `selfreport`, whose rule
  also needs `field`);

- a single
  [`recipe_rule`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md),
  when modifiers such as `match` or `cause` are needed;

- a list of
  [`recipe_rule`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md)s,
  for a slot whose rules differ from one another – the cancer-registry
  histology/behaviour branches are the usual case.

Omitted slots are recorded as unused. Rule fields that are absent are
left out rather than written as nulls: an empty histology filter and an
absent one mean the same thing to `derive_*`.

## Examples

``` r
recipe_new(
  id     = "myocardial_infarction_demo",
  label  = "Myocardial infarction",
  sources = list(
    hes   = recipe_rule(icd10 = c("I21", "I22"), match = "prefix"),
    death = recipe_rule(icd10 = c("I21", "I22"), match = "prefix",
                        cause = "primary")
  ),
  notes = "Provenance: worked example, not a published definition."
)
#> ✔ recipe_new: "myocardial_infarction_demo" - 2 rules across 2 sources.
#> 
#> ── Recipe: Myocardial infarction ───────────────────────────────────────────────
#> id: myocardial_infarction_demo | version 1 | updated 2026-08-21
#> 
#> Sources
#>   • hes  icd10="I21,I22"  match="prefix"
#>   • death  icd10="I21,I22"  match="prefix"  cause="primary"
#> 
#> Logic case=any | date=earliest
#> 
#> Notes
#>   1. Provenance: worked example, not a published definition.
```
