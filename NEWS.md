# ukbflow 0.3.3

*Released: April 2026*

## Bug Fixes

- `grs_validate()` — added `skip_if_not_installed("pROC")` guard to all
  logistic-path tests so the suite passes cleanly when `pROC` is absent

## Improvements

- Removed hardcoded default paths across all modules; examples refactored to
  use `ops_toy()` data where possible — runnable examples unwrapped,
  long-running examples (>5s) wrapped in `\donttest{}`, network-dependent
  examples remain in `\dontrun{}`
- `VignetteBuilder` field corrected in `DESCRIPTION`

## CI

- R CMD check split into four targeted workflows: `dev` (3 jobs), `main`
  (6 jobs), `release` (8 jobs, `--as-cran`), and `weekly` (scheduled every
  Saturday 21:00 CST, full CRAN-like matrix)
- Added `_R_CHECK_DEPENDS_ONLY_` matrix to verify Suggests packages are
  correctly declared

## Documentation

- Rd files regenerated across all modules after example and parameter updates

---

# ukbflow 0.3.2

*Released: March 26, 2026*

## Bug Fixes

- `ops_snapshot()` — removed Unicode character `Δ` from documentation to fix LaTeX PDF manual build on CRAN
- `test-plot.R` — added `skip_on_cran()` to `plot_tableone()` rendering tests that caused a 20-minute hang on Windows CRAN

## Improvements

- `plot_forest()` and `plot_tableone()` examples are now fully runnable (removed `\dontrun{}` wrapper; `save = FALSE` throughout)

## Documentation

- `README.md` — updated Codecov badge URL; fixed `CONTRIBUTING.md` and `README_zh.md` links to full GitHub URLs
- Added `inst/WORDLIST` with `Biobank` to suppress false-positive spelling NOTE on CRAN

---

# ukbflow 0.3.1

*Released: March 25, 2026*

## Bug Fixes

- `derive_followup()` — coerce date columns to `IDate` before `pmin()` to avoid type mismatch
- `install.Rmd` — corrected vignette cross-references

## Improvements

- All modules hardened with consistent `.assert_*()` input validation helpers
- All `cli::cli_abort()` calls now use `call = NULL` for cleaner error messages
- `plot_tableone()` — auto-coerce `data.table` input to `data.frame`

## Documentation

- Man pages updated across all modules (auth, fetch, extract, job, decode, derive, ops, grs, assoc, plot)
- All vignettes reviewed and corrected (output format, param contracts, example accuracy)
- `get-started.Rmd` and `README` updated for accuracy
- pkgdown reference index and vignette menu completed

## Tests

- Test suites overhauled for all modules: added input validation coverage, integration-style stubs, and edge cases

---

# ukbflow 0.3.0

*Released: March 13, 2026*

## New Features

### Operations (ops_*)
- `ops_withdraw()` — exclude UKB withdrawn participants from a cohort data.table by EID

### Snapshot — Column Tracking
- `ops_snapshot()` gains column-tracking helpers: `cols()`, `diff()`, `remove()`, and `set_safe_cols()`

### Visualisation Enhancements
- `plot_tableone()` — new `png_scale`, `pdf_width`, and `pdf_height` parameters for fine-grained output control

## Bug Fixes

- `fetch_file()` — enforce RAP-only guard; updated tests
- `grs_score()` — fix `-icmd` argument format; skip script upload if file already exists on RAP
- GRS pipeline — updated chr split threshold: chromosomes 1–16 use large instances, 17–22 use standard

## Documentation

- Added roxygen2 documentation for `ops_withdraw()`
- Unit tests added for `ops_withdraw()`

## Internal

- Added `broom` to `DESCRIPTION` Imports and `ops_setup()` dependency check
- Updated package logo (new hex sticker design)
- Integration tests requiring RAP environment are now skipped in local CI

---

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
