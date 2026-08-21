# Package index

## Authentication

Connect to the UK Biobank Research Analysis Platform (RAP) and manage
project selection.

- [`auth_list_projects()`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md)
  : List available DNAnexus projects
- [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)
  : Login to DNAnexus with a token
- [`auth_logout()`](https://evanbio.github.io/ukbflow/reference/auth_logout.md)
  : Logout from DNAnexus
- [`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md)
  : Select a DNAnexus project
- [`auth_status()`](https://evanbio.github.io/ukbflow/reference/auth_status.md)
  : Check current DNAnexus authentication status

## Fetch — RAP File System

Browse and list files in RAP project storage.

- [`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md)
  : List files and folders at a remote RAP path
- [`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)
  : Print a remote RAP directory tree

## Extract — Phenotype Data

Extract UKB fields from the RAP dataset into R.

- [`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
  : List all approved fields in the UKB dataset
- [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
  : Extract phenotype data from a UKB dataset
- [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
  : Submit a large-scale phenotype extraction job via table-exporter
- [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md)
  : Extract a UK Biobank primary-care (GP) record table
- [`extract_olink()`](https://evanbio.github.io/ukbflow/reference/extract_olink.md)
  : Export the UK Biobank Olink proteomics data
- [`extract_nmr()`](https://evanbio.github.io/ukbflow/reference/extract_nmr.md)
  : Export the UK Biobank Nightingale NMR metabolomics data

## Decode — Column Names and Values

Convert raw UKB column names and coded values to human-readable labels.

- [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
  : Rename UKB field ID columns to human-readable snake_case names
- [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
  : Decode UKB categorical column values using Showcase metadata

## Derive — Disease Phenotypes

Build case definitions from HES, cancer registry, self-report, First
Occurrence, death registry, and algorithmically-defined outcomes.

- [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
  : Define a self-reported phenotype from UKB touchscreen data
- [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
  : Derive a binary disease flag from UKB HES inpatient diagnoses
- [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md)
  : Derive a binary disease flag from UKB HES inpatient diagnoses
  (ICD-9)
- [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md)
  : Derive a binary procedure flag from UKB HES operative procedures
  (OPCS-4)
- [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
  : Derive a disease flag from GP clinical events (Read v2)
- [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md)
  : Derive a disease flag from GP clinical events (CTV3 / Read v3)
- [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
  : Derive a binary disease flag from UKB cancer registry
- [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md)
  : Derive a binary disease flag from UKB cancer registry (ICD-9)
- [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
  : Derive a binary disease flag from UKB death registry
- [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md)
  : Derive a binary disease flag from UKB First Occurrence fields
- [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md)
  : Derive a binary disease flag from UKB algorithmically-defined
  outcomes
- [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
  : Derive a unified ICD-10 disease flag across multiple UKB data
  sources
- [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)
  : Derive a unified ICD-9 disease flag across multiple UKB data sources
- [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
  : Combine per-source flags into a unified case definition
- [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
  : Apply a phenotype recipe to UKB data

## Derive — Covariates and Timing

Derive continuous covariates, categorical cuts, follow-up time, and
event timing variables.

- [`derive_covariate()`](https://evanbio.github.io/ukbflow/reference/derive_covariate.md)
  : Prepare UKB covariates for analysis
- [`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
  : Cut a continuous UKB variable into quantile-based or custom groups
- [`derive_missing()`](https://evanbio.github.io/ukbflow/reference/derive_missing.md)
  : Handle informative missing labels in UKB decoded data
- [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md)
  : Compute age at event for one or more UKB outcomes
- [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
  : Compute follow-up end date and follow-up time for survival analysis
- [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
  : Classify disease timing relative to UKB baseline assessment

## Jobs — Monitoring and Retrieval

Submit, monitor, and retrieve results from RAP extraction jobs.

- [`job_ls()`](https://evanbio.github.io/ukbflow/reference/job_ls.md) :
  List recent DNAnexus jobs in the current project
- [`job_path()`](https://evanbio.github.io/ukbflow/reference/job_path.md)
  : Get the RAP file path of a completed DNAnexus job output
- [`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md)
  : Load the result of a completed DNAnexus job into R
- [`job_status()`](https://evanbio.github.io/ukbflow/reference/job_status.md)
  : Check the current state of a DNAnexus job
- [`job_wait()`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
  : Wait for a DNAnexus job to finish

## Association Analysis

Fit regression models for UKB outcomes with automatic three-model
adjustment framework.

- [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  [`assoc_cox()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  : Cox proportional hazards association analysis
- [`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  [`assoc_logit()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  : Logistic regression association analysis
- [`assoc_linear()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
  [`assoc_lm()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
  : Linear regression association analysis
- [`assoc_coxph_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md)
  [`assoc_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md)
  : Proportional hazards assumption test for Cox regression
- [`assoc_subgroup()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md)
  [`assoc_sub()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md)
  : Subgroup association analysis with optional interaction test
- [`assoc_trend()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
  [`assoc_tr()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
  : Dose-response trend analysis
- [`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md)
  : Restricted cubic spline dose-response analysis
- [`assoc_competing()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md)
  [`assoc_fg()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md)
  : Fine-Gray competing risks association analysis
- [`assoc_lag()`](https://evanbio.github.io/ukbflow/reference/assoc_lag.md)
  : Cox regression lag sensitivity analysis
- [`assoc_evalue()`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md)
  : E-value for unmeasured confounding

## GRS — Genetic Risk Scores

End-to-end RAP-native pipeline for computing and validating polygenic
risk scores with plink2.

- [`grs_check()`](https://evanbio.github.io/ukbflow/reference/grs_check.md)
  : Check and export a GRS weights file
- [`grs_bgen2pgen()`](https://evanbio.github.io/ukbflow/reference/grs_bgen2pgen.md)
  : Convert UKB imputed BGEN files to PGEN on RAP
- [`grs_score()`](https://evanbio.github.io/ukbflow/reference/grs_score.md)
  : Calculate genetic risk scores from PGEN files on RAP
- [`grs_standardize()`](https://evanbio.github.io/ukbflow/reference/grs_standardize.md)
  [`grs_zscore()`](https://evanbio.github.io/ukbflow/reference/grs_standardize.md)
  : Standardise GRS columns by Z-score transformation
- [`grs_validate()`](https://evanbio.github.io/ukbflow/reference/grs_validate.md)
  : Validate GRS predictive performance

## Utilities & Diagnostics

Environment checks, field discovery, First Occurrence and
algorithmically-defined outcome lookups, covariate presets, synthetic
data generation, missing-value summaries, pipeline snapshots, and cohort
management.

- [`ops_setup()`](https://evanbio.github.io/ukbflow/reference/ops_setup.md)
  : Check the ukbflow operating environment
- [`ops_fields()`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
  : Search approved UKB fields in the current project
- [`ops_fields_common()`](https://evanbio.github.io/ukbflow/reference/ops_fields_common.md)
  : Common UK Biobank fields for quick reference
- [`ops_fo()`](https://evanbio.github.io/ukbflow/reference/ops_fo.md) :
  First Occurrence health outcome fields (offline lookup)
- [`ops_alg()`](https://evanbio.github.io/ukbflow/reference/ops_alg.md)
  : Algorithmically-defined outcome fields (offline lookup)
- [`ops_covariates()`](https://evanbio.github.io/ukbflow/reference/ops_covariates.md)
  : Common covariate presets for UK Biobank analysis
- [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
  : Generate toy UKB-like data for testing and development
- [`ops_na()`](https://evanbio.github.io/ukbflow/reference/ops_na.md) :
  Summarise missing values by column
- [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
  : Record and review dataset pipeline snapshots
- [`ops_snapshot_cols()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md)
  : Retrieve column names recorded at a snapshot
- [`ops_snapshot_diff()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_diff.md)
  : Compare column names between two snapshots
- [`ops_snapshot_remove()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_remove.md)
  : Remove raw source columns recorded at a snapshot
- [`ops_set_safe_cols()`](https://evanbio.github.io/ukbflow/reference/ops_set_safe_cols.md)
  : Register additional safe columns protected from snapshot-based drops
- [`ops_withdraw()`](https://evanbio.github.io/ukbflow/reference/ops_withdraw.md)
  : Exclude withdrawn participants from a dataset

## Phenotype Recipes

A versioned library of reproducible UK Biobank phenotype definitions:
browse the library, inspect a definition, and flatten it to a tidy rule
table. Authoring helpers build and save a definition without
hand-writing YAML. To apply a recipe to data, see derive_recipe() under
“Derive — Disease Phenotypes”.

- [`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
  : List available phenotype recipes
- [`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
  [`print(`*`<ukbflow_recipe>`*`)`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
  : Retrieve a single phenotype recipe
- [`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md)
  : Flatten a recipe's source rules into a table
- [`recipe_rule()`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md)
  : Build one source rule for a recipe
- [`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
  : Build a phenotype recipe
- [`recipe_write()`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)
  : Write a recipe to a YAML file

## Analysis Audit

Lightweight analysis manifests for fields, data snapshots, derived
phenotypes, phenotype recipes, model results, and session metadata.

- [`audit_start()`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
  [`print(`*`<ukbflow_audit>`*`)`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
  [`summary(`*`<ukbflow_audit>`*`)`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
  : Start a ukbflow audit record
- [`audit_fields()`](https://evanbio.github.io/ukbflow/reference/audit_fields.md)
  : Record UKB field IDs used for extraction
- [`audit_snapshot()`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
  : Record a data snapshot in a ukbflow audit object
- [`audit_cols()`](https://evanbio.github.io/ukbflow/reference/audit_cols.md)
  : Retrieve column names from an audit snapshot
- [`audit_pheno()`](https://evanbio.github.io/ukbflow/reference/audit_pheno.md)
  : Record a derived phenotype audit summary
- [`audit_recipe()`](https://evanbio.github.io/ukbflow/reference/audit_recipe.md)
  : Record a phenotype recipe in an audit manifest
- [`audit_model()`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
  : Record an association model result
- [`audit_job()`](https://evanbio.github.io/ukbflow/reference/audit_job.md)
  : Record a DNAnexus job in an audit manifest
- [`audit_write()`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
  : Write a ukbflow audit manifest
- [`audit_read()`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
  : Read a ukbflow audit manifest back into a ukbflow_audit object
- [`audit_diff()`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
  : Compare recorded audit entries along a chosen sequence, or two audit
  objects as a whole
- [`audit_flowchart()`](https://evanbio.github.io/ukbflow/reference/audit_flowchart.md)
  : Export a cohort flowchart table from recorded snapshots

## Visualisation

Publication-quality forest plots, Kaplan-Meier curves, and Table 1 for
manuscripts.

- [`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md)
  : Publication-ready forest plot
- [`plot_survival()`](https://evanbio.github.io/ukbflow/reference/plot_survival.md)
  : Publication-ready Kaplan-Meier survival plot
- [`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md)
  : Plot a restricted cubic spline dose-response curve
- [`plot_tableone()`](https://evanbio.github.io/ukbflow/reference/plot_tableone.md)
  : Publication-ready Table 1 (Baseline Characteristics)
