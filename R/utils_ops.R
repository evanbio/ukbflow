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
  # UKB coding 6: common non-cancer illness codes
  sr_codes <- c("1065", "1473", "1220", "1452", "1094", "1381", "1075", "1072")

  # Decreasing fill rate across array slots (a0 most populated)
  sr_fill <- c(0.30, 0.18, 0.10, 0.05, 0.02)

  sr_disease <- stats::setNames(
    lapply(sr_fill, function(p)
      ifelse(runif(n) < p, sample(sr_codes, n, replace = TRUE), NA_character_)
    ),
    paste0("p20002_i0_a", 0:4)
  )

  # Date: decimal year format e.g. 1995.5 (mid-year), NA-aligned with disease
  sr_dates <- stats::setNames(
    lapply(seq_along(sr_fill), function(i) {
      has_val <- !is.na(sr_disease[[i]])
      ifelse(has_val, sample(1975L:2010L, n, replace = TRUE) + 0.5, NA_real_)
    }),
    paste0("p20008_i0_a", 0:4)
  )

  # ── 6. HES (p41270 JSON + p41280_a0~a9) ──────────────────────────────────────
  icd10_hes     <- c("E11", "I10", "J45", "L20", "C44", "I25",
                     "N18", "F32", "K57", "M79", "I48", "G35")
  hes_has_rec   <- runif(n) < 0.35
  hes_date_span <- as.integer(as.Date("2020-12-31") - as.Date("1997-01-01"))

  p41270 <- sapply(seq_len(n), function(i) {
    if (!hes_has_rec[i]) return(NA_character_)
    codes <- sample(icd10_hes, sample(1:4, 1))
    paste0('["', paste(codes, collapse = '","'), '"]')
  })

  # p41280_a0~a9: dates aligned to HES record presence, sparser at higher index
  p41280 <- stats::setNames(
    lapply(0:9, function(i) {
      prob <- max(0.05, 0.40 - i * 0.04)
      ifelse(
        hes_has_rec & runif(n) < prob,
        format(as.Date("1997-01-01") + sample(0L:hes_date_span, n, replace = TRUE)),
        NA_character_
      )
    }),
    paste0("p41280_a", 0:9)
  )

  # ── 7. Cancer registry (i0 only) ─────────────────────────────────────────────
  icd10_cancer  <- c("C44", "C50", "C34", "C61", "C18", "C43", "C20", "C64")
  cancer_span   <- as.integer(as.Date("2020-12-31") - as.Date("1990-01-01"))
  cancer_flag   <- runif(n) < 0.05

  p40006_i0 <- ifelse(cancer_flag, sample(icd10_cancer, n, replace = TRUE), NA_character_)
  p40005_i0 <- ifelse(
    cancer_flag,
    format(as.Date("1990-01-01") + sample(0L:cancer_span, n, replace = TRUE)),
    NA_character_
  )

  # ── 8. Death registry (i0 only) ──────────────────────────────────────────────
  icd10_death <- c("I21.9", "C34.9", "I25.9", "C50.9", "C61",
                   "I64",   "C25.9", "I48.0", "C18.9")
  death_span  <- as.integer(as.Date("2023-12-31") - as.Date("2006-01-01"))
  death_flag  <- runif(n) < 0.10

  p40001_i0    <- ifelse(death_flag, sample(icd10_death, n, replace = TRUE), NA_character_)
  p40002_i0_a0 <- ifelse(
    death_flag & runif(n) < 0.30, sample(icd10_death, n, replace = TRUE), NA_character_
  )
  p40002_i0_a1 <- ifelse(
    death_flag & runif(n) < 0.10, sample(icd10_death, n, replace = TRUE), NA_character_
  )
  p40000_i0 <- ifelse(
    death_flag,
    format(as.Date("2006-01-01") + sample(0L:death_span, n, replace = TRUE)),
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

  # ── 10. Messy columns (robustness testing) ────────────────────────────────────
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

  dt[, p41270 := p41270]
  dt <- cbind(dt, data.table::as.data.table(p41280))

  dt[, `:=`(p40006_i0 = p40006_i0, p40005_i0 = p40005_i0)]

  dt[, `:=`(
    p40001_i0    = p40001_i0,
    p40002_i0_a0 = p40002_i0_a0,
    p40002_i0_a1 = p40002_i0_a1,
    p40000_i0    = p40000_i0
  )]

  dt[, p131742 := p131742]

  dt[, `:=`(
    messy_allna = messy_allna,
    messy_empty = messy_empty,
    messy_label = messy_label
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
