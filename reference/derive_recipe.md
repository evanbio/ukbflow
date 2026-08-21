# Apply a phenotype recipe to UKB data

Executes a
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
definition against `data`: each source rule is dispatched to the
matching `derive_*` function
([`derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md),
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
[`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md),
[`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md),
[`derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md),
[`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md),
[`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md),
[`derive_algorithm`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md)),
and the results are combined per the recipe's `logic` (`case`:
`"any"`/`"all"`; `date`: `"earliest"`/`"latest"`). Where
[`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
only reads and normalises a definition, `derive_recipe()` is the
executable counterpart that turns it into analysis-ready columns – the
automated form of the manual translation shown in
[`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md).

## Usage

``` r
derive_recipe(data, id, name = id, gp = NULL)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- id:

  (character) The recipe id, e.g. `"cscc"`. Passed to
  [`recipe_get`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
  which aborts on an unknown or invalid id.

- name:

  (character) Output column prefix. Default: `id`. Using the recipe id
  by default keeps two recipes for the same phenotype (e.g. `dementia`
  and `dementia_algorithmic`, which share a `label`) from colliding on
  column names when both are run against the same data.

- gp:

  (data.frame/data.table or NULL) The `gp_clinical` long table, required
  only when the recipe has primary-care rules (`gp_read2` / `gp_ctv3`
  slots); passed through to
  [`derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
  /
  [`derive_gp_ctv3`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md).
  Default `NULL`; a recipe with GP rules errors early if it is absent.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_status` (logical) and `{name}_date` (IDate). Always returns a
`data.table`.

## Details

**Rules within one source combine by OR.** A source holds a list of
rules, and several slots use more than one: `cancer_registry` for
histology/behaviour branches (`cscc`'s invasive/in-situ split),
`first_occurrence` for the several `p131xxx` date fields that make up
one phenotype, and `selfreport` for a set of alternative reported terms.
Each rule is run under a private temporary name, OR-combined (status) /
earliest-combined (date), and the per-rule intermediate columns are
removed once the combination is taken – they never appear in the
temporary column set added to `data`.

**Only two columns persist**, regardless of how many sources or rules
the recipe uses: `{name}_status` (logical) and `{name}_date` (`IDate`).
Every source-level and rule-level intermediate result is reported via
`cli` (through the underlying `derive_*` calls, plus a combined line per
multi-rule source) and then discarded – nothing extra is left in `data`.
This keeps a recipe's column footprint constant however many sources it
draws on, and matches the naming
[`derive_age`](https://evanbio.github.io/ukbflow/reference/derive_age.md),
[`derive_timing`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
and
[`derive_followup`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
already auto-detect (`{name}_status` / `{name}_date`), so the output
plugs directly into the rest of the `derive_*` pipeline.

**Column auto-detection only**: a recipe rule never records a source
column name, only its semantic definition (`field`, `regex`, `icd10`,
`icd9`, `opcs`, `read2`, `ctv3`, `histology`, `behaviour`). Every
dispatched `derive_*` call therefore relies on that function's own
auto-detection, which matches the raw UKB column names (`p41270`,
`participant.p41270`) directly and only falls back to the
[`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
field dictionary for data that has been through
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md).
There is no override mechanism.

If a required source column is missing from `data` (e.g. it was never
extracted), the underlying `derive_*` call **aborts**, exactly as it
would if called directly – it does not fall back to a status of `FALSE`,
which downstream would be indistinguishable from a genuine "not a case".
A source whose column is present but matches no codes is a different
situation: that warns and contributes zero cases.

**data.table pass-by-reference**: when the input is a `data.table`, the
two output columns are added in-place. Pass `data.table::copy(data)` to
preserve the original.

## Examples

``` r
dt <- ops_toy(n = 200)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 42
derive_recipe(dt, id = "psoriasis")
#> ! derive_selfreport (psoriasis): 0 cases found.
#> ✔ derive_first_occurrence (psoriasis): 14 cases with valid date.
#> ✔ derive_recipe (psoriasis): 14 cases, 14 with date [2 sources; logic: case=any, date=earliest]

# A recipe with multiple sources and multiple cancer_registry rules
dt2 <- ops_toy(n = 200)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 42
derive_recipe(dt2, id = "cscc")
#> ! derive_selfreport (cscc): 0 cases found.
#> ℹ   cancer_registry: 3 rules
#> ! derive_cancer_registry (cscc_cancer_registry_r1): 0 cases after filtering.
#> ! derive_cancer_registry (cscc_cancer_registry_r2): 0 cases after filtering.
#> ! derive_cancer_registry (cscc_cancer_registry_r3): 0 cases after filtering.
#> ℹ     -> cancer_registry combined: 0 cases, 0 with date
#> ✔ derive_recipe (cscc): 0 cases, 0 with date [2 sources; logic: case=any, date=earliest]

# A recipe with primary-care rules needs the gp_clinical long table.
# Match n and seed so the cohort and GP table share their eids.
dt3 <- ops_toy(n = 200, seed = 1)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 1
gp  <- ops_toy(scenario = "gp", n = 200, seed = 1)
#> ✔ ops_toy: 83 linked participants | 952 records | 5 columns | scenario = "gp" | seed = 1
derive_recipe(dt3, id = "dementia", gp = gp)
#> ✔ derive_hes (dementia): 19 cases, 19 with date.
#> ✔ derive_hes_icd9 (dementia): 7 cases, 7 with date.
#> ✔ derive_gp_read2 (dementia): 1 case, 1 with date.
#> ✔ derive_gp_ctv3 (dementia): 6 cases, 6 with date.
#> ✔ derive_recipe (dementia): 33 cases, 33 with date [4 sources; logic: case=any, date=earliest]
```
