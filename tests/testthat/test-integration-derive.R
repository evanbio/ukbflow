# =============================================================================
# test-integration-derive.R — Integration tests for derive_ series
# Uses a larger simulated dataset (n=2000) — no local files required.
# Run manually before release: devtools::test(filter = "integration-derive")
# =============================================================================

skip_on_ci()
skip_on_cran()


# ===========================================================================
# Shared fixture (n=2000, UKB-like structure)
# ===========================================================================

set.seed(2024L)
N <- 2000L

BASELINE <- data.table::as.IDate("2008-01-01")
CENSOR   <- as.Date("2022-06-01")

DATA <- data.table::data.table(
  eid                = seq_len(N),
  sex                = sample(c("Male", "Female",
                                "Do not know", "Prefer not to answer", ""),
                              N, TRUE, c(0.48, 0.48, 0.02, 0.01, 0.01)),
  age_at_recruitment = round(rnorm(N, 57, 8), 1),
  bmi                = round(rnorm(N, 27, 5), 1),
  smoking            = sample(c("Never", "Previous", "Current",
                                "Prefer not to say"),
                              N, TRUE, c(0.50, 0.35, 0.10, 0.05)),
  date_baseline      = BASELINE,
  ad_status          = rbinom(N, 1, 0.15),
  ad_date            = data.table::as.IDate(ifelse(
    rbinom(N, 1, 0.15) == 1L,
    sample(seq(as.Date("2000-01-01"), as.Date("2022-01-01"), by = "day"), N, TRUE),
    NA_integer_
  ), origin = "1970-01-01"),
  cscc_status        = rbinom(N, 1, 0.08),
  cscc_date          = data.table::as.IDate(ifelse(
    rbinom(N, 1, 0.08) == 1L,
    sample(seq(as.Date("2008-01-01"), as.Date("2022-01-01"), by = "day"), N, TRUE),
    NA_integer_
  ), origin = "1970-01-01"),
  date_death         = data.table::as.IDate(ifelse(
    rbinom(N, 1, 0.05) == 1L,
    sample(seq(as.Date("2010-01-01"), as.Date("2022-01-01"), by = "day"), N, TRUE),
    NA_integer_
  ), origin = "1970-01-01"),
  date_lost          = data.table::as.IDate(rep(NA_integer_, N),
                                            origin = "1970-01-01")
)
# Ensure cases with ad_status=1 have a date (some will be NA intentionally)
DATA[ad_status == 0L,   ad_date   := NA]
DATA[cscc_status == 0L, cscc_date := NA]


# ===========================================================================
# derive_missing() — simulated data
# ===========================================================================

test_that("derive_missing() runs on n=2000 without error", {
  d <- data.table::copy(DATA)
  expect_no_error(suppressMessages(derive_missing(d, action = "na")))
})

test_that("derive_missing() removes 'Do not know' from all character columns", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(derive_missing(d, action = "na"))
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  for (col in char_cols) {
    expect_false("Do not know" %in% result[[col]],
                 label = paste0("'Do not know' still in ", col))
  }
})

test_that("derive_missing() action='unknown' replaces all refusal labels", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(derive_missing(d, action = "unknown"))
  refusal   <- c("Do not know", "Prefer not to answer", "Prefer not to say")
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  for (col in char_cols) {
    expect_false(any(result[[col]] %in% refusal, na.rm = TRUE),
                 label = paste0("refusal label still in ", col))
  }
})

test_that("derive_missing() does not alter numeric columns", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(derive_missing(d, action = "na"))
  expect_equal(result$age_at_recruitment, DATA$age_at_recruitment)
  expect_equal(result$bmi,                DATA$bmi)
})

test_that("derive_missing() returns data.table", {
  d <- data.table::copy(DATA)
  expect_true(data.table::is.data.table(
    suppressMessages(derive_missing(d, action = "na"))
  ))
})


# ===========================================================================
# derive_covariate() — simulated data
# ===========================================================================

test_that("derive_covariate() converts sex to ordered factor", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_covariate(d,
      as_factor     = "sex",
      factor_levels = list(sex = c("Female", "Male")))
  )
  expect_true(is.factor(result$sex))
  expect_equal(levels(result$sex), c("Female", "Male"))
})

test_that("derive_covariate() converts bmi to numeric when character", {
  d <- data.table::data.table(
    eid = 1:5,
    bmi = c("22.5", "30.1", "28.4", "19.8", "35.0")
  )
  result <- suppressMessages(derive_covariate(d, as_numeric = "bmi"))
  expect_true(is.numeric(result$bmi))
  expect_equal(result$bmi, c(22.5, 30.1, 28.4, 19.8, 35.0))
})

test_that("derive_covariate() returns data.table", {
  d <- data.table::copy(DATA)
  expect_true(data.table::is.data.table(
    suppressMessages(derive_covariate(d, as_factor = "smoking"))
  ))
})


# ===========================================================================
# derive_cut() — simulated data
# ===========================================================================

test_that("derive_cut() bins bmi into tertiles on n=2000", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(derive_cut(d, col = "bmi", n = 3))
  expect_true("bmi_tri" %in% names(result))
  expect_true(is.factor(result$bmi_tri))
  expect_equal(nlevels(result$bmi_tri), 3L)
})

test_that("derive_cut() bins age into quartiles correctly", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(derive_cut(d, col = "age_at_recruitment", n = 4))
  expect_true("age_at_recruitment_quad" %in% names(result))
  expect_equal(nlevels(result$age_at_recruitment_quad), 4L)
})

test_that("derive_cut() respects custom breaks and labels on large data", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_cut(d, col = "bmi", n = 3,
               breaks = c(25, 30),
               labels = c("Normal", "Overweight", "Obese"),
               name   = "bmi_who")
  )
  expect_true("bmi_who" %in% names(result))
  expect_equal(levels(result$bmi_who), c("Normal", "Overweight", "Obese"))
})

test_that("derive_cut() NA values preserved in output", {
  d <- data.table::copy(DATA)
  d[sample(N, 50L), bmi := NA_real_]
  result <- suppressMessages(derive_cut(d, col = "bmi", n = 3))
  expect_true(any(is.na(result$bmi_tri)))
})


# ===========================================================================
# derive_timing() — simulated data
# ===========================================================================

test_that("derive_timing() adds ad_timing with values in {0,1,2,NA}", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_timing(d, name = "ad", baseline_col = "date_baseline")
  )
  expect_true("ad_timing" %in% names(result))
  expect_true(all(result$ad_timing %in% c(0L, 1L, 2L, NA_integer_)))
})

test_that("derive_timing() codes 0 for rows with ad_status=0", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_timing(d, name = "ad", baseline_col = "date_baseline")
  )
  expect_true(all(result[ad_status == 0L, ad_timing] == 0L, na.rm = TRUE))
})

test_that("derive_timing() incident rows have event_date > baseline", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_timing(d, name = "ad", baseline_col = "date_baseline")
  )
  incident <- result[!is.na(ad_timing) & ad_timing == 2L]
  if (nrow(incident) > 0L) {
    expect_true(all(incident$ad_date > incident$date_baseline, na.rm = TRUE))
  }
})

test_that("derive_timing() prevalent rows have event_date <= baseline", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_timing(d, name = "ad", baseline_col = "date_baseline")
  )
  prevalent <- result[!is.na(ad_timing) & ad_timing == 1L]
  if (nrow(prevalent) > 0L) {
    expect_true(all(prevalent$ad_date <= prevalent$date_baseline, na.rm = TRUE))
  }
})

test_that("derive_timing() returns data.table", {
  d <- data.table::copy(DATA)
  expect_true(data.table::is.data.table(
    suppressMessages(derive_timing(d, name = "ad", baseline_col = "date_baseline"))
  ))
})


# ===========================================================================
# derive_age() — simulated data
# ===========================================================================

test_that("derive_age() adds age_at_ad column", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_age(d, name = "ad",
               baseline_col = "date_baseline",
               age_col      = "age_at_recruitment")
  )
  expect_true("age_at_ad" %in% names(result))
})

test_that("derive_age() age_at_ad values are plausible (20-110 years)", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_age(d, name = "ad",
               baseline_col = "date_baseline",
               age_col      = "age_at_recruitment")
  )
  v <- result$age_at_ad
  expect_true(all(v >= 20 & v <= 110, na.rm = TRUE))
})

test_that("derive_age() returns NA for non-cases", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_age(d, name = "ad",
               baseline_col = "date_baseline",
               age_col      = "age_at_recruitment")
  )
  expect_true(all(is.na(result[ad_status == 0L, age_at_ad])))
})

test_that("derive_age() processes multiple names without error", {
  d <- data.table::copy(DATA)
  expect_no_error(suppressMessages(
    derive_age(d, name = c("ad", "cscc"),
               baseline_col = "date_baseline",
               age_col      = "age_at_recruitment")
  ))
  result <- suppressMessages(
    derive_age(d, name = c("ad", "cscc"),
               baseline_col = "date_baseline",
               age_col      = "age_at_recruitment")
  )
  expect_true("age_at_ad"   %in% names(result))
  expect_true("age_at_cscc" %in% names(result))
})


# ===========================================================================
# derive_followup() — simulated data
# ===========================================================================

test_that("derive_followup() adds followup_end and followup_years", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = CENSOR)
  )
  expect_true("cscc_followup_end"   %in% names(result))
  expect_true("cscc_followup_years" %in% names(result))
})

test_that("derive_followup() followup_end never exceeds censor_date", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = CENSOR)
  )
  expect_true(all(
    result$cscc_followup_end <= data.table::as.IDate(CENSOR), na.rm = TRUE
  ))
})

test_that("derive_followup() followup_years are all positive", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = CENSOR)
  )
  expect_true(all(result$cscc_followup_years > 0, na.rm = TRUE))
})

test_that("derive_followup() end = death_date when death precedes censor", {
  d      <- data.table::copy(DATA)
  result <- suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = CENSOR,
                    death_col    = "date_death")
  )
  died_no_cscc <- result[!is.na(date_death) & is.na(cscc_date)]
  if (nrow(died_no_cscc) > 0L) {
    expect_true(all(
      died_no_cscc$cscc_followup_end <=
        pmin(died_no_cscc$date_death, data.table::as.IDate(CENSOR)),
      na.rm = TRUE
    ))
  }
})

test_that("derive_followup() works without optional death_col / lost_col", {
  d <- data.table::copy(DATA)
  expect_no_error(suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = CENSOR)
  ))
})

test_that("derive_followup() returns data.table", {
  d <- data.table::copy(DATA)
  expect_true(data.table::is.data.table(suppressMessages(
    derive_followup(d, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = CENSOR)
  )))
})
