# Build one source rule for a recipe

Constructs a single rule for one of a recipe's eleven source slots, for
use with
[`recipe_new`](https://evanbio.github.io/ukbflow/reference/recipe_new.md).
Rules within a slot combine by OR.

## Usage

``` r
recipe_rule(...)
```

## Arguments

- ...:

  Named rule fields, e.g. `icd10 = c("I21", "I22")`, `match = "prefix"`.

## Value

A `ukbflow_recipe_rule` object (a named list).

## Details

`recipe_rule` only captures the fields you give it; which fields are
legal depends on the slot the rule is assigned to, so validation happens
in
[`recipe_new`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
where that slot is known. The legal fields per slot are:

- `selfreport`:

  `field` (`"noncancer"`/`"cancer"`), `regex`

- `hes`, `hes_icd9`, `opcs`:

  `icd10`/`icd9`/`opcs`, `match`, `position`

- `gp_read2`, `gp_ctv3`:

  `read2`/`ctv3`, `match`

- `death`:

  `icd10`, `match`, `cause`

- `first_occurrence`, `algorithm`:

  `field`

- `cancer_registry`, `cancer_registry_icd9`:

  `subtype`, `icd10`/`icd9`, `histology`, `behaviour`

`match` is `"prefix"`/`"exact"`/`"regex"`, `position` is
`"any"`/`"main"`, and `cause` is `"any"`/`"primary"`/`"secondary"`.
Omitted modifiers fall back to the corresponding `derive_*` default
rather than being written out.

Fields that are scalar per rule – `regex` for `selfreport`, `field` for
`first_occurrence` and `algorithm` – expand into one rule per element
when given a vector, so a definition built from several First Occurrence
fields is still a single call.

## Examples

``` r
recipe_rule(icd10 = c("I21", "I22"), match = "prefix")
#> $icd10
#> [1] "I21" "I22"
#> 
#> $match
#> [1] "prefix"
#> 
#> attr(,"class")
#> [1] "ukbflow_recipe_rule" "list"               
recipe_rule(field = "noncancer", regex = c("^angina$", "^heart attack$"))
#> $field
#> [1] "noncancer"
#> 
#> $regex
#> [1] "^angina$"       "^heart attack$"
#> 
#> attr(,"class")
#> [1] "ukbflow_recipe_rule" "list"               
```
