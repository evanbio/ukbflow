# =============================================================================
# test-grs.R — Unit tests for grs_ series (no network, no RAP)
# =============================================================================


# ===========================================================================
# Shared helpers
# ===========================================================================

# Minimal valid weights data.table
.fake_weights_dt <- function() {
  data.table::data.table(
    snp           = paste0("rs", 1:5),
    effect_allele = c("A", "T", "C", "G", "A"),
    beta          = c(0.10, -0.20, 0.30, 0.05, -0.15)
  )
}

# Write a weights CSV to a temp path; returns the path
.write_weights_file <- function(path, dt = NULL) {
  if (is.null(dt)) dt <- .fake_weights_dt()
  data.table::fwrite(dt, path)
  path
}

# Simulated GRS cohort for standardize / validate
.fake_grs_dt <- function(n = 300, seed = 42) {
  set.seed(seed)
  data.table::data.table(
    IID              = seq_len(n),
    GRS_a_z    = rnorm(n),
    GRS_b_z = rnorm(n),
    outcome          = rbinom(n, 1, 0.20),
    followup_years   = round(runif(n, 1, 15), 2)
  )
}


# ===========================================================================
# grs_check()
# ===========================================================================

test_that("grs_check() aborts when file not found", {
  expect_error(grs_check("/no/such/file.txt"), "not found")
})

test_that("grs_check() aborts when required columns are missing", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    data.table::fwrite(data.table::data.table(x = 1:3, y = 1:3), path)
    expect_error(grs_check(path), "Required column")
  })()
})

test_that("grs_check() aborts when NA values are present", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    dt <- .fake_weights_dt()
    dt[2L, beta := NA_real_]
    .write_weights_file(path, dt)
    expect_error(grs_check(path), "NA")
  })()
})

test_that("grs_check() aborts on duplicate SNP IDs", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    dt <- .fake_weights_dt()
    dt[2L, snp := dt$snp[1L]]
    .write_weights_file(path, dt)
    expect_error(grs_check(path), "duplicate")
  })()
})

test_that("grs_check() aborts when beta is non-numeric", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    dt <- data.table::data.table(
      snp           = paste0("rs", 1:3),
      effect_allele = c("A", "T", "C"),
      beta          = c("high", "low", "medium")
    )
    .write_weights_file(path, dt)
    expect_error(grs_check(path), "[Bb]eta|numeric")
  })()
})

test_that("grs_check() warns on non-rs SNP IDs but does not abort", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    dt <- .fake_weights_dt()
    dt[1L, snp := "chr1:12345:A:G"]
    dest <- tempfile(fileext = ".txt")
    on.exit(unlink(dest), add = TRUE)
    .write_weights_file(path, dt)
    expect_warning(grs_check(path, dest = dest), "rs\\[0-9\\]\\+|rs.*format")
  })()
})

test_that("grs_check() warns on non-ATCG alleles but does not abort", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    dt <- .fake_weights_dt()
    dt[1L, effect_allele := "INDEL"]
    dest <- tempfile(fileext = ".txt")
    on.exit(unlink(dest), add = TRUE)
    .write_weights_file(path, dt)
    expect_warning(grs_check(path, dest = dest), "A/T/C/G|allele")
  })()
})

test_that("grs_check() returns a 3-column data.table and writes output file", {
  withr::local_tempfile(fileext = ".csv") |> (function(path) {
    .write_weights_file(path)
    dest <- tempfile(fileext = ".txt")
    on.exit(unlink(dest), add = TRUE)

    result <- grs_check(path, dest = dest)

    expect_s3_class(result, "data.table")
    expect_equal(ncol(result), 3L)
    expect_named(result, c("snp", "effect_allele", "beta"))
    expect_equal(nrow(result), 5L)
    expect_true(file.exists(dest))
  })()
})


# ===========================================================================
# grs_standardize() / grs_zscore()
# ===========================================================================

test_that("grs_standardize() aborts on non-data.frame input", {
  expect_error(grs_standardize("not a df"), "data.frame")
})

test_that("grs_standardize() aborts when manually specified column not found", {
  dt <- .fake_grs_dt()
  expect_error(grs_standardize(dt, grs_cols = "no_such_col"), "not found")
})

test_that("grs_standardize() aborts when no GRS columns auto-detected", {
  dt <- data.table::data.table(IID = 1:5, age = 50:54)
  expect_error(grs_standardize(dt), "No columns")
})

test_that("grs_standardize() aborts on zero-variance column", {
  dt <- data.table::data.table(IID = 1:5, GRS_flat = rep(1.0, 5))
  expect_error(grs_standardize(dt), "zero variance")
})

test_that("grs_standardize() produces mean ≈ 0 and SD ≈ 1 for _z columns", {
  dt  <- .fake_grs_dt()
  out <- grs_standardize(dt, grs_cols = c("GRS_a_z", "GRS_b_z"))

  for (col in c("GRS_a_z_z", "GRS_b_z_z")) {
    expect_true(col %in% names(out))
    expect_lt(abs(mean(out[[col]], na.rm = TRUE)), 1e-10)
    expect_lt(abs(sd(out[[col]], na.rm = TRUE) - 1), 1e-10)
  }
})

test_that("grs_standardize() inserts _z column immediately after source column", {
  dt  <- .fake_grs_dt()
  out <- grs_standardize(dt, grs_cols = "GRS_a_z")
  idx_src <- which(names(out) == "GRS_a_z")
  idx_z   <- which(names(out) == "GRS_a_z_z")
  expect_equal(idx_z, idx_src + 1L)
})

test_that("grs_standardize() preserves original columns unchanged", {
  dt  <- .fake_grs_dt()
  out <- grs_standardize(dt, grs_cols = "GRS_a_z")
  expect_equal(out$GRS_a_z, dt$GRS_a_z)
})

test_that("grs_standardize() works on plain data.frame input", {
  df  <- as.data.frame(.fake_grs_dt())
  out <- grs_standardize(df, grs_cols = "GRS_a_z")
  expect_s3_class(out, "data.table")
  expect_true("GRS_a_z_z" %in% names(out))
})

test_that("grs_zscore() produces identical result to grs_standardize()", {
  dt  <- .fake_grs_dt()
  r1  <- grs_standardize(dt, grs_cols = "GRS_a_z")
  r2  <- grs_zscore(dt,      grs_cols = "GRS_a_z")
  expect_equal(r1, r2)
})


# ===========================================================================
# grs_validate()
# ===========================================================================

test_that("grs_validate() aborts on non-data.frame input", {
  expect_error(grs_validate("x", outcome_col = "outcome"), "data.frame")
})

test_that("grs_validate() aborts when outcome_col is missing", {
  dt <- .fake_grs_dt()
  expect_error(grs_validate(dt, outcome_col = "no_such_col"), "not found")
})

test_that("grs_validate() aborts when grs_cols not found in data", {
  dt <- .fake_grs_dt()
  expect_error(
    grs_validate(dt, grs_cols = "no_such_grs", outcome_col = "outcome"),
    "not found"
  )
})

test_that("grs_validate() aborts when no GRS columns auto-detected", {
  dt <- data.table::data.table(IID = 1:10, outcome = rbinom(10, 1, 0.2))
  expect_error(grs_validate(dt, outcome_col = "outcome"), "No GRS")
})

test_that("grs_validate() aborts when grs_cols are non-numeric", {
  dt <- data.table::data.table(
    IID     = 1:10,
    GRS_x   = as.character(rnorm(10)),
    outcome = rbinom(10, 1, 0.3)
  )
  expect_error(
    grs_validate(dt, grs_cols = "GRS_x", outcome_col = "outcome"),
    "numeric"
  )
})

test_that("grs_validate() returns a list with 4 named elements (logistic)", {
  skip_if_not_installed("pROC")
  dt  <- .fake_grs_dt()
  res <- suppressWarnings(
    grs_validate(dt,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  )
  expect_type(res, "list")
  expect_named(res, c("per_sd", "high_vs_low", "trend", "discrimination"))
})

test_that("grs_validate() per_sd has one row per GRS (logistic, unadjusted)", {
  skip_if_not_installed("pROC")
  dt  <- .fake_grs_dt()
  res <- suppressWarnings(
    grs_validate(dt,
                 grs_cols    = c("GRS_a_z", "GRS_b_z"),
                 outcome_col = "outcome")
  )
  expect_s3_class(res$per_sd, "data.table")
  # At minimum one unadjusted row per GRS
  expect_gte(nrow(res$per_sd), 2L)
})

test_that("grs_validate() discrimination returns AUC column (logistic)", {
  skip_if_not_installed("pROC")
  dt  <- .fake_grs_dt()
  res <- suppressWarnings(
    grs_validate(dt,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome")
  )
  expect_true("AUC" %in% names(res$discrimination))
  expect_gte(res$discrimination$AUC, 0)
  expect_lte(res$discrimination$AUC, 1)
})

test_that("grs_validate() returns C-index column when time_col supplied (Cox)", {
  dt  <- .fake_grs_dt()
  res <- suppressWarnings(
    grs_validate(dt,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome",
                 time_col    = "followup_years")
  )
  expect_true("C_index" %in% names(res$discrimination))
  expect_gte(res$discrimination$C_index, 0)
  expect_lte(res$discrimination$C_index, 1)
})

test_that("grs_validate() does not modify the user's original data", {
  skip_if_not_installed("pROC")
  dt   <- .fake_grs_dt()
  orig <- data.table::copy(dt)
  suppressWarnings(
    grs_validate(dt,
                 grs_cols    = "GRS_a_z",
                 outcome_col = "outcome")
  )
  expect_equal(dt, orig)
})


# ===========================================================================
# grs_bgen2pgen() — argument validation (no RAP submission)
# ===========================================================================

test_that("grs_bgen2pgen() aborts when chr contains out-of-range values", {
  expect_error(grs_bgen2pgen(chr = 0),  "between 1 and 22")
  expect_error(grs_bgen2pgen(chr = 23), "between 1 and 22")
})

test_that("grs_bgen2pgen() aborts when chr contains NA", {
  expect_error(grs_bgen2pgen(chr = NA_integer_), "between 1 and 22")
})

test_that("grs_bgen2pgen() aborts when maf is out of range", {
  expect_error(grs_bgen2pgen(chr = 22, maf = 0),    "maf")
  expect_error(grs_bgen2pgen(chr = 22, maf = 0.5),  "maf")
  expect_error(grs_bgen2pgen(chr = 22, maf = -0.1), "maf")
})

test_that("grs_bgen2pgen() aborts when maf is not a scalar", {
  expect_error(grs_bgen2pgen(chr = 22, maf = c(0.01, 0.05)), "maf")
})

test_that("grs_bgen2pgen() aborts on invalid instance value", {
  expect_error(grs_bgen2pgen(chr = 22, instance = "xlarge"), "arg")
})

test_that("grs_bgen2pgen() aborts on invalid priority value", {
  expect_error(grs_bgen2pgen(chr = 22, priority = "medium"), "arg")
})

test_that("grs_bgen2pgen() warns when standard instance used for chr 1-16", {
  # Mock project check so the test never reaches dx run, regardless of auth state
  local_mocked_bindings(
    .dx_get_project_id = function() NA_character_,
    .package = "ukbflow"
  )
  expect_warning(
    tryCatch(
      grs_bgen2pgen(chr = 1, instance = "standard"),
      error = function(e) NULL
    ),
    "storage|mem2_ssd1|large"
  )
})


# ===========================================================================
# grs_score() — argument validation (no RAP submission)
# ===========================================================================

test_that("grs_score() aborts when file is not a character vector", {
  expect_error(grs_score(file = 123L), "character")
})

test_that("grs_score() aborts when file entries are unnamed", {
  expect_error(grs_score(file = c("weights.txt")), "named")
})

test_that("grs_score() aborts when file has partially missing names", {
  expect_error(grs_score(file = c(grs_a = "a.txt", "b.txt")), "named")
})

test_that("grs_score() aborts on duplicate names in file", {
  expect_error(
    grs_score(file = c(grs_a = "a.txt", grs_a = "b.txt")),
    "[Dd]uplicate"
  )
})

test_that("grs_score() aborts when local weight file does not exist", {
  expect_error(
    grs_score(file = c(grs_a = "/no/such/weights.txt")),
    "not found"
  )
})

test_that("grs_score() aborts when maf is out of range", {
  withr::local_tempfile(fileext = ".txt") |> (function(f) {
    file.create(f)
    expect_error(grs_score(file = c(grs_a = f), maf = 0),   "maf")
    expect_error(grs_score(file = c(grs_a = f), maf = 0.5), "maf")
  })()
})

test_that("grs_score() aborts on invalid instance value", {
  withr::local_tempfile(fileext = ".txt") |> (function(f) {
    file.create(f)
    expect_error(grs_score(file = c(grs_a = f), instance = "mega"), "arg")
  })()
})

test_that("grs_score() aborts on invalid priority value", {
  withr::local_tempfile(fileext = ".txt") |> (function(f) {
    file.create(f)
    expect_error(grs_score(file = c(grs_a = f), priority = "urgent"), "arg")
  })()
})
