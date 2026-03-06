# =============================================================================
# test-integration-grs.R — Integration tests for grs_ series
# Uses larger simulated data (n=2000) to test real pipeline behaviour.
# Run manually before release: devtools::test(filter = "integration-grs")
# =============================================================================

skip_on_ci()
skip_on_cran()


# ===========================================================================
# Shared fixture (n=2000, UKB-like GRS cohort)
# ===========================================================================

set.seed(2024L)
N <- 2000L

# Simulate GRS z-scores correlated with outcome (realistic signal)
grs_signal <- rnorm(N)

DT <- data.table::data.table(
  IID                = seq_len(N),
  GRS_a_z      = grs_signal + rnorm(N, sd = 0.5),
  GRS_b_z   = grs_signal + rnorm(N, sd = 0.8),
  followup_years     = round(runif(N, 1, 15), 2),
  age_recruitment    = round(rnorm(N, 57, 8), 1),
  sex                = factor(sample(c("Male", "Female"), N, TRUE)),
  tdi                = rnorm(N, -1, 3),
  smoking            = factor(sample(c("Never", "Previous", "Current"), N, TRUE))
)

# Outcome correlated with GRS signal (event rate ~15%)
DT[, outcome := as.integer(
  plogis(-2.5 + 0.4 * grs_signal + rnorm(N, sd = 0.5)) > runif(N)
)]

COVS <- c("age_recruitment", "sex", "tdi")


# ===========================================================================
# grs_check() — integration
# ===========================================================================

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

  # Output file must exist and be space-delimited with 3 columns
  expect_true(file.exists(dest))
  out_dt <- data.table::fread(dest)
  expect_equal(ncol(out_dt), 3L)
  expect_equal(nrow(out_dt), 20L)

  # Returned data.table must match written content
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


# ===========================================================================
# grs_standardize() — integration
# ===========================================================================

test_that("grs_standardize() processes multiple GRS columns correctly", {
  out <- suppressMessages(
    grs_standardize(DT, grs_cols = c("GRS_a_z", "GRS_b_z"))
  )

  for (col in c("GRS_a_z_z", "GRS_b_z_z")) {
    v <- out[[col]]
    expect_lt(abs(mean(v, na.rm = TRUE)), 1e-10)
    expect_lt(abs(sd(v,   na.rm = TRUE) - 1), 1e-10)
  }
})

test_that("grs_standardize() auto-detects both GRS columns", {
  out <- suppressMessages(grs_standardize(DT))
  expect_true("GRS_a_z_z"    %in% names(out))
  expect_true("GRS_b_z_z" %in% names(out))
})

test_that("grs_standardize() output has correct column count", {
  out <- suppressMessages(
    grs_standardize(DT, grs_cols = c("GRS_a_z", "GRS_b_z"))
  )
  # 2 original GRS cols + 2 new _z cols → ncol(DT) + 2
  expect_equal(ncol(out), ncol(DT) + 2L)
})


# ===========================================================================
# grs_validate() — logistic (time_col = NULL)
# ===========================================================================

test_that("grs_validate() logistic runs without error on n=2000", {
  expect_no_error(suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  )))
})

test_that("grs_validate() logistic per_sd has positive OR and valid CI", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  ))
  # Grab the OR column (assoc_logistic uses OR)
  expect_true(all(res$per_sd$OR > 0))
  expect_true(all(res$per_sd$CI_lower < res$per_sd$OR))
  expect_true(all(res$per_sd$OR       < res$per_sd$CI_upper))
})

test_that("grs_validate() logistic high_vs_low contains only High rows", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  ))
  expect_true(all(grepl("High$", res$high_vs_low$term)))
})

test_that("grs_validate() logistic AUC is in [0.5, 1] with real signal", {
  skip_if_not_installed("pROC")
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome")
  ))
  expect_gte(res$discrimination$AUC, 0.5)
  expect_lte(res$discrimination$AUC, 1.0)
})

test_that("grs_validate() logistic with covariates adds fully adjusted model", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome",
                 covariates  = COVS)
  ))
  expect_true("Fully adjusted" %in% as.character(res$per_sd$model))
})


# ===========================================================================
# grs_validate() — Cox (time_col supplied)
# ===========================================================================

test_that("grs_validate() Cox runs without error on n=2000", {
  expect_no_error(suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  )))
})

test_that("grs_validate() Cox per_sd has positive HR and valid CI", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_true(all(res$per_sd$HR > 0))
  expect_true(all(res$per_sd$CI_lower < res$per_sd$HR))
  expect_true(all(res$per_sd$HR       < res$per_sd$CI_upper))
})

test_that("grs_validate() Cox C-index is in [0, 1]", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_true(all(res$discrimination$C_index >= 0))
  expect_true(all(res$discrimination$C_index <= 1))
  expect_true(all(res$discrimination$CI_lower < res$discrimination$C_index))
  expect_true(all(res$discrimination$C_index  < res$discrimination$CI_upper))
})

test_that("grs_validate() Cox trend data.table has one row per GRS × model", {
  res <- suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_s3_class(res$trend, "data.table")
  expect_gte(nrow(res$trend), 2L)
})

test_that("grs_validate() does not modify original data (Cox)", {
  orig <- data.table::copy(DT)
  suppressWarnings(suppressMessages(
    grs_validate(DT,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  ))
  expect_equal(DT, orig)
})
