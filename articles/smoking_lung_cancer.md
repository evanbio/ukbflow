# Smoking and Lung Cancer Risk: A Synthetic Workflow Demonstration

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
#> ✔ ops_toy: 500000 participants | 107 columns | scenario = "cohort" | seed = 2026
```

An analysis in ukbflow can carry a lightweight **audit manifest**
alongside it, recording the field IDs, data snapshots, phenotype
definitions, and model results as the script runs. We open one now with
[`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
and thread it through the rest of this vignette; the full API is covered
in
[`vignette("audit")`](https://evanbio.github.io/ukbflow/articles/audit.md).

``` r

aud <- audit_start("smoking_lung_cancer", check_dx = FALSE)
aud
#> ── ukbflow audit ───────────────────────────────────────────────────────────
#> name: "smoking_lung_cancer"
#> start_time: "2026-08-11T18:57:24+0800"
#> ukbflow_version: "0.3.4"
#> dx_user: "NA"
#> dx_project: "NA"
#> fields: 0
#> recipes: 0
#> snapshots: 0
#> phenotypes: 0
#> models: 0
#> jobs: 0
#> session_info: recorded
```

In a real RAP workflow the field IDs are already in a vector before
extraction; record that same vector so the manifest documents exactly
what was requested. Here we list the fields this synthetic analysis
draws on.

``` r

fields <- c(31, 53, 21022, 21001, 20116, 1558, 22189, 54,
            22009, 20001, 20006, 40006, 40011, 40012, 40005, 40000)
aud <- audit_fields(aud, fields, label = "analysis_fields")
```

## 3 Name Columns Semantically

On the RAP,
[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
reads the project’s own field dictionary and renames every column at
once (`p31` → `sex`, `p21022` → `age_at_recruitment`, and so on). It
needs that dictionary, so it only works inside the RAP environment:

``` r

data <- decode_names(data)
```

This vignette runs entirely offline, so it renames the handful of
columns the analysis touches with an explicit mapping instead. The
result is the same: everything below refers to columns by meaning rather
than by field ID.

``` r

name_map <- c(
  p31       = "sex",
  p53_i0    = "date_of_attending_assessment_centre_i0",
  p21022    = "age_at_recruitment",
  p21001_i0 = "body_mass_index_bmi_i0",
  p20116_i0 = "smoking_status_i0",
  p1558_i0  = "alcohol_intake_frequency_i0",
  p22189    = "townsend_deprivation_index_at_recruitment",
  p54_i0    = "uk_biobank_assessment_centre_i0",
  p40000_i0 = "date_of_death_i0"
)
setnames(data, names(name_map), unname(name_map))

# Genetic principal components: p22009_a1 ... p22009_a10 -> pc1 ... pc10
pc_raw <- paste0("p22009_a", 1:10)
setnames(data, pc_raw, paste0("pc", 1:10))
```

## 4 Derive Phenotypes

We first handle non-informative missing codes (e.g. “Do not know”,
“Prefer not to answer”) with
[`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md).

``` r

data <- derive_missing(data)
#> ✔ derive_missing: replaced 279782 values across 3 columns (action = "na").
```

Next, convert categorical columns to factors with
[`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md).

``` r

data <- derive_covariate(
  data,
  as_factor = c(
    "sex",
    "smoking_status_i0",
    "alcohol_intake_frequency_i0",
    "uk_biobank_assessment_centre_i0"
  )
)
#> ── Factor ──────────────────────────────────────────────────────────────────
#> sex [2 levels]
#> Female: n=270191 (54%)
#> Male: n=229809 (46%)
#> <NA>: n=0 (0%)
#> smoking_status_i0 [3 levels]
#> Current: n=69867 (14%)
#> Never: n=260458 (52.1%)
#> Previous: n=154871 (31%)
#> <NA>: n=14804 (3%)
#> ! alcohol_intake_frequency_i0: 6 levels > max_levels (5), consider collapsing categories.
#> alcohol_intake_frequency_i0 [6 levels]
#> Daily or almost daily: n=40113 (8%)
#> Never: n=45207 (9%)
#> Once or twice a week: n=140335 (28.1%)
#> One to three times a month: n=84580 (16.9%)
#> Special occasions only: n=70118 (14%)
#> Three or four times a week: n=104674 (20.9%)
#> <NA>: n=14973 (3%)
#> ! uk_biobank_assessment_centre_i0: 10 levels > max_levels (5), consider collapsing categories.
#> uk_biobank_assessment_centre_i0 [10 levels]
#> Birmingham: n=49709 (9.9%)
#> Bristol: n=49832 (10%)
#> Edinburgh: n=50212 (10%)
#> Leeds: n=49710 (9.9%)
#> Liverpool: n=50338 (10.1%)
#> Manchester: n=50095 (10%)
#> Newcastle: n=50237 (10%)
#> Nottingham: n=49848 (10%)
#> Oxford: n=49726 (9.9%)
#> Sheffield: n=50293 (10.1%)
#> <NA>: n=0 (0%)
```

We then bin BMI and Townsend Deprivation Index (TDI) into categories
using
[`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md).

``` r

data <- derive_cut(
  data,
  col    = "body_mass_index_bmi_i0",
  n      = 4,
  breaks = c(18.5, 25, 30),
  labels = c("Underweight", "Normal", "Overweight", "Obese"),
  name   = "bmi_cat"
)

data <- derive_cut(
  data,
  col    = "townsend_deprivation_index_at_recruitment",
  n      = 4,
  labels = c("Q1 (least deprived)", "Q2", "Q3", "Q4 (most deprived)"),
  name   = "tdi_cat"
)
#> ── Source: body_mass_index_bmi_i0 ──────────────────────────────────────────
#> body_mass_index_bmi_i0: mean=26.21, median=26.19, sd=5.48, Q1=22.48,
#> Q3=29.9, NA=0% (n=0)
#> ── New column: bmi_cat ─────────────────────────────────────────────────────
#> bmi_cat [4 levels]
#> Underweight: n=40238 (8%)
#> Normal: n=166710 (33.3%)
#> Overweight: n=170794 (34.2%)
#> Obese: n=122258 (24.5%)
#> <NA>: n=0 (0%)
#> ── Source: townsend_deprivation_index_at_recruitment ───────────────────────
#> townsend_deprivation_index_at_recruitment: mean=-1.25, median=-1.3, sd=3.1,
#> Q1=-3.46, Q3=0.86, NA=0% (n=0)
#> ── New column: tdi_cat ─────────────────────────────────────────────────────
#> tdi_cat [4 levels]
#> Q1 (least deprived): n=125290 (25.1%)
#> Q2: n=124831 (25%)
#> Q3: n=125102 (25%)
#> Q4 (most deprived): n=124777 (25%)
#> <NA>: n=0 (0%)
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
#> ! derive_selfreport: no visit columns for field 53.
#> ✔ derive_selfreport (lung_cancer): 6622 cases, 6622 with dates.
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
#> ✔ derive_cancer_registry (lung): 2497 cases, 2497 with date.
#> ✔ derive_icd10 (lung): 2497 cases across 1 source, 2497 with date.
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
#> ✔ derive_case (lung): 9085 cases, 9085 with date.
#> ℹ   Both sources (lung_icd10 & lung_cancer_selfreport): 34
```

Finally,
[`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
classifies each case as prevalent (disease before baseline) or incident
(disease after baseline), which determines eligibility for the survival
analysis.

``` r

data <- derive_timing(data, name = "lung", baseline_col = "date_of_attending_assessment_centre_i0")
#> ✔ derive_timing (lung_timing):
#> ℹ   0 (no disease): 490915
#> ℹ   1 (prevalent):  5045
#> ℹ   2 (incident):   4040
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
  baseline_col = "date_of_attending_assessment_centre_i0",
  censor_date  = as.Date("2022-10-31"),
  death_col    = "date_of_death_i0",
  lost_col     = FALSE             # lost-to-follow-up not available in this dataset
)
#> ✔ derive_followup (lung):
#> ℹ   lung_followup_end: 500000 / 500000 non-missing
#> ℹ   lung_followup_years: mean=13.72, median=14.09, range=[0, 16.83]
```

With the phenotype fully derived,
[`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
records a summary of the `lung_*` columns — self-report and ICD-10
components, combined status, timing, and follow-up — into the manifest.
It reads whichever components exist and needs only the phenotype prefix.

``` r

aud <- audit_pheno(aud, data, "lung")
```

## 5 Exposure Definition

Smoking status has three levels (Never, Previous, Current). For a
cleaner binary contrast, we collapse Previous and Current into a single
“Ever” category, with “Never” as the reference level.

``` r

data[, smoking_ever := factor(
  ifelse(smoking_status_i0 == "Never", "Never", "Ever"),
  levels = c("Never", "Ever")   # Never = reference
)]
```

## 6 Cohort Assembly

We exclude prevalent lung cancer cases and participants with missing
exposure or follow-up time to arrive at the final analysis cohort.
[`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
records the cohort size and column structure at each step into the audit
manifest — and, as we show below, that history exports directly as the
cohort flow diagram for your methods section.

``` r

aud <- audit_snapshot(aud, data, "raw")
#> ✔ audit snapshot "raw": 500000 rows x 121 cols.
```

Exclude participants with prevalent lung cancer (diagnosed at or before
baseline) — they are not eligible for the incident analysis.

``` r

data <- data[lung_timing != 1 | is.na(lung_timing)]
aud <- audit_snapshot(aud, data, "after excluding prevalent cases")
#> ✔ audit snapshot "after excluding prevalent cases": 494955 rows x 121 cols.
```

Exclude participants with missing values in the exposure or any
covariate.

``` r

data <- data[!is.na(smoking_ever)  &
             !is.na(sex)           &
             !is.na(age_at_recruitment)        &
             !is.na(bmi_cat)       &   # bmi category
             !is.na(alcohol_intake_frequency_i0) &
             !is.na(tdi_cat)       &   # townsend deprivation category
             !is.na(uk_biobank_assessment_centre_i0) &
             !is.na(pc1)     &
             !is.na(pc2)     &
             !is.na(pc3)     &
             !is.na(pc4)     &
             !is.na(pc5)     &
             !is.na(pc6)     &
             !is.na(pc7)     &
             !is.na(pc8)     &
             !is.na(pc9)     &
             !is.na(pc10)]
aud <- audit_snapshot(aud, data, "after excluding missing covariates")
#> ✔ audit snapshot "after excluding missing covariates": 465927 rows x 121 cols.
```

The recorded snapshots export directly as a cohort attrition table with
[`audit_flowchart()`](https://evanbio.github.io/ukbflow/reference/audit_flowchart.md).
Each step’s parent is the previous one, and a drop in row count is
emitted as a sibling `exclusion` row — exactly the shape a flow-diagram
package needs, with no manual bookkeeping.

``` r

audit_flowchart(aud)
#> raw: 500000
#> after excluding prevalent cases: 494955 (excluded 5045)
#> after excluding missing covariates: 465927 (excluded 29028)
```

Before running the association analysis, we take a quick look at the
final cohort — exposure distribution, outcome ascertainment, and
follow-up time.

``` r

# Exposure distribution
data[, .N, by = smoking_ever]


# Outcome: incident cases and timing
data[, .N, by = lung_timing]

# Follow-up time in years
data[, .(mean   = round(mean(lung_followup_years),   2),
         median = round(median(lung_followup_years), 2),
         min    = round(min(lung_followup_years),    2),
         max    = round(max(lung_followup_years),    2))]
#>    smoking_ever      N
#>          <fctr>  <int>
#> 1:         Ever 215902
#> 2:        Never 250025
#>    lung_timing      N
#>          <int>  <int>
#> 1:           0 462114
#> 2:           2   3813
#>     mean median   min   max
#>    <num>  <num> <num> <num>
#> 1: 13.72  14.09     0 16.83
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
  covariates   = c("age_at_recruitment",
                   "sex",
                   "bmi_cat",
                   "tdi_cat",
                   "alcohol_intake_frequency_i0",
                   "uk_biobank_assessment_centre_i0",
                   paste0("pc", 1:10))
)
#> ℹ outcome_col lung_status: logical detected, converting TRUE/FALSE -> 1/0
#> ── assoc_coxph ─────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models = 3 Cox regressions
#> ℹ Input cohort: 465927 participants (n/n_events/person_years reflect each model's actual analysis set)
#> ── smoking_ever ──
#> ✔   Unadjusted | smoking_everEver: HR 1.04 (0.98-1.11), p = 0.203
#> ✔   Age and sex adjusted | smoking_everEver: HR 1.04 (0.98-1.11), p = 0.201
#> ✔   Fully adjusted | smoking_everEver: HR 1.04 (0.98-1.11), p = 0.201
#> ✔ Done: 3 result rows across 1 exposure and 3 models.
```

[`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
stores the result table in the manifest. It picks up the outcome column,
time column, covariates, and exposure reference levels automatically
from an attribute `assoc_*` attaches to its own return value — nothing
needs to be re-typed, and `res` prints and plots exactly as before.

``` r

aud <- audit_model(aud, result = res, label = "smoking_lung_cox")
```

The results reflect the absence of a built-in exposure–outcome
relationship in the simulated data. A real UK Biobank analysis may yield
substantially different estimates.

## 8 Visualisation

We first inspect the result table returned by
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md).

``` r

print(res)

class(res)
#>        exposure             term                model      n n_events
#>          <char>           <char>                <ord>  <int>    <num>
#> 1: smoking_ever smoking_everEver           Unadjusted 465927     3813
#> 2: smoking_ever smoking_everEver Age and sex adjusted 465927     3813
#> 3: smoking_ever smoking_everEver       Fully adjusted 465927     3813
#>    person_years       HR  CI_lower CI_upper   p_value         HR_label
#>           <num>    <num>     <num>    <num>     <num>           <char>
#> 1:      6391737 1.042196 0.9780063 1.110599 0.2025609 1.04 (0.98-1.11)
#> 2:      6391737 1.042301 0.9781046 1.110711 0.2014650 1.04 (0.98-1.11)
#> 3:      6391737 1.042351 0.9781498 1.110767 0.2009548 1.04 (0.98-1.11)
#> [1] "data.table" "data.frame"
```

The quickest path is to pass `res` straight to
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md).
With `est` / `lower` / `upper` omitted, it auto-detects the Cox result
and derives the estimate and CI columns, reference line, display
columns, header, and x-axis range for you:

``` r

plot(plot_forest(res))
#> ✔ plot_forest: detected HR result: 3 rows, reference line at 1.
```

Because `smoking_ever` is binary, the figure shows one row per
adjustment model. (A categorical exposure would instead keep each
level’s models grouped together, with a `Term` column added
automatically.) Anything you pass explicitly overrides the auto value —
for example, to widen the axis or pick which columns to display:

``` r

plot(plot_forest(
  res,
  show_cols = c("n_events", "person_years", "p_value"),
  xlim      = c(0.5, 1.5)
))
```

For a fully bespoke layout — custom labels, an exposure header row,
hand-picked columns — build the display frame yourself and supply the
vectors directly. Here we prepend a row with `NA` estimates as a bold
section header:

``` r

res_df <- as.data.frame(res)

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

Alongside the adjusted hazard ratios above,
[`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md)
draws the **unadjusted** Kaplan-Meier curves straight from the same
follow-up-time and status columns
([`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
/
[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
output) — no [`Surv()`](https://rdrr.io/pkg/survival/man/Surv.html)
object needed. It reuses the exact `time_col` / `status_col` / `strata`
vocabulary of
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md).

``` r

plot_survival(
  data       = data,
  time_col   = "lung_followup_years",
  status_col = "lung_status",
  strata     = "smoking_ever",
  xlab       = "Follow-up (years)",
  title      = "Lung-cancer-free survival by smoking status"
)
```

The figure ships with a confidence-interval ribbon, a numbers-at-risk
table, and a log-rank p-value by default. Use `type = "risk"` for
cumulative incidence, or the `add_*` switches to toggle layers — see
[`?plot_survival`](https://evanbio.github.io/ukbflow/reference/plot_survival.md).

The package also provides
[`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
for generating publication-ready baseline characteristic tables. Here we
show a demo — for more advanced usage see
[`?plot_tableone`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md).

``` r

t1 <- plot_tableone(
  data    = as.data.frame(data),
  vars    = c("age_at_recruitment", "sex", "bmi_cat", "tdi_cat", "alcohol_intake_frequency_i0"),
  strata  = "smoking_ever",
  label   = list(
    age_at_recruitment   ~ "Age at recruitment (years)",
    sex      ~ "Sex",
    bmi_cat  ~ "BMI category",
    tdi_cat  ~ "Townsend deprivation index",
    alcohol_intake_frequency_i0 ~ "Alcohol intake frequency"
  ),
  add_p   = TRUE,
  save    = FALSE
)

print(t1)
```

## 9 Audit Trail

Throughout the analysis we appended records to `aud`.
[`summary()`](https://rdrr.io/r/base/summary.html) gives a
directory-style overview of every layer — the fields requested, the
cohort snapshots, the phenotype summary, and the model — each with a
one-line preview.

``` r

summary(aud)
#> ── ukbflow audit summary ───────────────────────────────────────────────────
#> name: "smoking_lung_cancer"
#> started: "2026-08-11T18:57:24+0800"
#> ukbflow_version: "0.3.4"
#> dx_user: "NA"
#> dx_project: "NA"
#> fields: 1
#> - analysis_fields: 16 fields (no dataset): 31, 53, 21022, 21001, 20116,
#> 1558, +10 more
#> recipes: 0
#> snapshots: 3
#> - raw: 500000 rows x 121 cols: eid, sex, p34,
#> date_of_attending_assessment_centre_i0, age_at_recruitment,
#> body_mass_index_bmi_i0, +115 more
#> - after excluding prevalent cases: 494955 rows x 121 cols: eid, sex, p34,
#> date_of_attending_assessment_centre_i0, age_at_recruitment,
#> body_mass_index_bmi_i0, +115 more
#> - after excluding missing covariates: 465927 rows x 121 cols: eid, sex,
#> p34, date_of_attending_assessment_centre_i0, age_at_recruitment,
#> body_mass_index_bmi_i0, +115 more
#> phenotypes: 1
#> - lung: 500000 rows, 9085 cases, timing 0/1/2 = 490915/5045/4040
#> models: 1
#> - smoking_lung_cox: coxph; exposures: smoking_ever; covariates:
#> age_at_recruitment, sex, bmi_cat, tdi_cat, alcohol_intake_frequency_i0,
#> uk_biobank_assessment_centre_i0, +10 more; 3 result rows
#> jobs: 0
#> session_info: recorded
```

Write the manifest as JSON alongside your analysis outputs.
[`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
validates the object first, so the file is either complete and
well-formed or not written at all.

``` r

audit_write(aud, "smoking_lung_cancer_audit.json", overwrite = TRUE)
#> ✔ audit manifest written: '<working directory>/smoking_lung_cancer_audit.json'
```

A saved manifest can be read back with
[`audit_read()`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
and compared — against the current analysis, or against a manifest from
a previous run — with
[`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md).
This is how you check that a re-run still matches a published analysis,
without re-running it.

``` r

aud_saved <- audit_read("smoking_lung_cancer_audit.json")

# What changed across the cohort snapshots?
audit_diff(aud_saved, layer = "snapshots")
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
  [`?assoc_rcs`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md),
  [`?assoc_evalue`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md),
  [`?plot_forest`](https://evanbio.github.io/ukbflow/reference/plot_forest.md),
  [`?plot_survival`](https://evanbio.github.io/ukbflow/reference/plot_survival.md),
  [`?plot_rcs`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md),
  [`?plot_tableone`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
- [`?audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md),
  [`?audit_snapshot`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md),
  [`?audit_pheno`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md),
  [`?audit_model`](https://evanbio.github.io/ukbflow/reference/audit_model.md),
  [`?audit_flowchart`](https://evanbio.github.io/ukbflow/reference/audit_flowchart.md),
  [`?audit_write`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md),
  [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md),
  [`vignette("assoc")`](https://evanbio.github.io/ukbflow/articles/assoc.md),
  [`vignette("plot")`](https://evanbio.github.io/ukbflow/articles/plot.md),
  [`vignette("audit")`](https://evanbio.github.io/ukbflow/articles/audit.md)
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)

## 10 Session Info

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
#> [1] ukbflow_0.3.4  testthat_3.2.3
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

## 11 References

- Xu C (2023). *forestploter: Create Flexible Forest Plot*. R package
  version 1.1.3. <https://CRAN.R-project.org/package=forestploter>

- Sjoberg DD, Whiting K, Curry M, Lavery JA, Larmarange J (2021).
  Reproducible Summary Tables with the gtsummary Package. *The R
  Journal*, 13(1), 570–580. <https://doi.org/10.32614/RJ-2021-053>

- Iannone R, Cheng J, Schloerke B, Haughton S, Hughes E, Lauer A,
  François R, Seo J, Brevoort K, Roy O (2026). *gt: Easily Create
  Presentation-Ready Display Tables*. R package version 1.3.0.9000.
  <https://gt.rstudio.com>
