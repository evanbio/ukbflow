# NA

## Summary

## Type

Code (function / bug fix / docs)

Recipe (new or updated phenotype definition)

------------------------------------------------------------------------

### If this is a CODE PR

Added / updated tests

`devtools::document()` run (man/ and NAMESPACE in sync)

`devtools::check()` passes — 0 errors, 0 warnings

NEWS.md updated (if user-facing)

### If this is a RECIPE PR

See
[CONTRIBUTING_RECIPE.md](https://github.com/evanbio/ukbflow/blob/main/.github/CONTRIBUTING_RECIPE.md).

File named after its `id`, in `inst/extdata/recipes/`

Header complete (`version`, `created`, `updated`)

Only the eleven fixed source slots; unused slots are `[]`

Codes verified against the cited source; provenance in `notes`

Any non-executable source arms recorded in `notes`, not dropped

`recipe_get("<id>")` loads without error

`devtools::test(filter = "recipe")` passes
