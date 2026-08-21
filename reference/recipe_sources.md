# Flatten a recipe's source rules into a table

Reads one recipe and returns its source rules as a tidy `data.table`:
one row per rule, in canonical source order. This is the flattened,
diff-friendly view of a definition – suited to side-by-side comparison
of how different studies operationalised the same phenotype, and to
supplementary tables. For the full nested object use
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md);
for a one-line-per-recipe index use
[`recipe_list`](https://evanbio.github.io/ukbflow/reference/recipe_list.md).

## Usage

``` r
recipe_sources(id)
```

## Arguments

- id:

  (character) The recipe id, e.g. `"cscc"`. Validated and resolved
  exactly as in
  [`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md);
  an unknown or invalid recipe is an error.

## Value

A `data.table` with one row per rule and columns `source`, `rule` (index
within the source), `subtype`, `field`, `match`, `position` (HES
diagnosis position), `cause` (death-certificate cause position),
`regex`, `icd10`, `icd9`, `opcs`, `read2`, `ctv3`, `histology`
(list-column of integer vectors), and `behaviour`.

## Details

Rule fields are spread across fixed columns. `histology` is a
*list-column* carrying the full integer vector of codes verbatim (no
folding or counting), so the table loses nothing needed to reproduce the
definition. Unused fields are `NA`; empty sources contribute no rows.

## Examples

``` r
recipe_sources("cscc")
#> ✔ recipe_sources: 4 rules across 2 sources.
#>             source  rule  subtype  field  match position  cause
#>             <char> <int>   <char> <char> <char>   <char> <char>
#> 1:      selfreport     1     <NA> cancer   <NA>     <NA>   <NA>
#> 2: cancer_registry     1 invasive   <NA>   <NA>     <NA>   <NA>
#> 3: cancer_registry     2  in_situ   <NA>   <NA>     <NA>   <NA>
#> 4: cancer_registry     3  in_situ   <NA>   <NA>     <NA>   <NA>
#>                        regex  icd10   icd9   opcs  read2   ctv3
#>                       <char> <char> <char> <char> <char> <char>
#> 1: ^squamous cell carcinoma$   <NA>   <NA>   <NA>   <NA>   <NA>
#> 2:                      <NA>   ^C44   <NA>   <NA>   <NA>   <NA>
#> 3:                      <NA>   ^D04   <NA>   <NA>   <NA>   <NA>
#> 4:                      <NA>   ^C44   <NA>   <NA>   <NA>   <NA>
#>                                histology behaviour
#>                                   <list>     <num>
#> 1:                                    NA        NA
#> 2: 8051,8052,8070,8071,8072,8073,...[13]         3
#> 3:                                    NA        NA
#> 4: 8070,8071,8072,8073,8074,8075,...[13]         2
```
