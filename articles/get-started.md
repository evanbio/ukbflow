# Get Started with ukbflow

## Welcome to `ukbflow`

**`ukbflow`** is an R package for UK Biobank analysis on the [Research
Analysis Platform (RAP)](https://ukbiobank.dnanexus.com). It covers the
full midstream-to-downstream pipeline — from phenotype derivation and
association analysis to publication-ready figures and genetic risk
scoring — designed for RAP-native UKB workflows, with local simulated
data for development and testing.

## Installation

``` r
pak::pkg_install("evanbio/ukbflow")
```

## A Quick Taste

### Load data

``` r
library(ukbflow)

df <- ops_toy()   # synthetic UKB-like cohort, no RAP connection needed

# On RAP, replace with:
# auth_login()
# auth_select_project("project-XXXXXXXXXXXX")
# df <- extract_pheno(c(31, 21022, 53, 20116)) |>
#   decode_values() |>
#   decode_names()
```

### Derive a disease phenotype

``` r
df <- df |>
  derive_missing() |>                                               # recode "Prefer not to answer" → NA
  derive_selfreport(name = "t2dm", regex = "diabetes",           # T2DM self-report
                    field = "noncancer") |>
  derive_icd10(name = "t2dm", icd10 = "E11", source = "hes") |> # T2DM from HES
  derive_case(name = "t2dm") |>                                  # → t2dm_status, t2dm_date
  derive_followup(name         = "t2dm",
                  event_col    = "t2dm_date",
                  baseline_col = "p53_i0",                          # assessment centre date
                  censor_date  = as.Date("2022-06-01"))
```

### Run an association model

``` r
res <- assoc_coxph(
  data         = df,
  outcome_coll  = "t2dm_status",
  time_col     = "t2dm_followup_years",
  exposure_col = "p21001_i0",   # BMI (continuous)
  covariates   = c("p21022",    # age_at_recruitment
                   "p31")       # sex
)
```

### Plot the results

``` r
# Forest plot — see vignette("plot") for full usage
res_df <- as.data.frame(res)
plot_forest(
  data      = res_df,
  est       = res_df$HR,
  lower     = res_df$CI_lower,
  upper     = res_df$CI_upper,
  ci_column = 7L   # res_df has 6 cols before HR; CI graphic goes here
)

# Table 1
plot_tableone(
  data   = as.data.frame(df),
  vars   = c("p21022",     # age_at_recruitment
             "p31",        # sex
             "p21001_i0"), # bmi
  strata = "t2dm_status"
)
```

## Full Function Overview

| Module   | Key functions                                                                                                                                                                                                                                           | Vignette                                                                                       |
|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Auth     | [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md), [`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md)                                                                              | [`vignette("auth")`](https://evanbio.github.io/ukbflow/articles/auth.md)                       |
| Fetch    | [`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md), [`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md), [`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)                       | [`vignette("fetch")`](https://evanbio.github.io/ukbflow/articles/fetch.md)                     |
| Extract  | [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md), [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md), [`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)       | [`vignette("extract")`](https://evanbio.github.io/ukbflow/articles/extract.md)                 |
| Job      | [`job_wait()`](https://evanbio.github.io/ukbflow/reference/job_wait.md), [`job_status()`](https://evanbio.github.io/ukbflow/reference/job_status.md), [`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md)                       | [`vignette("job")`](https://evanbio.github.io/ukbflow/articles/job.md)                         |
| Decode   | [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md), [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)                                                                                      | [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md)                   |
| Derive   | [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md), [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md), [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)     | [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)                   |
| Survival | [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md), [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md), [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)   | [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md) |
| Assoc    | [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md), [`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md), [`assoc_subgroup()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md) | [`vignette("assoc")`](https://evanbio.github.io/ukbflow/articles/assoc.md)                     |
| Plot     | [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md), [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)                                                                                        | [`vignette("plot")`](https://evanbio.github.io/ukbflow/articles/plot.md)                       |
| GRS      | [`grs_check()`](https://evanbio.github.io/ukbflow/reference/grs_check.md), [`grs_score()`](https://evanbio.github.io/ukbflow/reference/grs_score.md), [`grs_validate()`](https://evanbio.github.io/ukbflow/reference/grs_validate.md)                   | [`vignette("grs")`](https://evanbio.github.io/ukbflow/articles/grs.md)                         |
| Ops      | [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md), [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md), [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)                       | [`vignette("ops")`](https://evanbio.github.io/ukbflow/articles/ops.md)                         |

## End-to-End Case Study

For a complete worked example using a simulated UK Biobank cohort —
covering data loading, phenotype derivation, cohort assembly, Cox
regression, and publication-ready visualisation — see:

[`vignette("smoking_lung_cancer")`](https://evanbio.github.io/ukbflow/articles/smoking_lung_cancer.md)
— **Smoking and Lung Cancer Risk: A Complete Analysis Workflow**

## Additional Resources

- [Documentation site](https://evanbio.github.io/ukbflow/)
- [GitHub](https://github.com/evanbio/ukbflow)
- View all functions:
  [`?ukbflow`](https://evanbio.github.io/ukbflow/reference/ukbflow-package.md)
  or
  [`help(package = "ukbflow")`](https://evanbio.github.io/ukbflow/reference)

> *“All models are wrong, but some are publishable.”*
>
> — after George Box
