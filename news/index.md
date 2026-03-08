# Changelog

## ukbflow 0.1.0

*Released: March 6, 2026*

Initial release of **ukbflow** — a RAP-native R workflow for UK Biobank
analysis.

### New Features

#### Connection

- [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)
  — authenticate to RAP via dx-toolkit token
- [`auth_logout()`](https://evanbio.github.io/ukbflow/reference/auth_logout.md)
  — revoke current session
- [`auth_status()`](https://evanbio.github.io/ukbflow/reference/auth_status.md)
  — check current login state
- [`auth_list_projects()`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md)
  — list accessible RAP projects
- [`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md)
  — set active RAP project

#### Data Access

- [`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md)
  /
  [`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)
  — browse RAP project file structure
- [`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md)
  — download files from RAP to local
- [`fetch_url()`](https://evanbio.github.io/ukbflow/reference/fetch_url.md)
  — generate pre-signed download URLs
- [`fetch_metadata()`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md)
  — retrieve UKB field metadata (field.tsv, encoding.tsv)
- [`fetch_field()`](https://evanbio.github.io/ukbflow/reference/fetch_field.md)
  — retrieve UKB field-level metadata for specific field IDs
- [`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
  — list available UKB datasets on RAP
- [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
  — synchronously extract phenotype fields from a RAP dataset
- [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
  — submit a DNAnexus table-exporter job to extract phenotype fields
- [`job_wait()`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
  — poll job status until completion
- [`job_status()`](https://evanbio.github.io/ukbflow/reference/job_status.md)
  / [`job_ls()`](https://evanbio.github.io/ukbflow/reference/job_ls.md)
  /
  [`job_path()`](https://evanbio.github.io/ukbflow/reference/job_path.md)
  /
  [`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md)
  — monitor and locate RAP jobs

#### Data Processing

- [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
  — convert integer codes to human-readable labels
- [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
  — rename `p{field}_i{instance}_a{array}` columns to descriptive names
- [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
  — recode UKB informative-missing labels to `NA`
- [`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md)
  — standardise common covariates (age, BMI, TDI, etc.)
- [`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
  — create ordered factor variables from numeric cutpoints
- [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
  — derive disease phenotypes from Hospital Episode Statistics (ICD-10)
- [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
  — derive cancer phenotypes from UK cancer registry (ICD-10)
- [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
  — derive phenotypes from death registry (primary + secondary causes)
- [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md)
  — derive phenotypes from UKB First Occurrence fields
- [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
  — derive disease phenotypes from self-reported illness codes
- [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
  — merge multi-source ICD-10 case definitions across all registers
- [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
  — merge arbitrary multi-source case definitions
- [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
  — compute follow-up time with competing event support
- [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
  — classify prevalent vs. incident cases
- [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md)
  — compute age at event

#### Association Analysis

- [`assoc_linear()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
  — linear regression with automatic three-model framework
- [`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  — logistic regression with automatic three-model framework
- [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  — Cox proportional hazards with automatic three-model framework
- [`assoc_coxph_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md)
  — test proportional hazards assumption
- [`assoc_competing()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md)
  — Fine-Gray competing risks regression
- [`assoc_subgroup()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md)
  — subgroup analysis with interaction likelihood-ratio test
- [`assoc_trend()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
  — dose-response trend analysis across ordered categories
- [`assoc_lag()`](https://evanbio.github.io/ukbflow/reference/assoc_lag.md)
  — landmark / lag-time sensitivity analysis

#### Genomic Risk Score (GRS)

- [`grs_check()`](https://evanbio.github.io/ukbflow/reference/grs_check.md)
  — validate and reformat a GWAS summary statistics weight file
- [`grs_bgen2pgen()`](https://evanbio.github.io/ukbflow/reference/grs_bgen2pgen.md)
  — submit parallel BGEN → PGEN conversion jobs on RAP
- [`grs_score()`](https://evanbio.github.io/ukbflow/reference/grs_score.md)
  — submit distributed plink2 GRS scoring jobs on RAP
- [`grs_standardize()`](https://evanbio.github.io/ukbflow/reference/grs_standardize.md)
  — standardise GRS columns to mean = 0, SD = 1
- [`grs_validate()`](https://evanbio.github.io/ukbflow/reference/grs_validate.md)
  — validate GRS distribution and association with known risk factors

#### Visualization

- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  — publication-ready forest plots with customisable CI columns and
  p-value formatting
- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  — Table 1 baseline characteristics figure
