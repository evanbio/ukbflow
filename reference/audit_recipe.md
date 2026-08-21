# Record a phenotype recipe in an audit manifest

Stamps a versioned phenotype definition into the `recipes` layer of a
`ukbflow_audit` object. Unlike
[`audit_pheno`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md),
which summarises the *result* of applying a definition to a dataset,
this records the *definition itself*: which recipe (by `id`) and version
an analysis relied on, together with a self-contained snapshot of that
definition (sources, logic, and notes). The manifest can then reproduce
the phenotype specification even if the bundled recipe library later
changes.

## Usage

``` r
audit_recipe(audit, id, label = NULL)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- id:

  (character) The recipe id, e.g. `"cscc"`.

- label:

  (character or NULL) Optional label for this record. Default: `NULL`,
  which uses the recipe `id`.

## Value

The updated `ukbflow_audit` object.

## Details

The recipe is read with
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
so an unknown or structurally invalid `id` is an error.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
aud <- audit_recipe(aud, "cscc")
```
