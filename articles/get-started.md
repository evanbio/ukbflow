# Get Started with ukbflow

## Welcome to `ukbflow`

**`ukbflow`** is an R package for UK Biobank analysis on the [Research
Analysis Platform (RAP)](https://ukbiobank.dnanexus.com). It covers the
full midstream-to-downstream pipeline — from phenotype derivation and
association analysis to publication-ready figures and genetic risk
scoring — entirely within the RAP cloud environment.

## Installation

``` r
pak::pkg_install("evanbio/ukbflow")
```

## A Quick Taste

### Authenticate and extract data

``` r
library(ukbflow)

auth_login()
auth_select_project("project-XXXXXXXXXXXX")

df <- extract_pheno(c(31, 21022, 53, 20116)) |>
  decode_values() |>
  decode_names()
```

### Derive a disease phenotype

``` r
df <- df |>
  derive_missing() |>
  derive_selfreport(name = "outcome", regex = "diabetes", field = "non_cancer") |>
  derive_icd10(name = "outcome", icd10 = "E11", source = "hes") |>
  derive_case(name = "outcome") |>                 # → outcome_status, outcome_date
  derive_followup(name         = "outcome",
                  event_col    = "outcome_date",
                  baseline_col = "p53_i0",         # date_of_attending_assessment_centre_i0
                  censor_date  = as.Date("2022-06-01"))
```

### Run an association model

``` r
res <- assoc_coxph(
  data         = df,
  outcome_col  = "outcome_status",
  time_col     = "outcome_followup_years",
  exposure_col = "exposure_status",
  covariates   = c("age_at_recruitment", "sex", "smoking_status_i0")
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
  ci_column = 2L
)

# Table 1
plot_tableone(
  data   = df,
  vars   = c("age_at_recruitment", "sex", "smoking_status_i0"),
  strata = "outcome_status"
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
