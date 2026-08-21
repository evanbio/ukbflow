# Changelog

## ukbflow 0.4.0

*Released: August 2026*

### New Features

#### Phenotype Recipes

A recipe is a versioned, shareable record of how a study defined a
phenotype — its sources, codes, combination logic, and the caveats
needed to reproduce it.

- [`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md),
  [`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
  [`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md)
  — browse, read and flatten the bundled library, now 67 definitions
  drawn from published UK Biobank analyses, several of them competing
  definitions of the same phenotype
- [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
  — apply a recipe end-to-end, adding only `{id}_status` and `{id}_date`
  however many sources it draws on
- [`recipe_rule()`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md),
  [`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md),
  [`recipe_write()`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)
  — author a definition without hand-writing YAML
- Contribution path for external definitions: a submission form that
  opens a pull request, and a lightweight CI check for recipe-only
  changes

#### Analysis Audit

- [`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
  and the
  [`audit_fields()`](https://evanbio.github.io/ukbflow/reference/audit_fields.md)
  /
  [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
  /
  [`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
  /
  [`audit_recipe()`](https://evanbio.github.io/ukbflow/reference/audit_recipe.md)
  /
  [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
  /
  [`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
  family record what an analysis did as it runs, against a fixed schema
  validated before writing
- [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
  /
  [`audit_read()`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
  — JSON manifests that round-trip exactly;
  [`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
  compares labelled records or two whole audits
- [`audit_cols()`](https://evanbio.github.io/ukbflow/reference/audit_cols.md)
  retrieves columns from a snapshot;
  [`audit_flowchart()`](https://evanbio.github.io/ukbflow/reference/audit_flowchart.md)
  exports a cohort attrition table
- `assoc_*()` results carry their call metadata, so
  [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
  records the model without being told

#### Phenotype Sources

- ICD-9:
  [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md),
  [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md),
  [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)
- OPCS-4 procedures:
  [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md)
- Primary care:
  [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
  and
  [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md),
  with
  [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)
  to load the `gp_clinical` record table
- Algorithmically-defined outcomes (Category 42):
  [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md)
- `position` selects any-position or main HES diagnoses; `cause` selects
  the underlying or contributory cause of death
- [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
  folds ICD-9, OPCS-4 and primary-care arms in when present

#### Data Access

- [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md),
  [`extract_olink()`](https://evanbio.github.io/ukbflow/reference/extract_olink.md),
  [`extract_nmr()`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md)
  — export the primary-care, proteomic and NMR metabolomic panels from
  RAP

#### Analysis and Visualisation

- [`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md)
  and
  [`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md)
  — restricted cubic spline dose-response with a non-linearity test
- [`assoc_evalue()`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md)
  — E-value sensitivity to unmeasured confounding
- [`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md)
  — Kaplan-Meier curves
- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  accepts an `assoc_*()` result table directly

#### Offline Lookups

- [`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
  searches approved project fields;
  [`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md)
  is an offline reference covering 14 groups, including the blood count,
  blood biochemistry and NMR panels in full
- [`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md)
  and
  [`ops_alg()`](https://evanbio.github.io/ukbflow/reference/ops_alg.md)
  look up the field IDs behind the 1,165 First Occurrence outcomes and
  19 algorithmically-defined outcomes
- [`ops_covariates()`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md)
  lists common covariate presets as decoded column names

### Improvements

- [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
  covers the main-position HES fields, an algorithmically-defined
  outcome, loss to follow-up, and a new `"gp"` scenario returning a
  `gp_clinical` long table, so the whole phenotype pipeline can be
  exercised offline
- `assoc_*()` gained explicit column resolution, likelihood-ratio tests
  and cluster-robust Cox variance
- `\donttest{}` removed from examples that run in well under a second,
  putting them back in the default check path
- The four `fetch_*` download helpers are removed; individual-level data
  stays on the platform

### Bug Fixes

- An empty or missing code list is now rejected rather than matched
  against every record. Previously `derive_hes(icd10 = NULL)` —
  reachable from a recipe rule with a misspelled code field — flagged
  every participant holding any HES record instead of none
- Recipe rules are validated on read as well as on construction: an
  unknown field, a missing code field, or an out-of-vocabulary `match`
  is reported against the recipe rather than surfacing later as an
  implausible case count
- [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
  writes at full numeric precision; effect estimates and p-values
  previously lost precision on the way into the manifest
- Every `derive_*()` returns invisibly, rather than depending on whether
  any case was found
- [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md),
  [`grs_bgen2pgen()`](https://evanbio.github.io/ukbflow/reference/grs_bgen2pgen.md),
  [`grs_score()`](https://evanbio.github.io/ukbflow/reference/grs_score.md)
  and
  [`job_path()`](https://evanbio.github.io/ukbflow/reference/job_path.md)
  now check for the RAP environment, as their siblings already did

------------------------------------------------------------------------

## ukbflow 0.3.4

CRAN release: 2026-04-08

*Released: April 2026*

### Bug Fixes

- All `test-integration-*.R` files now call `skip_on_cran()` at file
  scope, preventing integration tests from running on CRAN. Resolves
  CHECK ERROR on `r-devel-linux-x86_64-fedora-clang` and
  `r-devel-linux-x86_64-fedora-gcc` reported by CRAN on 2026-04-08.
- [`RNGkind()`](https://rdrr.io/r/base/Random.html) is now explicitly
  set before [`set.seed()`](https://rdrr.io/r/base/Random.html) in
  integration tests that use simulated data, ensuring cross-platform RNG
  reproducibility.

## ukbflow 0.3.3

CRAN release: 2026-04-07

*Released: April 2026*

### Bug Fixes

- [`grs_validate()`](https://evanbio.github.io/ukbflow/reference/grs_validate.md)
  — added `skip_if_not_installed("pROC")` guard to all logistic-path
  tests so the suite passes cleanly when `pROC` is absent

### Improvements

- Removed hardcoded default paths across all modules; examples
  refactored to use
  [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
  data where possible — runnable examples unwrapped, long-running
  examples (\>5s) wrapped in `\donttest{}`, network-dependent examples
  remain in `\dontrun{}`
- `VignetteBuilder` field corrected in `DESCRIPTION`

### CI

- R CMD check split into four targeted workflows: `dev` (3 jobs), `main`
  (6 jobs), `release` (8 jobs, `--as-cran`), and `weekly` (scheduled
  every Saturday 21:00 CST, full CRAN-like matrix)
- Added `_R_CHECK_DEPENDS_ONLY_` matrix to verify Suggests packages are
  correctly declared

### Documentation

- Rd files regenerated across all modules after example and parameter
  updates

------------------------------------------------------------------------

## ukbflow 0.3.2

*Released: March 26, 2026*

### Bug Fixes

- [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
  — removed Unicode character `Δ` from documentation to fix LaTeX PDF
  manual build on CRAN
- `test-plot.R` — added `skip_on_cran()` to
  [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  rendering tests that caused a 20-minute hang on Windows CRAN

### Improvements

- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  and
  [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  examples are now fully runnable (removed `\dontrun{}` wrapper;
  `save = FALSE` throughout)

### Documentation

- `README.md` — updated Codecov badge URL; fixed `CONTRIBUTING.md` and
  `README_zh.md` links to full GitHub URLs
- Added `inst/WORDLIST` with `Biobank` to suppress false-positive
  spelling NOTE on CRAN

------------------------------------------------------------------------

## ukbflow 0.3.1

*Released: March 25, 2026*

### Bug Fixes

- [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
  — coerce date columns to `IDate` before
  [`pmin()`](https://rdrr.io/r/base/Extremes.html) to avoid type
  mismatch
- `install.Rmd` — corrected vignette cross-references

### Improvements

- All modules hardened with consistent `.assert_*()` input validation
  helpers
- All
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
  calls now use `call = NULL` for cleaner error messages
- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  — auto-coerce `data.table` input to `data.frame`

### Documentation

- Man pages updated across all modules (auth, fetch, extract, job,
  decode, derive, ops, grs, assoc, plot)
- All vignettes reviewed and corrected (output format, param contracts,
  example accuracy)
- `get-started.Rmd` and `README` updated for accuracy
- pkgdown reference index and vignette menu completed

### Tests

- Test suites overhauled for all modules: added input validation
  coverage, integration-style stubs, and edge cases

------------------------------------------------------------------------

## ukbflow 0.3.0

*Released: March 13, 2026*

### New Features

#### Operations (ops\_\*)

- [`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
  — exclude UKB withdrawn participants from a cohort data.table by EID

#### Snapshot — Column Tracking

- [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
  gains column-tracking helpers: `cols()`,
  [`diff()`](https://rdrr.io/r/base/diff.html),
  [`remove()`](https://rdrr.io/r/base/rm.html), and `set_safe_cols()`

#### Visualisation Enhancements

- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  — new `png_scale`, `pdf_width`, and `pdf_height` parameters for
  fine-grained output control

### Bug Fixes

- `fetch_file()` — enforce RAP-only guard; updated tests
- [`grs_score()`](https://evanbio.github.io/ukbflow/reference/grs_score.md)
  — fix `-icmd` argument format; skip script upload if file already
  exists on RAP
- GRS pipeline — updated chr split threshold: chromosomes 1–16 use large
  instances, 17–22 use standard

### Documentation

- Added roxygen2 documentation for
  [`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
- Unit tests added for
  [`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)

### Internal

- Added `broom` to `DESCRIPTION` Imports and
  [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
  dependency check
- Updated package logo (new hex sticker design)
- Integration tests requiring RAP environment are now skipped in local
  CI

------------------------------------------------------------------------

## ukbflow 0.2.0

*Released: March 10, 2026*

### New Features

#### Operations (ops\_\*)

- [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
  — check and report the local environment (R, dx-toolkit, dxpy) health
- [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
  — generate synthetic UKB-style cohort or forest-plot data for testing
  and demos; includes GRS columns and cancer self-report fields
- [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md) —
  summarise missing-value rates per column with threshold-based
  filtering and `cli` progress feedback
- [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
  — record and display a history of dataset row/column counts across
  pipeline steps

### Bug Fixes

- All
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
  calls now pass `call = NULL` to suppress internal call-stack noise in
  error messages
- [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md):
  added cancer self-report fields (`p20001`, `p20006`) and corrected
  `sr_codes` → text label mapping

### Documentation

- New vignette: *Smoking and Lung Cancer — End-to-End Analysis*
  ([`vignette("smoking_lung_cancer")`](https://evanbio.github.io/ukbflow/articles/smoking_lung_cancer.md))
- New vignette: *ops\_* Series\* covering setup, toy data, NA summary,
  and snapshots
- pkgdown site now auto-deploys via GitHub Actions (CI-managed `docs/`)

### Internal

- Resolved R CMD check NOTEs: added `importFrom(stats, rnorm, runif)`,
  `importFrom(utils, object.size)`, and `pct_na` to
  [`globalVariables()`](https://rdrr.io/r/utils/globalVariables.html)
- Added `builds/` to `.Rbuildignore`

------------------------------------------------------------------------

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
- `fetch_file()` — download files from RAP to local
- `fetch_url()` — generate pre-signed download URLs
- `fetch_metadata()` — retrieve UKB field metadata (field.tsv,
  encoding.tsv)
- `fetch_field()` — download the UKB field dictionary file
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
