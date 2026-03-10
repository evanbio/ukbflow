# =============================================================================
# utils_ops.R — Internal helpers for ops_ series
# =============================================================================


# ── ops_toy helpers ───────────────────────────────────────────────────────────

#' Generate toy cohort data (UKB-like phenotype table)
#'
#' @param n (integer) Number of participants.
#' @return A data.table with UKB-style column names.
#' @keywords internal
#' @noRd
.ops_toy_cohort <- function(n) {

  # ── 1. Identity ──────────────────────────────────────────────────────────────
  eid <- seq(10000001L, by = 1L, length.out = n)

  # ── 2. Demographics ──────────────────────────────────────────────────────────
  p31 <- sample(c("Female", "Male"), n, replace = TRUE, prob = c(0.54, 0.46))
  p34 <- sample(1930L:1980L, n, replace = TRUE)

  baseline_days <- as.integer(as.Date("2010-12-31") - as.Date("2006-01-01"))
  p53_i0 <- format(
    as.Date("2006-01-01") + sample(0L:baseline_days, n, replace = TRUE)
  )
  p21022 <- sample(30L:80L, n, replace = TRUE)

  # ── 3. Anthropometrics & Lifestyle ───────────────────────────────────────────
  # BMI: similar distribution but not identical to real UKB
  p21001_i0 <- round(pmax(12, pmin(65, rnorm(n, mean = 26.2, sd = 5.5))), 4L)

  # Smoking: label-valued, proportions vary with seed
  p20116_i0 <- sample(
    c("Never", "Previous", "Current", "Prefer not to answer"),
    n, replace = TRUE, prob = c(0.52, 0.31, 0.14, 0.03)
  )

  # Alcohol: label-valued
  p1558_i0 <- sample(
    c("Daily or almost daily", "Three or four times a week",
      "Once or twice a week",  "One to three times a month",
      "Special occasions only", "Never", "Prefer not to answer"),
    n, replace = TRUE, prob = c(0.08, 0.21, 0.28, 0.17, 0.14, 0.09, 0.03)
  )

  # Ethnicity: simplified broad categories
  p21000_i0 <- sample(
    c("White", "Asian", "Black", "Mixed", "Other"),
    n, replace = TRUE, prob = c(0.87, 0.06, 0.02, 0.02, 0.03)
  )

  # Townsend deprivation index: approx N(-1.3, 3.2), clipped
  p22189 <- round(pmax(-7, pmin(12, rnorm(n, mean = -1.3, sd = 3.2))), 2L)

  # Assessment centre: subset of common UK sites
  p54_i0 <- sample(
    c("Leeds", "Manchester", "Edinburgh", "Bristol", "Birmingham",
      "Oxford", "Newcastle", "Nottingham", "Liverpool", "Sheffield"),
    n, replace = TRUE
  )

  # ── 4. Genetic PCs (p22009_a1 ~ p22009_a10) ──────────────────────────────────
  pc_mat  <- matrix(round(rnorm(n * 10L), 6L), nrow = n)
  pc_cols <- stats::setNames(
    as.data.frame(pc_mat), paste0("p22009_a", 1:10)
  )

  # ── 5. Self-report disease (i0, a0~a4) ───────────────────────────────────────
  # UKB coding 6: non-cancer illness text labels (as exported from RAP)
  sr_codes <- c(
    "hypertension", "type 2 diabetes", "asthma", "back problem",
    "thyroid problem (not cancer)", "fracture", "joint disorder",
    "heart attack/myocardial infarction"
  )

  # Decreasing fill rate across array slots (a0 most populated)
  sr_fill <- c(0.30, 0.18, 0.10, 0.05, 0.02)

  sr_disease <- stats::setNames(
    lapply(sr_fill, function(p)
      ifelse(runif(n) < p, sample(sr_codes, n, replace = TRUE), NA_character_)
    ),
    paste0("p20002_i0_a", 0:4)
  )

  # Date: decimal year format e.g. 2005.5 (mid-year), NA-aligned with disease
  # Reason: keep most self-report dates post-2000 so incident cases dominate
  sr_dates <- stats::setNames(
    lapply(seq_along(sr_fill), function(i) {
      has_val <- !is.na(sr_disease[[i]])
      ifelse(has_val, sample(2000L:2015L, n, replace = TRUE) + 0.5, NA_real_)
    }),
    paste0("p20008_i0_a", 0:4)
  )

  # ── 5b. Self-report cancer (p20001 i0 a0~a4, p20006 i0 a0~a4) ───────────────
  # UKB coding 3: cancer illness text labels (as exported from RAP)
  sc_codes <- c(
    "lung cancer", "breast cancer", "bladder cancer",
    "malignant melanoma", "non-melanoma skin cancer",
    "lymphoma", "thyroid cancer", "kidney/renal cell cancer"
  )

  # Lower fill rate than non-cancer; decreasing across array slots
  sc_fill <- c(0.05, 0.03, 0.015, 0.008, 0.003)

  sc_disease <- stats::setNames(
    lapply(sc_fill, function(p)
      ifelse(runif(n) < p, sample(sc_codes, n, replace = TRUE), NA_character_)
    ),
    paste0("p20001_i0_a", 0:4)
  )

  # Decimal year format, NA-aligned with disease — same convention as p20008
  sc_dates <- stats::setNames(
    lapply(seq_along(sc_fill), function(i) {
      has_val <- !is.na(sc_disease[[i]])
      ifelse(has_val, sample(2000L:2015L, n, replace = TRUE) + 0.5, NA_real_)
    }),
    paste0("p20006_i0_a", 0:4)
  )

  # ── 6. HES (p41270 JSON + p41280_a0~a9) ──────────────────────────────────────
  icd10_hes     <- c("E11", "I10", "J45", "L20", "C44", "I25",
                     "N18", "F32", "K57", "M79", "I48", "G35")
  hes_has_rec   <- runif(n) < 0.35
  hes_date_span <- as.integer(as.Date("2022-12-31") - as.Date("2000-01-01"))

  # Reason: build p41270 and p41280 together so code count and dates are
  # index-aligned — every code at position k gets a date in p41280_ak.
  hes_records <- lapply(seq_len(n), function(i) {
    if (!hes_has_rec[i]) return(list(json = NA_character_, dates = rep(NA_character_, 9L)))
    k     <- sample(1:4, 1)
    codes <- sample(icd10_hes, k)
    dates <- format(as.Date("2000-01-01") + sample(0L:hes_date_span, k, replace = TRUE))
    list(
      json  = paste0('["', paste(codes, collapse = '","'), '"]'),
      dates = c(dates, rep(NA_character_, 9L - k))   # pad to length 9
    )
  })

  p41270 <- vapply(hes_records, `[[`, character(1), "json")

  p41280 <- stats::setNames(
    lapply(0:8, function(i)
      vapply(hes_records, function(r) r$dates[i + 1L], character(1))
    ),
    paste0("p41280_a", 0:8)
  )

  # ── 7. Cancer registry (i0~i2, 3 instances) ──────────────────────────────────
  icd10_cancer <- c("C44", "C50", "C34", "C61", "C18", "C43", "C20", "C64")
  hist_codes   <- c(8090L, 8140L, 8500L, 8070L, 8010L, 8743L, 8130L, 8520L, 8000L, 8720L)
  behv_codes   <- c(3L, 3L, 3L, 3L, 3L, 3L, 3L, 2L, 2L, 1L, 0L, 6L, 5L, 9L)  # 3=malignant ~85%
  cancer_span  <- as.integer(as.Date("2020-12-31") - as.Date("1990-01-01"))

  # Decreasing prevalence across instances
  cancer_prob <- c(0.05, 0.02, 0.008)

  cancer_cols <- lapply(seq_along(cancer_prob), function(i) {
    flag <- runif(n) < cancer_prob[i]
    list(
      icd  = ifelse(flag, sample(icd10_cancer, n, replace = TRUE), NA_character_),
      hist = ifelse(flag, sample(hist_codes,   n, replace = TRUE), NA_integer_),
      behv = ifelse(flag, sample(behv_codes,   n, replace = TRUE), NA_integer_),
      date = ifelse(flag,
        format(as.Date("1990-01-01") + sample(0L:cancer_span, n, replace = TRUE)),
        NA_character_)
    )
  })

  # ── 8. Death registry (i0, 3 contributory causes) ────────────────────────────
  icd10_death <- c("I21.9", "C34.9", "I25.9", "C50.9", "C61",
                   "I64",   "C25.9", "I48.0", "C18.9")
  death_span  <- as.integer(as.Date("2023-12-31") - as.Date("2011-01-01"))
  death_flag  <- runif(n) < 0.10

  p40001_i0    <- ifelse(death_flag, sample(icd10_death, n, replace = TRUE), NA_character_)
  p40002_i0_a0 <- ifelse(death_flag & runif(n) < 0.30, sample(icd10_death, n, replace = TRUE), NA_character_)
  p40002_i0_a1 <- ifelse(death_flag & runif(n) < 0.15, sample(icd10_death, n, replace = TRUE), NA_character_)
  p40002_i0_a2 <- ifelse(death_flag & runif(n) < 0.05, sample(icd10_death, n, replace = TRUE), NA_character_)
  p40000_i0 <- ifelse(
    death_flag,
    format(as.Date("2011-01-01") + sample(0L:death_span, n, replace = TRUE)),
    NA_character_
  )

  # ── 9. First occurrence (p131742) ────────────────────────────────────────────
  # Reason: representative first-occurrence date field used by derive_first_occurrence
  fo_span <- as.integer(as.Date("2022-12-31") - as.Date("1995-01-01"))
  p131742 <- ifelse(
    runif(n) < 0.08,
    format(as.Date("1995-01-01") + sample(0L:fo_span, n, replace = TRUE)),
    NA_character_
  )

  # ── 10. GRS columns (raw, unstandardised — for testing grs_standardize()) ────
  grs_bmi     <- round(rnorm(n, mean = 0.82, sd = 2.5), 6L)
  grs_raw     <- round(rnorm(n, mean = 1.54, sd = 3.5), 6L)
  grs_finngen <- round(rnorm(n, mean = 0.41, sd = 1.8), 6L)

  # ── 11. Messy columns (robustness testing) ────────────────────────────────────
  # Reason: stress-test derive_missing and decode_ against real data quality issues
  messy_allna <- rep(NA_character_, n)
  messy_empty <- ifelse(runif(n) < 0.5, "", NA_character_)
  messy_label <- sample(
    c("#N/A", "N/A", "-1", "999", ".", "unknown", "NULL", NA_character_),
    n, replace = TRUE, prob = c(0.05, 0.05, 0.08, 0.08, 0.05, 0.05, 0.04, 0.60)
  )

  # ── Assemble ──────────────────────────────────────────────────────────────────
  dt <- data.table::data.table(
    eid       = eid,
    p31       = p31,       p34       = p34,
    p53_i0    = p53_i0,    p21022    = p21022,
    p21001_i0 = p21001_i0, p20116_i0 = p20116_i0,
    p1558_i0  = p1558_i0,  p21000_i0 = p21000_i0,
    p22189    = p22189,    p54_i0    = p54_i0
  )

  dt <- cbind(dt, data.table::as.data.table(pc_cols))
  dt <- cbind(dt, data.table::as.data.table(sr_disease), data.table::as.data.table(sr_dates))
  dt <- cbind(dt, data.table::as.data.table(sc_disease), data.table::as.data.table(sc_dates))

  dt[, p41270 := p41270]
  dt <- cbind(dt, data.table::as.data.table(p41280))

  # Cancer: 3 instances × 4 fields (icd, hist, behv, date)
  for (i in seq_along(cancer_cols)) {
    idx <- i - 1L
    dt[, (paste0("p40006_i", idx)) := cancer_cols[[i]]$icd ]
    dt[, (paste0("p40011_i", idx)) := cancer_cols[[i]]$hist]
    dt[, (paste0("p40012_i", idx)) := cancer_cols[[i]]$behv]
    dt[, (paste0("p40005_i", idx)) := cancer_cols[[i]]$date]
  }

  dt[, `:=`(
    p40001_i0    = p40001_i0,
    p40002_i0_a0 = p40002_i0_a0,
    p40002_i0_a1 = p40002_i0_a1,
    p40002_i0_a2 = p40002_i0_a2,
    p40000_i0    = p40000_i0
  )]

  dt[, p131742 := p131742]

  dt[, `:=`(
    grs_bmi     = grs_bmi,
    grs_raw     = grs_raw,
    grs_finngen = grs_finngen
  )]

  dt[, `:=`(
    messy_allna = messy_allna,
    messy_empty = messy_empty,
    messy_label = messy_label
  )]

  dt
}


#' Generate toy forest plot data (assoc_coxph-style results table)
#'
#' @param n (integer) Number of exposures. Default 8L.
#' @return A data.table matching the output structure of assoc_coxph().
#' @keywords internal
#' @noRd
.ops_toy_forest <- function(n = 8L) {

  exposures <- c(
    "bmi", "smoking_ex", "smoking_current", "alcohol_freq",
    "townsend_deprivation", "age_at_recruitment", "ethnicity_asian",
    "ethnicity_black", "physical_activity", "sleep_duration"
  )[seq_len(min(n, 10L))]

  models <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")

  # Generate one row per exposure × model
  rows <- lapply(exposures, function(exp) {
    # Each exposure gets a "true" log-HR drawn from a realistic range
    log_hr_true <- rnorm(1, mean = 0.05, sd = 0.25)

    lapply(models, function(mod) {
      # SE shrinks with adjustment (wider CI for unadjusted)
      se <- switch(mod,
        "Unadjusted"           = runif(1, 0.03, 0.10),
        "Age and sex adjusted" = runif(1, 0.03, 0.09),
        "Fully adjusted"       = runif(1, 0.03, 0.08)
      )
      hr       <- exp(log_hr_true + rnorm(1, 0, se * 0.2))
      ci_lower <- exp(log(hr) - 1.96 * se)
      ci_upper <- exp(log(hr) + 1.96 * se)
      z        <- log(hr) / se
      p_val    <- 2 * stats::pnorm(-abs(z))

      list(
        exposure     = exp,
        term         = exp,
        model        = mod,
        n            = sample(40000L:500000L, 1L),
        n_events     = sample(500L:20000L, 1L),
        person_years = round(runif(1, 3e5, 7e6), 0),
        HR           = round(hr, 6L),
        CI_lower     = round(ci_lower, 6L),
        CI_upper     = round(ci_upper, 6L),
        p_value      = round(p_val, 6L),
        HR_label     = sprintf("%.2f (%.2f-%.2f)", hr, ci_lower, ci_upper)
      )
    })
  })

  dt <- data.table::rbindlist(unlist(rows, recursive = FALSE))

  # model as ordered factor — matches assoc_coxph output
  dt[, model := factor(model,
    levels  = c("Unadjusted", "Age and sex adjusted", "Fully adjusted"),
    ordered = TRUE
  )]

  dt
}


#' Check dx CLI installation
#'
#' @return Named list: ok, path, version.
#' @keywords internal
#' @noRd
.ops_check_dx <- function() {
  path <- Sys.which("dx")
  if (!nzchar(path)) {
    return(list(ok = FALSE, path = NA_character_, version = NA_character_))
  }

  ver_res <- processx::run(
    command          = unname(path),
    args             = "--version",
    error_on_status  = FALSE
  )
  version <- trimws(ver_res$stdout)
  if (!nzchar(version)) version <- trimws(ver_res$stderr)

  list(ok = TRUE, path = unname(path), version = version)
}


#' Check RAP authentication status
#'
#' @return Named list: ok, logged_in, user, project.
#' @keywords internal
#' @noRd
.ops_check_auth <- function() {
  # Guard: if dx is not on PATH, skip silently
  if (!nzchar(Sys.which("dx"))) {
    return(list(ok = FALSE, logged_in = FALSE, user = NA_character_, project = NA_character_))
  }

  whoami <- .dx_run(c("whoami"))
  if (!whoami$success) {
    return(list(ok = FALSE, logged_in = FALSE, user = NA_character_, project = NA_character_))
  }

  project <- .dx_get_project_id()
  list(
    ok        = TRUE,
    logged_in = TRUE,
    user      = whoami$stdout,
    project   = project
  )
}


#' Check R package dependencies
#'
#' Returns a list of check results for all Imports and key Suggests.
#'
#' @return A list of named lists, each with: package, required, group,
#'   installed, version.
#' @keywords internal
#' @noRd
.ops_check_deps <- function() {
  # Each entry: package name, required (TRUE = Imports), module group label
  deps <- list(
    # Core
    list(pkg = "cli",          required = TRUE,  group = "core"),
    list(pkg = "data.table",   required = TRUE,  group = "core"),
    list(pkg = "processx",     required = TRUE,  group = "core"),
    list(pkg = "rlang",        required = TRUE,  group = "core"),
    list(pkg = "tools",        required = TRUE,  group = "core"),
    # Extract / Fetch
    list(pkg = "curl",         required = TRUE,  group = "extract / fetch"),
    list(pkg = "jsonlite",     required = TRUE,  group = "extract / fetch"),
    # Analysis
    list(pkg = "survival",     required = TRUE,  group = "assoc_coxph"),
    list(pkg = "dplyr",        required = TRUE,  group = "assoc / derive"),
    list(pkg = "tidyselect",   required = TRUE,  group = "assoc / derive"),
    # Visualisation
    list(pkg = "forestploter", required = TRUE,  group = "plot_forest"),
    list(pkg = "broom",        required = TRUE,  group = "plot_tableone"),
    list(pkg = "gt",           required = TRUE,  group = "plot_tableone"),
    list(pkg = "gtsummary",    required = TRUE,  group = "plot_tableone"),
    # Optional / Suggests
    list(pkg = "pROC",         required = FALSE, group = "assoc (optional)"),
    list(pkg = "knitr",        required = FALSE, group = "vignettes"),
    list(pkg = "rmarkdown",    required = FALSE, group = "vignettes")
  )

  lapply(deps, function(d) {
    inst    <- requireNamespace(d$pkg, quietly = TRUE)
    version <- if (inst) as.character(utils::packageVersion(d$pkg)) else NA_character_
    list(
      package   = d$pkg,
      required  = d$required,
      group     = d$group,
      installed = inst,
      version   = version
    )
  })
}
