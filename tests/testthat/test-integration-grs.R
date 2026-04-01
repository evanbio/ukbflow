# =============================================================================
# test-integration-grs.R — Integration tests for grs_ series
# Fixture: ops_toy(n=2000, seed=42) + simulated GRS raw scores
# Mirrors the style of test-integration-derive.R.
# Run manually before release: devtools::test(filter = "integration-grs")
# =============================================================================

# =============================================================================
# Shared fixture
# =============================================================================

DT <- suppressMessages(ops_toy(n = 2000L, seed = 42L))

# Simulate two raw GRS scores correlated with a latent signal
set.seed(42L)
N          <- nrow(DT)
grs_signal <- rnorm(N)

DT[, GRS_a := grs_signal + rnorm(N, sd = 0.5)]
DT[, GRS_b := grs_signal + rnorm(N, sd = 0.8)]

# Binary outcome correlated with GRS signal (~15% event rate)
DT[, outcome := as.integer(
  plogis(-2.5 + 0.4 * grs_signal + rnorm(N, sd = 0.5)) > runif(N)
)]

# Follow-up time from baseline (p53_i0) to admin censor date
CENSOR <- as.Date("2022-06-01")
DT[, followup_years := as.numeric(
  difftime(CENSOR, as.Date(p53_i0), units = "days") / 365.25
)]

# Covariates available from ops_toy
COVS <- c("p21022", "p31", "p22189")  # age at recruitment, sex, TDI


# =============================================================================
# grs_check() — integration
# =============================================================================

test_that("grs_check() round-trips: writes and the output is plink2-ready", {
  input <- withr::local_tempfile(fileext = ".csv")
  dest  <- withr::local_tempfile(fileext = ".txt")

  data.table::fwrite(
    data.table::data.table(
      snp           = paste0("rs", 1:20),
      effect_allele = sample(c("A", "T", "C", "G"), 20, TRUE),
      beta          = rnorm(20, 0, 0.3)
    ),
    input
  )

  result <- suppressMessages(grs_check(input, dest = dest))

  expect_true(file.exists(dest))
  out_dt <- data.table::fread(dest)
  expect_equal(ncol(out_dt), 3L)
  expect_equal(nrow(out_dt), 20L)
  expect_equal(nrow(result), 20L)
  expect_true(is.numeric(result$beta))
})

test_that("grs_check() normalises lowercase effect_allele to uppercase", {
  input <- withr::local_tempfile(fileext = ".csv")
  dest  <- withr::local_tempfile(fileext = ".txt")

  data.table::fwrite(
    data.table::data.table(
      snp           = paste0("rs", 1:3),
      effect_allele = c("a", "t", "c"),
      beta          = c(0.1, 0.2, 0.3)
    ),
    input
  )

  result <- suppressMessages(grs_check(input, dest = dest))
  expect_true(all(result$effect_allele %in% c("A", "T", "C", "G")))
})


# =============================================================================
# grs_standardize() — integration with ops_toy GRS columns
# =============================================================================

test_that("grs_standardize() produces z-scores with mean≈0 and SD≈1 on ops_toy data", {
  out <- suppressMessages(
    grs_standardize(DT, grs_cols = c("GRS_a", "GRS_b"))
  )

  for (col in c("GRS_a_z", "GRS_b_z")) {
    v <- out[[col]]
    expect_lt(abs(mean(v, na.rm = TRUE)), 1e-10)
    expect_lt(abs(sd(v,   na.rm = TRUE) - 1), 1e-10)
  }
})

test_that("grs_standardize() auto-detects both GRS columns from ops_toy data", {
  out <- suppressMessages(grs_standardize(DT))
  expect_true("GRS_a_z" %in% names(out))
  expect_true("GRS_b_z" %in% names(out))
})

test_that("grs_standardize() adds exactly 2 columns for 2 GRS inputs", {
  out <- suppressMessages(
    grs_standardize(DT, grs_cols = c("GRS_a", "GRS_b"))
  )
  expect_equal(ncol(out), ncol(DT) + 2L)
})

test_that("grs_standardize() inserts _z column immediately after source column", {
  out     <- suppressMessages(grs_standardize(DT, grs_cols = "GRS_a"))
  idx_src <- which(names(out) == "GRS_a")
  idx_z   <- which(names(out) == "GRS_a_z")
  expect_equal(idx_z, idx_src + 1L)
})

test_that("grs_standardize() does not modify original GRS_a column in ops_toy", {
  orig_a <- DT$GRS_a
  suppressMessages(grs_standardize(DT, grs_cols = "GRS_a"))
  expect_equal(DT$GRS_a, orig_a)
})


# =============================================================================
# grs_validate() helpers — standardize first, then validate
# =============================================================================

# Pre-standardize GRS columns once for downstream validate tests
DT_Z <- suppressMessages(
  grs_standardize(DT, grs_cols = c("GRS_a", "GRS_b"))
)


# =============================================================================
# grs_validate() — logistic (time_col = NULL)
# =============================================================================

test_that("grs_validate() logistic runs without error on ops_toy n=2000", {
  skip_if_not_installed("pROC")
  expect_no_error(suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  )))
})

test_that("grs_validate() logistic per_sd has positive OR and valid CI", {
  skip_if_not_installed("pROC")
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  ))
  expect_true(all(res$per_sd$OR > 0))
  expect_true(all(res$per_sd$CI_lower < res$per_sd$OR))
  expect_true(all(res$per_sd$OR       < res$per_sd$CI_upper))
})

test_that("grs_validate() logistic high_vs_low contains only High rows", {
  skip_if_not_installed("pROC")
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  ))
  expect_true(all(grepl("High$", res$high_vs_low$term)))
})

test_that("grs_validate() logistic AUC is in [0.5, 1] with real GRS signal", {
  skip_if_not_installed("pROC")
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome")
  ))
  expect_gte(res$discrimination$AUC, 0.5)
  expect_lte(res$discrimination$AUC, 1.0)
})

test_that("grs_validate() logistic with covariates adds fully adjusted model", {
  skip_if_not_installed("pROC")
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome",
                 covariates  = COVS)
  ))
  expect_true("Fully adjusted" %in% as.character(res$per_sd$model))
})


# =============================================================================
# grs_validate() — Cox (time_col supplied)
# =============================================================================

test_that("grs_validate() Cox runs without error on ops_toy n=2000", {
  expect_no_error(suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  )))
})

test_that("grs_validate() Cox per_sd has positive HR and valid CI", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_true(all(res$per_sd$HR > 0))
  expect_true(all(res$per_sd$CI_lower < res$per_sd$HR))
  expect_true(all(res$per_sd$HR       < res$per_sd$CI_upper))
})

test_that("grs_validate() Cox C-index is in [0, 1] with CI bounds correct", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_true(all(res$discrimination$C_index >= 0))
  expect_true(all(res$discrimination$C_index <= 1))
  expect_true(all(res$discrimination$CI_lower < res$discrimination$C_index))
  expect_true(all(res$discrimination$C_index  < res$discrimination$CI_upper))
})

test_that("grs_validate() Cox C-index is above 0.5 with real GRS signal", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_gte(res$discrimination$C_index, 0.5)
})

test_that("grs_validate() Cox trend data.table has one row per GRS × model", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_s3_class(res$trend, "data.table")
  expect_gte(nrow(res$trend), 2L)
})

test_that("grs_validate() Cox does not modify original ops_toy data", {
  orig <- data.table::copy(DT_Z)
  suppressWarnings(suppressMessages(
    grs_validate(DT_Z,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_equal(DT_Z, orig)
})


# =============================================================================
# End-to-end pipeline: ops_toy → GRS_a raw → standardize → validate (Cox)
# =============================================================================

test_that("full GRS pipeline ops_toy → standardize → Cox validate runs without error", {
  d <- data.table::copy(DT)

  suppressWarnings(suppressMessages({
    # Standardize raw GRS columns
    d <- grs_standardize(d, grs_cols = c("GRS_a", "GRS_b"))

    # Validate via Cox
    res <- grs_validate(d,
                        grs_cols    = c("GRS_a_z", "GRS_b_z"),
                        outcome_col = "outcome",
                        time_col    = "followup_years",
                        covariates  = COVS)
  }))

  expect_named(res, c("per_sd", "high_vs_low", "trend", "discrimination"))
  expect_true(all(res$per_sd$HR > 0))
  expect_true("C_index" %in% names(res$discrimination))
  expect_true(data.table::is.data.table(res$per_sd))
})
