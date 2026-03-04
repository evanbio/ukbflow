# =============================================================================
# test-derive.R — Unit tests for derive_ series (no network, no real files)
# =============================================================================

# ===========================================================================
# Shared helpers
# ===========================================================================

.fake_derive_dt <- function() {
  data.table::data.table(
    eid             = 1:6,
    sex             = c("Male", "Female", "Do not know", "Prefer not to answer",
                        "Prefer not to say", ""),
    age_recruitment = c(55.0, 62.0, 48.0, 70.0, 58.0, 45.0),
    bmi             = c(22.5, 30.1, NA_real_, 28.4, 19.8, 35.0)
  )
}

.fake_timing_dt <- function() {
  data.table::data.table(
    eid           = 1:5,
    ad_status     = c(FALSE, TRUE,  TRUE,  TRUE,  FALSE),
    ad_date       = data.table::as.IDate(
                      c(NA, "2010-01-01", "2018-06-01", NA, NA)),
    date_baseline = data.table::as.IDate("2015-01-01")
  )
}

.fake_followup_dt <- function() {
  data.table::data.table(
    eid           = 1:4,
    cscc_date     = data.table::as.IDate(
                      c("2018-01-01", NA, "2023-01-01", NA)),
    date_baseline = data.table::as.IDate("2008-01-01"),
    date_death    = data.table::as.IDate(c(NA, "2020-06-01", NA, NA)),
    date_lost     = data.table::as.IDate(c(NA, NA, NA, "2019-03-01"))
  )
}

.fake_age_dt <- function() {
  data.table::data.table(
    eid             = 1:4,
    ad_status       = c(1L, 1L, 0L, 1L),
    ad_date         = data.table::as.IDate(
                        c("2010-01-01", "2018-06-01", NA, "2016-03-15")),
    cscc_status     = c(1L, 0L, 1L, 0L),
    cscc_date       = data.table::as.IDate(
                        c("2019-05-01", NA, "2021-11-01", NA)),
    date_baseline   = data.table::as.IDate("2008-01-01"),
    age_recruitment = c(55.0, 62.0, 48.0, 70.0)
  )
}


# ===========================================================================
# derive_missing()
# ===========================================================================

test_that("derive_missing() stops on non-data.frame input", {
  expect_error(derive_missing("not a df"), "data.frame")
})

test_that("derive_missing() stops on invalid extra_labels", {
  dt <- .fake_derive_dt()
  expect_error(derive_missing(dt, extra_labels = 123), "character")
})

test_that("derive_missing() action='na': converts 'Do not know' to NA", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt, action = "na"))
  expect_true(is.na(result$sex[3]))   # "Do not know"
})

test_that("derive_missing() action='na': converts 'Prefer not to answer' to NA", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt, action = "na"))
  expect_true(is.na(result$sex[4]))   # "Prefer not to answer"
})

test_that("derive_missing() action='na': converts 'Prefer not to say' to NA", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt, action = "na"))
  expect_true(is.na(result$sex[5]))   # "Prefer not to say"
})

test_that("derive_missing() always converts empty string to NA", {
  dt <- .fake_derive_dt()
  result_na      <- suppressMessages(derive_missing(dt, action = "na"))
  result_unknown <- suppressMessages(derive_missing(
    data.table::copy(.fake_derive_dt()), action = "unknown"))
  expect_true(is.na(result_na$sex[6]))
  expect_true(is.na(result_unknown$sex[6]))
})

test_that("derive_missing() action='unknown': converts labels to 'Unknown'", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt, action = "unknown"))
  expect_equal(result$sex[3], "Unknown")
  expect_equal(result$sex[4], "Unknown")
})

test_that("derive_missing() preserves valid labels", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt, action = "na"))
  expect_equal(result$sex[1], "Male")
  expect_equal(result$sex[2], "Female")
})

test_that("derive_missing() skips numeric columns silently", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt, action = "na"))
  expect_equal(result$age_recruitment, dt$age_recruitment)
})

test_that("derive_missing() extra_labels treated as missing", {
  dt <- data.table::data.table(
    eid = 1:3,
    smoke = c("Never", "Not applicable", "Current")
  )
  result <- suppressMessages(
    derive_missing(dt, extra_labels = "Not applicable", action = "na")
  )
  expect_true(is.na(result$smoke[2]))
  expect_equal(result$smoke[1], "Never")
})

test_that("derive_missing() returns data.table", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_missing(dt))
  expect_true(data.table::is.data.table(result))
})


# ===========================================================================
# derive_covariate()
# ===========================================================================

test_that("derive_covariate() stops on non-data.frame input", {
  expect_error(derive_covariate("not a df"), "data.frame")
})

test_that("derive_covariate() stops on non-list factor_levels", {
  dt <- .fake_derive_dt()
  expect_error(
    suppressMessages(derive_covariate(dt, factor_levels = "bad")),
    "named list"
  )
})

test_that("derive_covariate() converts character column to numeric", {
  dt <- data.table::data.table(eid = 1:3, score = c("1.5", "2.0", "3.5"))
  result <- suppressMessages(derive_covariate(dt, as_numeric = "score"))
  expect_true(is.numeric(result$score))
  expect_equal(result$score, c(1.5, 2.0, 3.5))
})

test_that("derive_covariate() converts column to factor with default levels", {
  dt <- data.table::data.table(
    eid  = 1:3,
    smoke = c("Never", "Current", "Never")
  )
  result <- suppressMessages(derive_covariate(dt, as_factor = "smoke"))
  expect_true(is.factor(result$smoke))
})

test_that("derive_covariate() respects custom factor_levels order", {
  dt <- data.table::data.table(
    eid   = 1:3,
    smoke = c("Never", "Current", "Previous")
  )
  result <- suppressMessages(derive_covariate(
    dt,
    as_factor     = "smoke",
    factor_levels = list(smoke = c("Never", "Previous", "Current"))
  ))
  expect_equal(levels(result$smoke), c("Never", "Previous", "Current"))
})

test_that("derive_covariate() skips missing column with warning", {
  dt <- .fake_derive_dt()
  expect_message(
    derive_covariate(dt, as_numeric = "nonexistent"),
    regexp = "not found|skipped",
    ignore.case = TRUE
  )
})

test_that("derive_covariate() returns data.table", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_covariate(dt, as_numeric = "age_recruitment"))
  expect_true(data.table::is.data.table(result))
})


# ===========================================================================
# derive_cut()
# ===========================================================================

test_that("derive_cut() stops on non-data.frame input", {
  expect_error(derive_cut("not a df", col = "age", n = 3), "data.frame")
})

test_that("derive_cut() stops when col not found", {
  dt <- .fake_derive_dt()
  expect_error(suppressMessages(derive_cut(dt, col = "missing", n = 3)),
               "not found")
})

test_that("derive_cut() stops when n < 2", {
  dt <- .fake_derive_dt()
  expect_error(suppressMessages(derive_cut(dt, col = "bmi", n = 1)), ">= 2")
})

test_that("derive_cut() stops when breaks length != n - 1", {
  dt <- .fake_derive_dt()
  expect_error(
    suppressMessages(derive_cut(dt, col = "bmi", n = 3, breaks = c(25))),
    "length"
  )
})

test_that("derive_cut() stops when labels length != n", {
  dt <- .fake_derive_dt()
  expect_error(
    suppressMessages(derive_cut(dt, col = "bmi", n = 3,
                                labels = c("low", "high"))),
    "length"
  )
})

test_that("derive_cut() produces factor column with n levels (quantile)", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_cut(dt, col = "bmi", n = 2))
  expect_true("bmi_bi" %in% names(result))
  expect_true(is.factor(result$bmi_bi))
})

test_that("derive_cut() uses default name suffix correctly", {
  dt <- .fake_derive_dt()
  r2 <- suppressMessages(derive_cut(data.table::copy(dt), col = "bmi", n = 2))
  r3 <- suppressMessages(derive_cut(data.table::copy(dt), col = "bmi", n = 3))
  r4 <- suppressMessages(derive_cut(data.table::copy(dt), col = "bmi", n = 4))
  expect_true("bmi_bi"   %in% names(r2))
  expect_true("bmi_tri"  %in% names(r3))
  expect_true("bmi_quad" %in% names(r4))
})

test_that("derive_cut() respects custom breaks and labels", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(
    derive_cut(dt, col = "bmi", n = 3,
               breaks = c(25, 30),
               labels = c("Normal", "Overweight", "Obese"),
               name   = "bmi_cat")
  )
  expect_true("bmi_cat" %in% names(result))
  expect_true(all(levels(result$bmi_cat) == c("Normal", "Overweight", "Obese")))
})

test_that("derive_cut() returns data.table", {
  dt <- .fake_derive_dt()
  result <- suppressMessages(derive_cut(dt, col = "bmi", n = 3))
  expect_true(data.table::is.data.table(result))
})


# ===========================================================================
# derive_timing()
# ===========================================================================

test_that("derive_timing() stops on non-data.frame input", {
  expect_error(derive_timing("not a df", name = "ad",
                             baseline_col = "date_baseline"), "data.frame")
})

test_that("derive_timing() stops when required column missing", {
  dt <- .fake_timing_dt()
  expect_error(
    suppressMessages(derive_timing(dt, name = "ad",
                                   baseline_col = "nonexistent")),
    "not found"
  )
})

test_that("derive_timing() adds {name}_timing column", {
  dt <- .fake_timing_dt()
  result <- suppressMessages(
    derive_timing(dt, name = "ad", baseline_col = "date_baseline")
  )
  expect_true("ad_timing" %in% names(result))
})

test_that("derive_timing() codes 0 for no-disease rows", {
  dt <- .fake_timing_dt()
  result <- suppressMessages(
    derive_timing(dt, name = "ad", baseline_col = "date_baseline")
  )
  # Rows 1 and 5: ad_status = FALSE → 0
  expect_equal(result$ad_timing[1], 0L)
  expect_equal(result$ad_timing[5], 0L)
})

test_that("derive_timing() codes 1 for prevalent cases (date <= baseline)", {
  dt <- .fake_timing_dt()
  result <- suppressMessages(
    derive_timing(dt, name = "ad", baseline_col = "date_baseline")
  )
  # Row 2: ad_date = 2010-01-01 < baseline 2015-01-01 → prevalent (1)
  expect_equal(result$ad_timing[2], 1L)
})

test_that("derive_timing() codes 2 for incident cases (date > baseline)", {
  dt <- .fake_timing_dt()
  result <- suppressMessages(
    derive_timing(dt, name = "ad", baseline_col = "date_baseline")
  )
  # Row 3: ad_date = 2018-06-01 > baseline 2015-01-01 → incident (2)
  expect_equal(result$ad_timing[3], 2L)
})

test_that("derive_timing() codes NA when case has no date", {
  dt <- .fake_timing_dt()
  result <- suppressMessages(
    derive_timing(dt, name = "ad", baseline_col = "date_baseline")
  )
  # Row 4: ad_status = TRUE but ad_date = NA → NA
  expect_true(is.na(result$ad_timing[4]))
})

test_that("derive_timing() respects explicit status_col and date_col overrides", {
  dt <- data.table::data.table(
    eid           = 1:2,
    my_status     = c(TRUE, FALSE),
    my_date       = data.table::as.IDate(c("2012-01-01", NA)),
    date_baseline = data.table::as.IDate("2015-01-01")
  )
  result <- suppressMessages(
    derive_timing(dt, name = "x",
                  status_col   = "my_status",
                  date_col     = "my_date",
                  baseline_col = "date_baseline")
  )
  expect_equal(result$x_timing[1], 1L)   # prevalent
  expect_equal(result$x_timing[2], 0L)   # no disease
})

test_that("derive_timing() returns data.table", {
  dt <- .fake_timing_dt()
  result <- suppressMessages(
    derive_timing(dt, name = "ad", baseline_col = "date_baseline")
  )
  expect_true(data.table::is.data.table(result))
})


# ===========================================================================
# derive_age()
# ===========================================================================

test_that("derive_age() stops on non-data.frame input", {
  expect_error(
    derive_age("not a df", name = "ad",
               baseline_col = "date_baseline", age_col = "age_recruitment"),
    "data.frame"
  )
})

test_that("derive_age() stops on empty name", {
  dt <- .fake_age_dt()
  expect_error(
    derive_age(dt, name = character(0),
               baseline_col = "date_baseline", age_col = "age_recruitment"),
    "non-empty"
  )
})

test_that("derive_age() stops when baseline_col missing", {
  dt <- .fake_age_dt()
  expect_error(
    derive_age(dt, name = "ad",
               baseline_col = "nonexistent", age_col = "age_recruitment"),
    "not found"
  )
})

test_that("derive_age() adds age_at_{name} column", {
  dt <- .fake_age_dt()
  result <- suppressMessages(
    derive_age(dt, name = "ad",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true("age_at_ad" %in% names(result))
})

test_that("derive_age() computes correct age for case with integer status", {
  dt <- .fake_age_dt()
  result <- suppressMessages(
    derive_age(dt, name = "ad",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  # Row 1: age_recruitment=55, ad_date=2010-01-01, baseline=2008-01-01
  # offset = (2010-01-01 - 2008-01-01) / 365.25 ≈ 2.00
  expect_true(!is.na(result$age_at_ad[1]))
  expect_equal(result$age_at_ad[1],
               55 + as.numeric(
                 data.table::as.IDate("2010-01-01") -
                 data.table::as.IDate("2008-01-01")
               ) / 365.25)
})

test_that("derive_age() returns NA for non-cases (status = 0)", {
  dt <- .fake_age_dt()
  result <- suppressMessages(
    derive_age(dt, name = "ad",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  # Row 3: ad_status = 0 → NA
  expect_true(is.na(result$age_at_ad[3]))
})

test_that("derive_age() handles logical status column", {
  dt <- data.table::data.table(
    eid             = 1:3,
    ad              = c(TRUE, FALSE, TRUE),    # bare logical, no _status suffix
    ad_date         = data.table::as.IDate(c("2012-06-01", NA, "2017-09-01")),
    date_baseline   = data.table::as.IDate("2010-01-01"),
    age_recruitment = c(50.0, 60.0, 55.0)
  )
  result <- suppressMessages(
    derive_age(dt, name = "ad",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true(!is.na(result$age_at_ad[1]))
  expect_true(is.na(result$age_at_ad[2]))   # FALSE → NA
})

test_that("derive_age() processes multiple names in one call", {
  dt <- .fake_age_dt()
  result <- suppressMessages(
    derive_age(dt, name = c("ad", "cscc"),
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true("age_at_ad"   %in% names(result))
  expect_true("age_at_cscc" %in% names(result))
})

test_that("derive_age() warns and skips when date column missing", {
  dt <- .fake_age_dt()
  expect_message(
    derive_age(dt, name = "unknown_disease",
               baseline_col = "date_baseline", age_col = "age_recruitment"),
    regexp = "not found|skipping",
    ignore.case = TRUE
  )
  expect_false("age_at_unknown_disease" %in% names(dt))
})

test_that("derive_age() partial date_cols override works without error", {
  dt <- .fake_age_dt()
  # Only specify date_col for ad; cscc should auto-detect cscc_date
  result <- suppressMessages(
    derive_age(dt, name = c("ad", "cscc"),
               baseline_col = "date_baseline",
               age_col      = "age_recruitment",
               date_cols    = c(ad = "ad_date"))   # cscc not specified → auto
  )
  expect_true("age_at_ad"   %in% names(result))
  expect_true("age_at_cscc" %in% names(result))
})

test_that("derive_age() returns data.table", {
  dt <- .fake_age_dt()
  result <- suppressMessages(
    derive_age(dt, name = "ad",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true(data.table::is.data.table(result))
})


# ===========================================================================
# derive_followup()
# ===========================================================================

test_that("derive_followup() stops on non-data.frame input", {
  expect_error(
    derive_followup("not a df", name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01")),
    "data.frame"
  )
})

test_that("derive_followup() stops when event_col missing", {
  dt <- .fake_followup_dt()
  expect_error(
    suppressMessages(
      derive_followup(dt, name = "cscc",
                      event_col    = "nonexistent",
                      baseline_col = "date_baseline",
                      censor_date  = as.Date("2022-06-01"))
    ),
    "not found"
  )
})

test_that("derive_followup() adds {name}_followup_end and {name}_followup_years", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"))
  )
  expect_true("cscc_followup_end"   %in% names(result))
  expect_true("cscc_followup_years" %in% names(result))
})

test_that("derive_followup() end = event_date when event precedes censor", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"),
                    death_col    = "date_death",
                    lost_col     = "date_lost")
  )
  # Row 1: cscc_date = 2018-01-01 < censor → end = 2018-01-01
  expect_equal(result$cscc_followup_end[1],
               data.table::as.IDate("2018-01-01"))
})

test_that("derive_followup() end = censor_date when event exceeds censor", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"),
                    death_col    = "date_death",
                    lost_col     = "date_lost")
  )
  # Row 3: cscc_date = 2023-01-01 > censor 2022-06-01 → end = censor
  expect_equal(result$cscc_followup_end[3],
               data.table::as.IDate("2022-06-01"))
})

test_that("derive_followup() end = death_date when death precedes censor", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"),
                    death_col    = "date_death",
                    lost_col     = "date_lost")
  )
  # Row 2: no cscc, death = 2020-06-01 < censor → end = 2020-06-01
  expect_equal(result$cscc_followup_end[2],
               data.table::as.IDate("2020-06-01"))
})

test_that("derive_followup() end = lost_date when lost precedes censor", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"),
                    death_col    = "date_death",
                    lost_col     = "date_lost")
  )
  # Row 4: no cscc, no death, lost = 2019-03-01 < censor → end = 2019-03-01
  expect_equal(result$cscc_followup_end[4],
               data.table::as.IDate("2019-03-01"))
})

test_that("derive_followup() followup_years is positive and finite", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"))
  )
  yrs <- result$cscc_followup_years
  expect_true(all(yrs > 0, na.rm = TRUE))
  expect_true(all(is.finite(yrs)))
})

test_that("derive_followup() followup_years computed correctly", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"))
  )
  # Row 1: 2018-01-01 - 2008-01-01 = 3652 days / 365.25
  expected <- as.numeric(
    data.table::as.IDate("2018-01-01") - data.table::as.IDate("2008-01-01")
  ) / 365.25
  expect_equal(result$cscc_followup_years[1], expected)
})

test_that("derive_followup() works without death_col and lost_col", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"))
  )
  expect_true("cscc_followup_end" %in% names(result))
})

test_that("derive_followup() accepts character censor_date", {
  dt <- .fake_followup_dt()
  expect_no_error(
    suppressMessages(
      derive_followup(dt, name = "cscc",
                      event_col    = "cscc_date",
                      baseline_col = "date_baseline",
                      censor_date  = "2022-06-01")
    )
  )
})

test_that("derive_followup() returns data.table", {
  dt <- .fake_followup_dt()
  result <- suppressMessages(
    derive_followup(dt, name = "cscc",
                    event_col    = "cscc_date",
                    baseline_col = "date_baseline",
                    censor_date  = as.Date("2022-06-01"))
  )
  expect_true(data.table::is.data.table(result))
})
