# ukbflow 0.2.0

*Released: March 10, 2026*

## New Features

### Operations (ops_*)
- `ops_setup()` — check and report the local environment (R, dx-toolkit, dxpy) health
- `ops_toy()` — generate synthetic UKB-style cohort or forest-plot data for testing and demos; includes GRS columns and cancer self-report fields
- `ops_na()` — summarise missing-value rates per column with threshold-based filtering and `cli` progress feedback
- `ops_snapshot()` — record and display a history of dataset row/column counts across pipeline steps

## Bug Fixes

- All `cli::cli_abort()` calls now pass `call = NULL` to suppress internal call-stack noise in error messages
- `ops_toy()`: added cancer self-report fields (`p20001`, `p20006`) and corrected `sr_codes` → text label mapping

## Documentation

- New vignette: *Smoking and Lung Cancer — End-to-End Analysis* (`vignette("smoking_lung_cancer")`)
- New vignette: *ops_* Series* covering setup, toy data, NA summary, and snapshots
- pkgdown site now auto-deploys via GitHub Actions (CI-managed `docs/`)

## Internal

- Resolved R CMD check NOTEs: added `importFrom(stats, rnorm, runif)`, `importFrom(utils, object.size)`, and `pct_na` to `globalVariables()`
- Added `builds/` to `.Rbuildignore`

---

# ukbflow 0.1.0

*Released: March 6, 2026*

Initial release of **ukbflow** — a RAP-native R workflow for UK Biobank analysis.

## New Features

### Connection
- `auth_login()` — authenticate to RAP via dx-toolkit token
- `auth_logout()` — revoke current session
- `auth_status()` — check current login state
- `auth_list_projects()` — list accessible RAP projects
- `auth_select_project()` — set active RAP project

### Data Access
- `fetch_ls()` / `fetch_tree()` — browse RAP project file structure
- `fetch_file()` — download files from RAP to local
- `fetch_url()` — generate pre-signed download URLs
- `fetch_metadata()` — retrieve UKB field metadata (field.tsv, encoding.tsv)
- `fetch_field()` — retrieve UKB field-level metadata for specific field IDs
- `extract_ls()` — list available UKB datasets on RAP
- `extract_pheno()` — synchronously extract phenotype fields from a RAP dataset
- `extract_batch()` — submit a DNAnexus table-exporter job to extract phenotype fields
- `job_wait()` — poll job status until completion
- `job_status()` / `job_ls()` / `job_path()` / `job_result()` — monitor and locate RAP jobs

### Data Processing
- `decode_values()` — convert integer codes to human-readable labels
- `decode_names()` — rename `p{field}_i{instance}_a{array}` columns to descriptive names
- `derive_missing()` — recode UKB informative-missing labels to `NA`
- `derive_covariate()` — standardise common covariates (age, BMI, TDI, etc.)
- `derive_cut()` — create ordered factor variables from numeric cutpoints
- `derive_hes()` — derive disease phenotypes from Hospital Episode Statistics (ICD-10)
- `derive_cancer_registry()` — derive cancer phenotypes from UK cancer registry (ICD-10)
- `derive_death_registry()` — derive phenotypes from death registry (primary + secondary causes)
- `derive_first_occurrence()` — derive phenotypes from UKB First Occurrence fields
- `derive_selfreport()` — derive disease phenotypes from self-reported illness codes
- `derive_icd10()` — merge multi-source ICD-10 case definitions across all registers
- `derive_case()` — merge arbitrary multi-source case definitions
- `derive_followup()` — compute follow-up time with competing event support
- `derive_timing()` — classify prevalent vs. incident cases
- `derive_age()` — compute age at event

### Association Analysis
- `assoc_linear()` — linear regression with automatic three-model framework
- `assoc_logistic()` — logistic regression with automatic three-model framework
- `assoc_coxph()` — Cox proportional hazards with automatic three-model framework
- `assoc_coxph_zph()` — test proportional hazards assumption
- `assoc_competing()` — Fine-Gray competing risks regression
- `assoc_subgroup()` — subgroup analysis with interaction likelihood-ratio test
- `assoc_trend()` — dose-response trend analysis across ordered categories
- `assoc_lag()` — landmark / lag-time sensitivity analysis

### Genomic Risk Score (GRS)
- `grs_check()` — validate and reformat a GWAS summary statistics weight file
- `grs_bgen2pgen()` — submit parallel BGEN → PGEN conversion jobs on RAP
- `grs_score()` — submit distributed plink2 GRS scoring jobs on RAP
- `grs_standardize()` — standardise GRS columns to mean = 0, SD = 1
- `grs_validate()` — validate GRS distribution and association with known risk factors

### Visualization
- `plot_forest()` — publication-ready forest plots with customisable CI columns and p-value formatting
- `plot_tableone()` — Table 1 baseline characteristics figure
