# Smoking and Lung Cancer Risk: A Complete Analysis Workflow

## 1 Introduction

Cigarette smoking is the leading preventable cause of lung cancer,
accounting for approximately 85% of all cases and conferring a 15–30
times higher risk compared with never-smokers. Risk scales with
cumulative exposure and decreases — but never fully reverts — after
cessation. Sex, age, and socioeconomic deprivation are well-established
modifiers of this association in large prospective cohorts such as the
UK Biobank. This vignette uses a simulated UK Biobank-style dataset to
walk through the complete ukbflow pipeline for this canonical exposure–
outcome pair.

## 2 Data Loading

We use the package built-in function
[`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md) to
simulate and generate a synthetic UK Biobank-style dataset for this
analysis.

``` r
library(ukbflow)

data <- ops_toy(n = 500000, seed = 2026)
#> ✔ ops_toy: 500000 participants | 75 columns | scenario = "cohort" | seed = 2026
```

## 3 Decode Column Names

In a real RAP session,
[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
translates UKB field IDs into human-readable snake_case column names
(e.g. `p31` → `sex`, `p21022` → `age_at_recruitment`).

``` r
data <- decode_names(data)
#> Field dictionary not cached - calling `extract_ls()` to populate it.
#> Using dataset: "XXXXXXXXXXXXXXXXXXXXXXX"
#> Fetching approved fields... (cached after first call)
#> 29951 fields available. Assign to a variable or use pattern= to search.
#> ✔ Renamed 68 columns.
#> ! 5 column names longer than 60 characters - consider renaming manually:
#> • interpolated_year_when_non_cancer_illness_first_diagnosed_i0_a0
#> • interpolated_year_when_non_cancer_illness_first_diagnosed_i0_a1
#> • interpolated_year_when_non_cancer_illness_first_diagnosed_i0_a2
#> • interpolated_year_when_non_cancer_illness_first_diagnosed_i0_a3
#> • interpolated_year_when_non_cancer_illness_first_diagnosed_i0_a4
```

## 4 Derive Phenotypes

We first handle non-informative missing codes (e.g. “Do not know”,
“Prefer not to answer”) with
[`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md).

``` r
data <- derive_missing(data)
#> ✔ derive_missing: replaced 279650 values across 3 columns (action = "na").
```

Next, convert categorical columns to factors with
[`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md).

``` r
data <- derive_covariate(
  data,
  as_factor = c(
    "p31",        # sex
    "p20116_i0",  # smoking_status_i0
    "p1558_i0",   # alcohol_intake_frequency_i0
    "p54_i0"      # uk_biobank_assessment_centre_i0
  )
)
#> ── Factor ───────────────────────────────────────────────────────────────────
#> sex [2 levels]
#>   Female: n=270191 (54%)  |  Male: n=229809 (46%)  |  <NA>: n=0 (0%)
#> smoking_status_i0 [3 levels]
#>   Current: n=69867 (14%)  |  Never: n=260458 (52.1%)  |  Previous: n=154871 (31%)  |  <NA>: n=14804 (3%)
#> ! alcohol_intake_frequency_i0: 6 levels > max_levels (5), consider collapsing categories.
#>   Daily or almost daily: n=40113 (8%)  |  Never: n=45207 (9%)  |  ...  |  <NA>: n=14973 (3%)
#> ! uk_biobank_assessment_centre_i0: 10 levels > max_levels (5), consider collapsing categories.
#>   Birmingham: n=49709 (9.9%)  |  Bristol: n=49832 (10%)  |  ...  |  Sheffield: n=50293 (10.1%)
```

We then bin BMI and Townsend Deprivation Index (TDI) into categories
using
[`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md).

``` r
data <- derive_cut(
  data,
  col    = "p21001_i0",                              # body_mass_index_bmi_i0
  n      = 4,
  breaks = c(18.5, 25, 30),
  labels = c("Underweight", "Normal", "Overweight", "Obese"),
  name   = "bmi_cat"
)
#> ── Source: body_mass_index_bmi_i0 ───────────────────────────────────────────
#>   mean=26.21, median=26.19, sd=5.48, Q1=22.48, Q3=29.9, NA=0% (n=0)
#> ── New column: bmi_cat ──────────────────────────────────────────────────────
#> bmi_cat [4 levels]
#>   Underweight: n=40238 (8%)  |  Normal: n=166710 (33.3%)
#>   Overweight:  n=170794 (34.2%)  |  Obese: n=122258 (24.5%)  |  <NA>: n=0 (0%)

data <- derive_cut(
  data,
  col    = "p22189",                                 # townsend_deprivation_index_at_recruitment
  n      = 4,
  labels = c("Q1 (least deprived)", "Q2", "Q3", "Q4 (most deprived)"),
  name   = "tdi_cat"
)
#> ── Source: townsend_deprivation_index_at_recruitment ────────────────────────
#>   mean=-1.25, median=-1.3, sd=3.1, Q1=-3.46, Q3=0.86, NA=0% (n=0)
#> ── New column: tdi_cat ──────────────────────────────────────────────────────
#> tdi_cat [4 levels]
#>   Q1 (least deprived): n=125290 (25.1%)  |  Q2: n=124831 (25%)
#>   Q3: n=125102 (25%)  |  Q4 (most deprived): n=124777 (25%)  |  <NA>: n=0 (0%)
```

Self-reported lung cancer (field 20001) is derived with
[`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md),
which searches the cancer self-report columns for a matching label.

``` r
data <- derive_selfreport(
  data,
  name  = "lung_cancer",
  regex = "lung cancer",
  field = "cancer"
)
#> ✔ derive_selfreport (lung_cancer): 6700 cases, 6700 with dates.
```

ICD-10 diagnoses in the UK Biobank can be ascertained from four sources:
First Occurrence fields, HES inpatient records, death registry, and
cancer registry. For malignant neoplasms such as lung cancer, the cancer
registry provides the most complete and accurate ascertainment and is
therefore our primary source.

``` r
data <- derive_icd10(
  data,
  name      = "lung",
  icd10     = "^C3[34]",
  match     = "regex",
  source    = "cancer_registry",
  behaviour = 3L
)
#> ✔ derive_cancer_registry (lung): 2449 cases, 2449 with date.
#> ✔ derive_icd10 (lung): 2449 cases across 1 source, 2449 with date.
```

[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
merges the self-report and ICD-10 flags into a single case status and
earliest date using an OR rule across sources.

``` r
data <- derive_case(
  data,
  name                = "lung",
  selfreport_col      = "lung_cancer_selfreport",
  selfreport_date_col = "lung_cancer_selfreport_date"
)
#> ✔ derive_case (lung): 9110 cases, 9110 with date.
#> ℹ   Both sources (lung_icd10 & lung_cancer_selfreport): 39
```

Finally,
[`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
classifies each case as prevalent (disease before baseline) or incident
(disease after baseline), which determines eligibility for the survival
analysis.

``` r
data <- derive_timing(data, name = "lung", baseline_col = "p53_i0")  # date_of_attending_assessment_centre_i0
#> ✔ derive_timing (lung_timing):
#> ℹ   0 (no disease): 490890
#> ℹ   1 (prevalent):  5056
#> ℹ   2 (incident):   4054
#> ℹ   NA (no date):   0
```

[`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
computes follow-up end date and time in years for each participant,
taking the earliest of the event date, death date, and the
administrative censoring date.

``` r
data <- derive_followup(
  data,
  name         = "lung",
  event_col    = "lung_date",
  baseline_col = "p53_i0",         # date_of_attending_assessment_centre_i0
  censor_date  = as.Date("2022-10-31"),
  death_col    = "p40000_i0",      # date_of_death_i0
  lost_col     = FALSE             # lost-to-follow-up not available in this dataset
)
#> ✔ derive_followup (lung):
#> ℹ   lung_followup_end: 500000 / 500000 non-missing
#> ℹ   lung_followup_years: mean=13.71, median=14.09, range=[0, 16.83]
```

## 5 Exposure Definition

Smoking status has three levels (Never, Previous, Current). For a
cleaner binary contrast, we collapse Previous and Current into a single
“Ever” category, with “Never” as the reference level.

``` r
data[, smoking_ever := factor(
  ifelse(p20116_i0 == "Never", "Never", "Ever"),
  levels = c("Never", "Ever")   # Never = reference
)]
```

## 6 Cohort Assembly

We exclude prevalent lung cancer cases and participants with missing
exposure or follow-up time to arrive at the final analysis cohort.
[`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
is a handy utility for recording cohort size at each step — the snapshot
history can directly inform the flow diagram in your methods section.

``` r
ops_snapshot(data, label = "raw")
#> ── snapshot: raw ────────────────────────────────────────────────────────────
#>   rows      500,000
#>   cols           89
#>   NA cols        59
#>   size       293 MB
```

Exclude participants with prevalent lung cancer (diagnosed at or before
baseline) — they are not eligible for the incident analysis.

``` r
data <- data[lung_timing != 1 | is.na(lung_timing)]
ops_snapshot(data, label = "after excluding prevalent cases")
#> ── snapshot: after excluding prevalent cases ─────────────────────────────────
#>   rows      494,944  (-5,056)
#>   cols           89  (= 0)
#>   NA cols        58  (-1)
#>   size       290.1 MB  (-2.95 MB)
```

Exclude participants with missing values in the exposure or any
covariate.

``` r
data <- data[!is.na(smoking_ever)  &
             !is.na(p31)           &   # sex
             !is.na(p21022)        &   # age_at_recruitment
             !is.na(bmi_cat)       &   # bmi category
             !is.na(p1558_i0)      &   # alcohol_intake_frequency_i0
             !is.na(tdi_cat)       &   # townsend deprivation category
             !is.na(p54_i0)        &   # assessment_centre
             !is.na(p22009_a1)     &   # PC1
             !is.na(p22009_a2)     &   # PC2
             !is.na(p22009_a3)     &   # PC3
             !is.na(p22009_a4)     &   # PC4
             !is.na(p22009_a5)     &   # PC5
             !is.na(p22009_a6)     &   # PC6
             !is.na(p22009_a7)     &   # PC7
             !is.na(p22009_a8)     &   # PC8
             !is.na(p22009_a9)     &   # PC9
             !is.na(p22009_a10)]       # PC10
ops_snapshot(data, label = "after excluding missing covariates")
#> ── snapshot: after excluding missing covariates ──────────────────────────────
#>   rows      465,937  (-29,007)
#>   cols           89  (= 0)
#>   NA cols        55  (-3)
#>   size       273.3 MB  (-16.75 MB)
```

Review the full exclusion history.

``` r
ops_snapshot()
#> ── ops_snapshot history ─────────────────────────────────────────────────────
#>    idx                              label timestamp   nrow  ncol n_na_cols size_mb
#>  1:  1                                raw  15:35:24 500000    89        59  293.03
#>  2:  2    after excluding prevalent cases  15:35:51 494944    89        58  290.08
#>  3:  3 after excluding missing covariates  15:36:18 465937    89        55  273.33
```

Before running the association analysis, we take a quick look at the
final cohort — exposure distribution, outcome ascertainment, and
follow-up time.

``` r
# Exposure distribution
data[, .N, by = smoking_ever]

#>    smoking_ever      N
#>          <fctr>  <int>
#>  1:        Ever 215893
#>  2:       Never 250044

# Outcome: incident cases and timing
data[, .N, by = lung_timing]
#>    lung_timing      N
#>          <int>  <int>
#>  1:          0 462110
#>  2:          2   3827

# Follow-up time in years
data[, .(mean   = round(mean(lung_followup_years),   2),
         median = round(median(lung_followup_years), 2),
         min    = round(min(lung_followup_years),    2),
         max    = round(max(lung_followup_years),    2))]
#>     mean median min    max
#>    <num>  <num> <num> <num>
#>  1: 13.71  14.09     0 16.83
```

## 7 Association Analysis

We fit a Cox proportional hazards model with
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md).
The function automatically produces three adjustment levels: unadjusted,
age and sex adjusted, and fully adjusted.

``` r
res <- assoc_coxph(
  data         = data,
  outcome_col  = "lung_status",
  time_col     = "lung_followup_years",
  exposure_col = "smoking_ever",
  covariates   = c("p21022",              # age_at_recruitment
                   "p31",                 # sex
                   "bmi_cat",
                   "tdi_cat",
                   "p1558_i0",            # alcohol_intake_frequency_i0
                   "p54_i0",              # uk_biobank_assessment_centre_i0
                   paste0("p22009_a", 1:10))  # genetic PCs 1-10
)
#> ℹ outcome_col lung_status: logical detected, converting TRUE/FALSE -> 1/0
#> ── assoc_coxph ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models = 3 Cox regressions
#> ℹ Input cohort: 465937 participants (n/n_events/person_years reflect each model's actual analysis set)
#> ── smoking_ever ─────────────────────────────────────────────────────────────
#>   ✔ Unadjusted             | smoking_everEver: HR 0.99 (0.93-1.06), p = 0.834
#>   ✔ Age and sex adjusted   | smoking_everEver: HR 0.99 (0.93-1.06), p = 0.838
#>   ✔ Fully adjusted         | smoking_everEver: HR 0.99 (0.93-1.06), p = 0.829
#> ✔ Done: 3 result rows across 1 exposure and 3 models.
```

The results reflect the absence of a built-in exposure–outcome
relationship in the simulated data. A real UK Biobank analysis may yield
substantially different estimates.

## 8 Visualisation

We first inspect the result table returned by
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md).

``` r
print(res)
#>        exposure             term                model      n n_events person_years        HR  CI_lower
#>          <char>           <char>                <ord>  <int>    <num>        <num>     <num>     <num>
#>  1: smoking_ever smoking_everEver           Unadjusted 465937     3827      6388195 0.9932076 0.9320517
#>  2: smoking_ever smoking_everEver Age and sex adjusted 465937     3827      6388195 0.9933735 0.9322072
#>  3: smoking_ever smoking_everEver       Fully adjusted 465937     3827      6388195 0.9930029 0.9318576
#>     CI_upper   p_value         HR_label
#>        <num>     <num>           <char>
#>  1: 1.058376 0.8335146 0.99 (0.93-1.06)
#>  2: 1.058553 0.8375372 0.99 (0.93-1.06)
#>  3: 1.058160 0.8285626 0.99 (0.93-1.06)

class(res)
#> [1] "data.table" "data.frame"
```

[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
relies on dplyr internally, so we convert the result to a plain
data.frame first.

``` r
res_df <- as.data.frame(res)
```

`res_df` can be used directly with
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
to produce a forest plot.

``` r
p <- plot_forest(
  data       = res_df,
  est        = res_df$HR,
  lower      = res_df$CI_lower,
  upper      = res_df$CI_upper,
  ci_column  = 2L,          # forest plot rendered in column 2 (HR_label)
  p_cols     = "p_value",
  ref_line   = 1,
  xlim       = c(0, 2.0),
  ticks_at   = c(0, 0.5, 1.0, 1.5, 2.0)
)

plot(p)
```

Or we can reshape `res_df` or add equal-length vectors to produce a
publication-ready figure.

``` r
p2 <- plot_forest(
  data       = res_df[, c("model", "n_events", "n", "p_value")],
  est        = res_df$HR,
  lower      = res_df$CI_lower,
  upper      = res_df$CI_upper,
  ci_column  = 4L,
  p_cols     = "p_value",
  ref_line   = 1,
  xlim       = c(0, 2.0),
  ticks_at   = c(0.5, 0.75, 1.0, 1.25, 1.5),
  header     = c("Model", "Cases", "N", "", "HR (95% CI)", "P value")
)

plot(p2)
```

To add a header row with an exposure label, prepend a row with `NA`
estimates.

``` r
res_pub <- rbind(
  data.frame(model = "Ever vs. Never", HR_label = "", p_value = NA,
             HR = NA, CI_lower = NA, CI_upper = NA, stringsAsFactors = FALSE),
  res_df[, c("model", "HR_label", "p_value", "HR", "CI_lower", "CI_upper")]
)

p3 <- plot_forest(
  data       = res_pub[, c("model", "p_value")],
  est        = res_pub$HR,
  lower      = res_pub$CI_lower,
  upper      = res_pub$CI_upper,
  ci_column  = 2L,
  p_cols     = "p_value",
  ref_line   = 1,
  xlim       = c(0, 2.0),
  ticks_at   = c(0, 0.5, 1.0, 1.5, 2.0),
  indent     = c(0L, 1L, 1L, 1L),
  bold_label = c(TRUE, FALSE, FALSE, FALSE),
  header     = c("Model", "", "HR (95% CI)", "P value")
)

plot(p3)
```

For further customisation — colours, font sizes, borders, arrow labels,
and saving to file — see
[`?plot_forest`](https://evanbio.github.io/ukbflow/reference/plot_forest.md).

> **Acknowledgement**: Forest plots are one of the most widely used
> methods in epidemiology for presenting effect estimates and their
> uncertainty.
> [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
> is powered by the
> [forestploter](https://cran.r-project.org/package=forestploter)
> package. We thank its author for the excellent work.

The package also provides
[`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
for generating publication-ready baseline characteristic tables. Here we
show a demo — for more advanced usage see
[`?plot_tableone`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md).

``` r
t1 <- plot_tableone(
  data    = as.data.frame(data),
  vars    = c("p21022", "p31", "bmi_cat", "tdi_cat", "p1558_i0"),
  strata  = "smoking_ever",
  label   = list(
    p21022   ~ "Age at recruitment (years)",
    p31      ~ "Sex",
    bmi_cat  ~ "BMI category",
    tdi_cat  ~ "Townsend deprivation index",
    p1558_i0 ~ "Alcohol intake frequency"
  ),
  add_p   = TRUE,
  save    = FALSE
)

print(t1)
```

## Getting Help

- [`?ops_toy`](https://evanbio.github.io/ukbflow/reference/ops_toy.md),
  [`?ops_snapshot`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md),
  [`?ops_na`](https://evanbio.github.io/ukbflow/reference/ops_na.md)
- [`?derive_missing`](https://evanbio.github.io/ukbflow/reference/derive_missing.md),
  [`?derive_covariate`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md),
  [`?derive_cut`](https://evanbio.github.io/ukbflow/reference/derive_cut.md),
  [`?derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
- [`?derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md),
  [`?derive_case`](https://evanbio.github.io/ukbflow/reference/derive_case.md),
  [`?derive_timing`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
  [`?derive_followup`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
- [`?assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
  [`?plot_forest`](https://evanbio.github.io/ukbflow/reference/plot_forest.md),
  [`?plot_tableone`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md),
  [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md),
  [`vignette("assoc")`](https://evanbio.github.io/ukbflow/articles/assoc.md),
  [`vignette("plot")`](https://evanbio.github.io/ukbflow/articles/plot.md)
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)

## 9 Session Info

Session Info

``` r
sessionInfo()
#> R version 4.5.1 (2025-06-13 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26200)
#>
#> Matrix products: default
#>   LAPACK version 3.12.1
#>
#> locale:
#> [1] LC_COLLATE=Chinese (Simplified)_China.utf8  LC_CTYPE=Chinese (Simplified)_China.utf8
#> [3] LC_MONETARY=Chinese (Simplified)_China.utf8 LC_NUMERIC=C
#> [5] LC_TIME=Chinese (Simplified)_China.utf8
#>
#> time zone: Asia/Shanghai
#> tzcode source: internal
#>
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base
#>
#> other attached packages:
#> [1] ukbflow_0.3.0  testthat_3.2.3
#>
#> loaded via a namespace (and not attached):
#>  [1] gt_1.0.0            sass_0.4.10         tidyr_1.3.1         generics_0.1.4      gtsummary_2.4.0
#>  [6] xml2_1.3.8          lattice_0.22-7      digest_0.6.37       magrittr_2.0.3      evaluate_1.0.5
#> [11] grid_4.5.1          cards_0.7.0         pkgload_1.4.0       fastmap_1.2.0       rprojroot_2.1.1
#> [16] jsonlite_2.0.0      Matrix_1.7-3        processx_3.8.6      pkgbuild_1.4.8      sessioninfo_1.2.3
#> [21] backports_1.5.0     cardx_0.3.0         brio_1.1.5          survival_3.8-3      ps_1.9.1
#> [26] gridExtra_2.3       purrr_1.0.4         cli_3.6.4           forestploter_1.1.3  rlang_1.1.6
#> [31] litedown_0.7        commonmark_2.0.0    ellipsis_0.3.2      splines_4.5.1       remotes_2.5.0
#> [36] withr_3.0.2         cachem_1.1.0        devtools_2.4.5.9000 tools_4.5.1         memoise_2.0.1
#> [41] dplyr_1.1.4.9000    broom_1.0.10        curl_7.0.0          vctrs_0.6.5         R6_2.6.1
#> [46] lifecycle_1.0.4     fs_1.6.6            usethis_3.2.1       pkgconfig_2.0.3     desc_1.4.3
#> [51] pillar_1.11.1       gtable_0.3.6        data.table_1.17.0   glue_1.8.0          xfun_0.52
#> [56] tibble_3.2.1        tidyselect_1.2.1    rstudioapi_0.17.1   knitr_1.50          htmltools_0.5.8.1
#> [61] rmarkdown_2.29      compiler_4.5.1      markdown_2.0
```

## 10 References

- Xu C (2023). *forestploter: Create Flexible Forest Plot*. R package
  version 1.1.3. <https://CRAN.R-project.org/package=forestploter>

- Sjoberg DD, Whiting K, Curry M, Lavery JA, Larmarange J (2021).
  Reproducible Summary Tables with the gtsummary Package. *The R
  Journal*, 13(1), 570–580. <https://doi.org/10.32614/RJ-2021-053>

- Iannone R, Cheng J, Schloerke B, Haughton S, Hughes E, Lauer A,
  François R, Seo J, Brevoort K, Roy O (2026). *gt: Easily Create
  Presentation-Ready Display Tables*. R package version 1.3.0.9000.
  <https://gt.rstudio.com>
