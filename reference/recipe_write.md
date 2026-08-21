# Write a recipe to a YAML file

Serialises a `ukbflow_recipe` object to a recipe YAML file. The output
carries the full eleven-slot schema with unused slots empty, so
generated files diff cleanly against one another.

## Usage

``` r
recipe_write(recipe, file, overwrite = FALSE)
```

## Arguments

- recipe:

  A `ukbflow_recipe` object, from
  [`recipe_new`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
  or
  [`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md).

- file:

  (character) Destination path, ending in `.yaml` or `.yml`. By
  convention the file is named after the recipe's `id`.

- overwrite:

  (logical) Overwrite `file` if it already exists? Default `FALSE`.

## Value

The path, invisibly.

## Details

Generated files carry no comments. Everything a reader needs –
provenance, code-format quirks, arms that are documented but not
executable – belongs in `notes`, which is part of the definition: it is
validated, returned by
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
shown by `print`, and read by the recipe catalogue. A YAML comment is
none of those things.

An existing file is never overwritten unless `overwrite = TRUE`. The
bundled library was written by hand and its inline commentary would be
lost on rewrite.

## Examples

``` r
rec <- recipe_new(
  id     = "atopic_dermatitis_demo",
  label  = "Atopic dermatitis",
  sources = list(first_occurrence = 131720),
  notes  = "Provenance: worked example, not a published definition."
)
#> ✔ recipe_new: "atopic_dermatitis_demo" - 1 rule across 1 source.
path <- file.path(tempdir(), "atopic_dermatitis_demo.yaml")
recipe_write(rec, path)
#> ✔ recipe_write: "atopic_dermatitis_demo" -> /tmp/RtmpLXmOSW/atopic_dermatitis_demo.yaml.
cat(readLines(path), sep = "\n")
#> id: atopic_dermatitis_demo
#> label: Atopic dermatitis
#> version: 1
#> created: '2026-08-21'
#> updated: '2026-08-21'
#> sources:
#>   selfreport: []
#>   hes: []
#>   hes_icd9: []
#>   opcs: []
#>   gp_read2: []
#>   gp_ctv3: []
#>   death: []
#>   first_occurrence:
#>   - field: 131720
#>   cancer_registry: []
#>   cancer_registry_icd9: []
#>   algorithm: []
#> logic:
#>   case: any
#>   date: earliest
#> notes:
#> - 'Provenance: worked example, not a published definition.'
```
