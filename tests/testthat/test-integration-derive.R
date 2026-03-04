# =============================================================================
# test-integration-derive.R — Integration tests for derive_ series
# Requires real decoded UKB data in dev/data/.
# Run manually before release: devtools::test(filter = "integration-derive")
# =============================================================================

skip_on_ci()
skip_on_cran()

# Local decoded test data — produced by extract_pheno() + decode_names()
DATA_PATH <- "dev/data/ukb_phenotype_core_fields_v2.csv"

if (!file.exists(DATA_PATH)) {
  skip(paste0(
    "Test data not found at '", DATA_PATH, "'. ",
    "Run extract_pheno() and save the decoded output there first."
  ))
}

data <- data.table::fread(DATA_PATH)

# Baseline date column (p53_i0 after decode_names)
BASELINE_COL <- grep("^date_of_attending|^date_baseline",
                     names(data), value = TRUE)[1L]

if (is.na(BASELINE_COL)) {
  skip("Baseline date column (p53_i0 / date_baseline) not found in test data.")
}


# ===========================================================================
# derive_missing() — live decoded data
# ===========================================================================

test_that("derive_missing() runs on real data without error", {
  d <- data.table::copy(data)
  expect_no_error(suppressMessages(derive_missing(d, action = "na")))
})

test_that("derive_missing() removes 'Do not know' from character columns", {
  d <- data.table::copy(data)
  result <- suppressMessages(derive_missing(d, action = "na"))
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  for (col in char_cols) {
    expect_false("Do not know" %in% result[[col]],
                 label = paste0("'Do not know' still present in ", col))
  }
})

test_that("derive_missing() action='unknown' produces no raw refusal labels", {
  d <- data.table::copy(data)
  result <- suppressMessages(derive_missing(d, action = "unknown"))
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  refusal <- c("Do not know", "Prefer not to answer", "Prefer not to say")
  for (col in char_cols) {
    expect_false(any(result[[col]] %in% refusal, na.rm = TRUE),
                 label = paste0("raw refusal label in ", col))
  }
})


# ===========================================================================
# derive_covariate() — live decoded data
# ===========================================================================

test_that("derive_covariate() converts sex to factor on real data", {
  d <- data.table::copy(data)
  sex_col <- grep("^sex$", names(d), value = TRUE)[1L]
  skip_if(is.na(sex_col), "sex column not found")

  result <- suppressMessages(
    derive_covariate(d,
      as_factor     = sex_col,
      factor_levels = setNames(list(c("Female", "Male")), sex_col))
  )
  expect_true(is.factor(result[[sex_col]]))
  expect_equal(levels(result[[sex_col]]), c("Female", "Male"))
})


# ===========================================================================
# derive_cut() — live decoded data
# ===========================================================================

test_that("derive_cut() bins age_at_recruitment into tertiles on real data", {
  d <- data.table::copy(data)
  age_col <- grep("age_at_recruitment|age_recruitment", names(d),
                  value = TRUE)[1L]
  skip_if(is.na(age_col), "age_at_recruitment column not found")

  result <- suppressMessages(derive_cut(d, col = age_col, n = 3))
  out_col <- paste0(age_col, "_tri")
  expect_true(out_col %in% names(result))
  expect_true(is.factor(result[[out_col]]))
  expect_equal(nlevels(result[[out_col]]), 3L)
})


# ===========================================================================
# derive_timing() — live decoded data
# ===========================================================================

test_that("derive_timing() runs on real data with auto-detected columns", {
  d <- data.table::copy(data)

  # Requires ad_status + ad_date columns (from derive_case / derive_hes)
  skip_if(!"ad_status" %in% names(d), "ad_status not found — run derive_case first")
  skip_if(!"ad_date"   %in% names(d), "ad_date not found")

  result <- suppressMessages(
    derive_timing(d, name = "ad", baseline_col = BASELINE_COL)
  )
  expect_true("ad_timing" %in% names(result))
  expect_true(all(result$ad_timing %in% c(0L, 1L, 2L, NA_integer_)))
})

test_that("derive_timing() produces no 2 (incident) with dates before baseline", {
  d <- data.table::copy(data)
  skip_if(!"ad_status" %in% names(d), "ad_status not found")
  skip_if(!"ad_date"   %in% names(d), "ad_date not found")

  result <- suppressMessages(
    derive_timing(d, name = "ad", baseline_col = BASELINE_COL)
  )
  # Incident rows must have event_date > baseline
  incident <- result[ad_timing == 2L]
  if (nrow(incident) > 0L) {
    expect_true(all(incident$ad_date > incident[[BASELINE_COL]], na.rm = TRUE))
  }
})


# ===========================================================================
# derive_age() — live decoded data
# ===========================================================================

test_that("derive_age() adds age_at_ad on real data", {
  d <- data.table::copy(data)
  age_col <- grep("age_at_recruitment|age_recruitment", names(d),
                  value = TRUE)[1L]
  skip_if(is.na(age_col),      "age_at_recruitment not found")
  skip_if(!"ad_date" %in% names(d), "ad_date not found")

  result <- suppressMessages(
    derive_age(d, name = "ad",
               baseline_col = BASELINE_COL,
               age_col      = age_col)
  )
  expect_true("age_at_ad" %in% names(result))
})

test_that("derive_age() age_at_ad values are plausible (20-110 years)", {
  d <- data.table::copy(data)
  age_col <- grep("age_at_recruitment|age_recruitment", names(d),
                  value = TRUE)[1L]
  skip_if(is.na(age_col),      "age_at_recruitment not found")
  skip_if(!"ad_date" %in% names(d), "ad_date not found")

  result <- suppressMessages(
    derive_age(d, name = "ad",
               baseline_col = BASELINE_COL,
               age_col      = age_col)
  )
  v <- result$age_at_ad
  expect_true(all(v >= 20 & v <= 110, na.rm = TRUE))
})

test_that("derive_age() processes multiple names without error", {
  d <- data.table::copy(data)
  age_col <- grep("age_at_recruitment|age_recruitment", names(d),
                  value = TRUE)[1L]
  skip_if(is.na(age_col), "age_at_recruitment not found")

  # Collect names whose _date column exists
  candidates <- c("ad", "cscc")
  valid_names <- candidates[paste0(candidates, "_date") %in% names(d)]
  skip_if(length(valid_names) == 0L, "no *_date columns found for candidates")

  expect_no_error(suppressMessages(
    derive_age(d, name = valid_names,
               baseline_col = BASELINE_COL,
               age_col      = age_col)
  ))
})


# ===========================================================================
# derive_followup() — live decoded data
# ===========================================================================

test_that("derive_followup() adds followup_end and followup_years on real data", {
  d <- data.table::copy(data)
  skip_if(!"cscc_date" %in% names(d), "cscc_date not found")

  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = BASELINE_COL,
                    censor_date  = as.Date("2022-06-01"))
  )
  expect_true("cscc_followup_end"   %in% names(result))
  expect_true("cscc_followup_years" %in% names(result))
})

test_that("derive_followup() followup_end never exceeds censor_date", {
  d <- data.table::copy(data)
  skip_if(!"cscc_date" %in% names(d), "cscc_date not found")

  censor <- as.Date("2022-06-01")
  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = BASELINE_COL,
                    censor_date  = censor)
  )
  expect_true(all(result$cscc_followup_end <= data.table::as.IDate(censor),
                  na.rm = TRUE))
})

test_that("derive_followup() followup_years are positive on real data", {
  d <- data.table::copy(data)
  skip_if(!"cscc_date" %in% names(d), "cscc_date not found")

  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = BASELINE_COL,
                    censor_date  = as.Date("2022-06-01"))
  )
  expect_true(all(result$cscc_followup_years > 0, na.rm = TRUE))
})

test_that("derive_followup() auto-detects death_col (field 40000)", {
  d <- data.table::copy(data)
  skip_if(!"cscc_date" %in% names(d), "cscc_date not found")

  # If field 40000 is present, auto-detection should work without error
  expect_no_error(suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = BASELINE_COL,
                    censor_date  = as.Date("2022-06-01"))
  ))
})
