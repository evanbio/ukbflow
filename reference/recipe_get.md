# Retrieve a single phenotype recipe

Reads one recipe from the bundled library and returns its full,
normalised definition as a `ukbflow_recipe` object. Unlike
[`recipe_list`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
(which skips unreadable files), `recipe_get` fails hard when the
requested `id` does not exist or the recipe is structurally invalid,
because a broken definition cannot be reproduced.

## Usage

``` r
recipe_get(id)

# S3 method for class 'ukbflow_recipe'
print(x, ...)
```

## Arguments

- id:

  (character) The recipe id, e.g. `"atopic_dermatitis"`. Matched against
  the recipe's `id` field, not its file name.

- x:

  A `ukbflow_recipe` object.

- ...:

  Ignored.

## Value

A `ukbflow_recipe` object: a normalised list with elements `id`,
`label`, `short_label`, `version`, `created`, `updated`, `description`,
`sources`, `logic`, and `notes`.

## Details

The returned object has a fixed shape: all eleven source slots are
always present (`selfreport`, `hes`, `hes_icd9`, `opcs`, `gp_read2`,
`gp_ctv3`, `death`, `first_occurrence`, `cancer_registry`,
`cancer_registry_icd9`, `algorithm`), each a list of rules (empty when
unused); `logic` is filled with the documented defaults (`case = "any"`,
`date = "earliest"`) when absent; and `notes` is always a character
vector.

## Examples

``` r
recipe_get("atopic_dermatitis")
#> 
#> ── Recipe: Atopic dermatitis (AD) ──────────────────────────────────────────────
#> id: atopic_dermatitis | version 2 | updated 2026-07-13
#> A UK Biobank operational phenotype definition for atopic dermatitis, based on
#> self-report and the ICD-10 L20 First Occurrence field.
#> 
#> Sources
#>   • selfreport  field="noncancer"  regex="^eczema/dermatitis$"
#>   • first_occurrence  field=131720
#> 
#> Logic case=any | date=earliest
#> 
#> Notes
#>   1. UKB self-report (p20002) only codes 'eczema/dermatitis'; UKB has no distinct 'atopic dermatitis', 'atopic eczema', or 'infantile/childhood/flexural eczema' term.
#>   2. 'Contact dermatitis' is excluded — not an atopic disease.
#>   3. ICD-10 ascertainment uses the pre-computed First Occurrence field (L20, p131720), not raw HES or death-registry records.
```
