# Common covariate presets for UK Biobank analysis

Returns ready-to-use covariate column-name sets for frequently used UK
Biobank adjustment models. This is a small offline reference catalogue:
each preset is a fixed, named combination of decoded column names that
can be passed straight to the `covariates` argument of the `assoc_*`
functions. It shows common conventions as a convenience; it is not a
recommendation, and which covariates to adjust for remains a
study-design decision the analyst must make.

## Usage

``` r
ops_covariates(id = NULL)
```

## Arguments

- id:

  (character or NULL) The preset id, e.g. `"age_sex_pcs"`. Default
  `NULL` returns the catalogue of available presets. An unknown id is an
  error that lists the valid ids.

## Value

With `id = NULL`, a `data.table` catalogue with columns `id`,
`description`, and `n_vars`. With `id` set, a character vector of
decoded covariate column names.

## Details

Column names are returned in their decoded (snake_case) form, matching
the output of
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
– the form used when fitting models, not the raw `pXXXX` field names.
Genetic principal components are fixed to the first ten (`_a1` to
`_a10`); if a different number is needed, request the individual columns
directly rather than through a preset.

## Examples

``` r
ops_covariates()
#>                    id                                    description n_vars
#>                <char>                                         <char>  <int>
#> 1:                age                             Age at recruitment      1
#> 2:                sex                                            Sex      1
#> 3:                pcs          First 10 genetic principal components     10
#> 4:            age_sex                                      Age + sex      2
#> 5:        age_sex_pcs                     Age + sex + 10 genetic PCs     12
#> 6:             center                   Assessment centre (baseline)      1
#> 7:     age_sex_center                  Age + sex + assessment centre      3
#> 8: age_sex_center_pcs Age + sex + assessment centre + 10 genetic PCs     13
ops_covariates("age_sex")
#> [1] "age_at_recruitment" "sex"               
ops_covariates("age_sex_pcs")
#>  [1] "age_at_recruitment"               "sex"                             
#>  [3] "genetic_principal_components_a1"  "genetic_principal_components_a2" 
#>  [5] "genetic_principal_components_a3"  "genetic_principal_components_a4" 
#>  [7] "genetic_principal_components_a5"  "genetic_principal_components_a6" 
#>  [9] "genetic_principal_components_a7"  "genetic_principal_components_a8" 
#> [11] "genetic_principal_components_a9"  "genetic_principal_components_a10"
```
