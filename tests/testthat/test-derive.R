# =============================================================================
# test-derive.R — Unit tests for derive_ series
# Primary fixture: ops_toy(n = 300, seed = 42) — UKB-like structure, no network
# Hand-crafted helpers only where exact row-level values must be asserted
# =============================================================================

# File-level fixture (created once, copied per test)
DT <- suppressMessages(ops_toy(n = 300L, seed = 42L))

# ── Hand-crafted helpers (exact-value tests) ──────────────────────────────────

.timing_dt <- function() {
  data.table::data.table(
    eid           = 1:5,
    t2d_status    = c(FALSE, TRUE,  TRUE,  TRUE,  FALSE),
    t2d_date      = data.table::as.IDate(
      c(NA, "2010-01-01", "2018-06-01", NA, NA)),
    date_baseline = data.table::as.IDate("2015-01-01")
  )
}

.followup_dt <- function() {
  data.table::data.table(
    eid           = 1:4,
    t2d_date      = data.table::as.IDate(c("2018-01-01", NA, "2023-01-01", NA)),
    date_baseline = data.table::as.IDate("2008-01-01"),
    date_death    = data.table::as.IDate(c(NA, "2020-06-01", NA, NA)),
    date_lost     = data.table::as.IDate(c(NA, NA, NA, "2019-03-01"))
  )
}

.age_dt <- function() {
  data.table::data.table(
    eid             = 1:4,
    t2d_status      = c(1L, 1L, 0L, 1L),
    t2d_date        = data.table::as.IDate(
      c("2010-01-01", "2018-06-01", NA, "2016-03-15")),
    cvd_status      = c(1L, 0L, 1L, 0L),
    cvd_date        = data.table::as.IDate(
      c("2019-05-01", NA, "2021-11-01", NA)),
    date_baseline   = data.table::as.IDate("2008-01-01"),
    age_recruitment = c(55.0, 62.0, 48.0, 70.0)
  )
}

.case_dt <- function() {
  data.table::data.table(
    eid                 = 1:5,
    t2d_icd10          = c(TRUE,  FALSE, TRUE,  FALSE, TRUE),
    t2d_selfreport     = c(FALSE, TRUE,  TRUE,  FALSE, FALSE),
    t2d_icd10_date     = data.table::as.IDate(
      c("2010-01-01", NA, "2015-06-01", NA, "2018-03-01")),
    t2d_selfreport_date = data.table::as.IDate(
      c(NA, "2012-05-01", "2013-01-01", NA, NA))
  )
}


# =============================================================================
# derive_missing()
# =============================================================================

test_that("derive_missing() stops on non-data.frame input", {
  expect_error(derive_missing("not a df"), "data.frame")
})

test_that("derive_missing() stops on invalid extra_labels type", {
  expect_error(derive_missing(data.table::copy(DT), extra_labels = 123), "character")
})

test_that("derive_missing() action='na': removes all three built-in refusal labels", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_missing(d, action = "na"))
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  refusal   <- c("Do not know", "Prefer not to answer", "Prefer not to say")
  for (col in char_cols) {
    expect_false(any(result[[col]] %in% refusal, na.rm = TRUE),
                 label = paste0("refusal label still present in ", col))
  }
})

test_that("derive_missing() always converts empty string to NA regardless of action", {
  d_na  <- data.table::copy(DT)
  d_unk <- data.table::copy(DT)
  r_na  <- suppressMessages(derive_missing(d_na,  action = "na"))
  r_unk <- suppressMessages(derive_missing(d_unk, action = "unknown"))
  char_cols <- names(r_na)[vapply(r_na, is.character, logical(1L))]
  for (col in char_cols) {
    expect_false(any(r_na[[col]]  == "", na.rm = TRUE))
    expect_false(any(r_unk[[col]] == "", na.rm = TRUE))
  }
})

test_that("derive_missing() action='unknown': converts refusal labels to 'Unknown'", {
  d <- data.table::data.table(
    eid   = 1:4,
    smoke = c("Never", "Prefer not to answer", "Do not know", "Current")
  )
  result <- suppressMessages(derive_missing(d, action = "unknown"))
  expect_equal(result$smoke[2], "Unknown")
  expect_equal(result$smoke[3], "Unknown")
  expect_equal(result$smoke[1], "Never")    # valid label untouched
})

test_that("derive_missing() preserves valid labels and skips numeric columns", {
  d      <- data.table::copy(DT)
  bmi_before <- d$p21001_i0
  result <- suppressMessages(derive_missing(d, action = "na"))
  expect_equal(result$p21001_i0, bmi_before)
})

test_that("derive_missing() extra_labels treated as informative missing", {
  d <- data.table::data.table(
    eid   = 1:3,
    smoke = c("Never", "Not applicable", "Current")
  )
  result <- suppressMessages(
    derive_missing(d, extra_labels = "Not applicable", action = "na")
  )
  expect_true(is.na(result$smoke[2]))
  expect_equal(result$smoke[1], "Never")
})

test_that("derive_missing() returns data.table", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_missing(d))
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_covariate()
# =============================================================================

test_that("derive_covariate() stops on non-data.frame input", {
  expect_error(derive_covariate("not a df"), "data.frame")
})

test_that("derive_covariate() stops on non-list factor_levels", {
  expect_error(
    suppressMessages(derive_covariate(data.table::copy(DT), factor_levels = "bad")),
    "named list"
  )
})

test_that("derive_covariate() converts character column to numeric", {
  d <- data.table::data.table(eid = 1:3, bmi_char = c("22.5", "30.1", "28.4"))
  result <- suppressMessages(derive_covariate(d, as_numeric = "bmi_char"))
  expect_true(is.numeric(result$bmi_char))
  expect_equal(result$bmi_char, c(22.5, 30.1, 28.4))
})

test_that("derive_covariate() converts smoking column to factor using ops_toy data", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_covariate(d, as_factor = "p20116_i0"))
  expect_true(is.factor(result$p20116_i0))
})

test_that("derive_covariate() respects custom factor_levels order", {
  d <- data.table::copy(DT)
  result <- suppressMessages(
    derive_covariate(d, as_factor = "p20116_i0",
                     factor_levels = list(
                       p20116_i0 = c("Never", "Previous", "Current", "Prefer not to answer")
                     ))
  )
  expect_equal(levels(result$p20116_i0)[1], "Never")
  expect_equal(levels(result$p20116_i0)[3], "Current")
})

test_that("derive_covariate() skips missing column with warning", {
  d <- data.table::copy(DT)
  expect_message(
    derive_covariate(d, as_numeric = "nonexistent_col"),
    regexp = "not found|skipped",
    ignore.case = TRUE
  )
})

test_that("derive_covariate() returns data.table", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_covariate(d, as_factor = "p21000_i0"))
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_cut()
# =============================================================================

test_that("derive_cut() stops on non-data.frame input", {
  expect_error(derive_cut("not a df", col = "p21001_i0", n = 3), "data.frame")
})

test_that("derive_cut() stops when col not found", {
  expect_error(
    suppressMessages(derive_cut(data.table::copy(DT), col = "nonexistent", n = 3)),
    "missing column"
  )
})

test_that("derive_cut() stops when n < 2", {
  expect_error(
    suppressMessages(derive_cut(data.table::copy(DT), col = "p21001_i0", n = 1)),
    "2"
  )
})

test_that("derive_cut() stops when breaks length != n - 1", {
  expect_error(
    suppressMessages(derive_cut(data.table::copy(DT), col = "p21001_i0",
                                n = 3, breaks = c(25))),
    "length"
  )
})

test_that("derive_cut() stops when labels length != n", {
  expect_error(
    suppressMessages(derive_cut(data.table::copy(DT), col = "p21001_i0",
                                n = 3, labels = c("low", "high"))),
    "length"
  )
})

test_that("derive_cut() uses correct default name suffix for n = 2/3/4/5", {
  for (spec in list(list(2L, "_bi"), list(3L, "_tri"),
                    list(4L, "_quad"), list(5L, "_quin"))) {
    d   <- data.table::copy(DT)
    res <- suppressMessages(derive_cut(d, col = "p21001_i0", n = spec[[1]]))
    expect_true(paste0("p21001_i0", spec[[2]]) %in% names(res),
                label = paste0("suffix ", spec[[2]], " missing for n=", spec[[1]]))
  }
})

test_that("derive_cut() produces factor with n levels (quantile-based)", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_cut(d, col = "p21001_i0", n = 3))
  expect_true(is.factor(result$p21001_i0_tri))
  expect_equal(nlevels(result$p21001_i0_tri), 3L)
})

test_that("derive_cut() respects custom breaks, labels, and name", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_cut(d, col = "p21001_i0", n = 3,
               breaks = c(25, 30),
               labels = c("Normal", "Overweight", "Obese"),
               name   = "bmi_who")
  )
  expect_true("bmi_who" %in% names(result))
  expect_equal(levels(result$bmi_who), c("Normal", "Overweight", "Obese"))
})

test_that("derive_cut() returns data.table", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_cut(d, col = "p21001_i0", n = 3))
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_selfreport()
# =============================================================================

test_that("derive_selfreport() stops on non-data.frame input", {
  expect_error(
    derive_selfreport("not a df", name = "t2d",
                      regex = "diabetes", field = "noncancer"),
    "data.frame"
  )
})

test_that("derive_selfreport() stops on non-scalar name", {
  expect_error(
    suppressMessages(
      derive_selfreport(data.table::copy(DT), name = c("t2d", "cvd"),
                        regex = "diabetes", field = "noncancer")
    ),
    "single non-empty string"
  )
})

test_that("derive_selfreport() adds {name}_selfreport and {name}_selfreport_date", {
  d      <- data.table::copy(DT)
  sr_d   <- grep("^p20002_i0_a", names(d), value = TRUE)
  sr_t   <- grep("^p20008_i0_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = sr_d,
                      date_cols    = sr_t,
                      visit_cols   = "p53_i0")
  )
  expect_true("t2d_selfreport"      %in% names(result))
  expect_true("t2d_selfreport_date" %in% names(result))
})

test_that("derive_selfreport() date column is IDate", {
  d    <- data.table::copy(DT)
  sr_d <- grep("^p20002_i0_a", names(d), value = TRUE)
  sr_t <- grep("^p20008_i0_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = sr_d,
                      date_cols    = sr_t,
                      visit_cols   = "p53_i0")
  )
  expect_true(inherits(result$t2d_selfreport_date, "Date"))
})

test_that("derive_selfreport() status is logical", {
  d    <- data.table::copy(DT)
  sr_d <- grep("^p20002_i0_a", names(d), value = TRUE)
  sr_t <- grep("^p20008_i0_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = sr_d,
                      date_cols    = sr_t,
                      visit_cols   = "p53_i0")
  )
  expect_true(is.logical(result$t2d_selfreport))
})

test_that("derive_selfreport() cases have non-NA date, non-cases have NA date", {
  d    <- data.table::copy(DT)
  sr_d <- grep("^p20002_i0_a", names(d), value = TRUE)
  sr_t <- grep("^p20008_i0_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = sr_d,
                      date_cols    = sr_t,
                      visit_cols   = "p53_i0")
  )
  # All non-cases must have NA date
  expect_true(all(is.na(result[t2d_selfreport == FALSE, t2d_selfreport_date])))
})

test_that("derive_selfreport() returns FALSE flag when no regex match", {
  d    <- data.table::copy(DT)
  sr_d <- grep("^p20002_i0_a", names(d), value = TRUE)
  sr_t <- grep("^p20008_i0_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_selfreport(d, name = "rare_disease", regex = "^xyzzy_not_real$",
                      field        = "noncancer",
                      disease_cols = sr_d,
                      date_cols    = sr_t,
                      visit_cols   = "p53_i0")
  )
  expect_true(all(!result$rare_disease_selfreport))
})

test_that("derive_selfreport() returns data.table", {
  d    <- data.table::copy(DT)
  sr_d <- grep("^p20002_i0_a", names(d), value = TRUE)
  sr_t <- grep("^p20008_i0_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = sr_d,
                      date_cols    = sr_t,
                      visit_cols   = "p53_i0")
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_first_occurrence()
# =============================================================================

test_that("derive_first_occurrence() stops on non-data.frame input", {
  expect_error(
    derive_first_occurrence("not a df", name = "t2d", field = 131742L),
    "data.frame"
  )
})

test_that("derive_first_occurrence() adds {name}_fo and {name}_fo_date", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d", field = 131742L, col = "p131742")
  )
  expect_true("t2d_fo"      %in% names(result))
  expect_true("t2d_fo_date" %in% names(result))
})

test_that("derive_first_occurrence() status is TRUE only when date is valid", {
  d <- data.table::data.table(
    eid     = 1:4,
    p131742 = c("2010-01-01", NA, "bad-date", "2015-06-01")
  )
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d", field = 131742L, col = "p131742")
  )
  expect_true(result$t2d_fo[1])
  expect_false(result$t2d_fo[2])   # NA
  expect_false(result$t2d_fo[3])   # unparseable → NA → FALSE
  expect_true(result$t2d_fo[4])
})

test_that("derive_first_occurrence() date column is IDate", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d", field = 131742L, col = "p131742")
  )
  expect_true(inherits(result$t2d_fo_date, "Date"))
})

test_that("derive_first_occurrence() aborts when col missing and no cache", {
  d <- data.table::data.table(eid = 1:3, x = 1:3)
  expect_error(
    suppressMessages(derive_first_occurrence(d, name = "t2d", field = 999999L)),
    "Cannot find|not found",
    ignore.case = TRUE
  )
})

test_that("derive_first_occurrence() returns data.table", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d", field = 131742L, col = "p131742")
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_hes()
# =============================================================================

test_that("derive_hes() stops on non-data.frame input", {
  expect_error(derive_hes("not a df", name = "t2d", icd10 = "E11"), "data.frame")
})

test_that("derive_hes() adds {name}_hes and {name}_hes_date columns", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result   <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11",
               disease_cols = "p41270",
               date_cols    = date_cols)
  )
  expect_true("t2d_hes"      %in% names(result))
  expect_true("t2d_hes_date" %in% names(result))
})

test_that("derive_hes() status is logical", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result   <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11",
               disease_cols = "p41270",
               date_cols    = date_cols)
  )
  expect_true(is.logical(result$t2d_hes))
})

test_that("derive_hes() prefix match finds at least some cases in ops_toy data", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result   <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11", match = "prefix",
               disease_cols = "p41270",
               date_cols    = date_cols)
  )
  # ops_toy generates E11 in HES with ~35% having records, multiple ICD codes
  expect_true(sum(result$t2d_hes) > 0L)
})

test_that("derive_hes() date is IDate and NA for non-cases", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result   <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11",
               disease_cols = "p41270",
               date_cols    = date_cols)
  )
  expect_true(inherits(result$t2d_hes_date, "Date"))
  expect_true(all(is.na(result[t2d_hes == FALSE, t2d_hes_date])))
})

test_that("derive_hes() exact match returns subset of prefix match cases", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  r_prefix  <- suppressMessages(
    derive_hes(data.table::copy(d), name = "t2d", icd10 = "E", match = "prefix",
               disease_cols = "p41270", date_cols = date_cols)
  )
  r_exact   <- suppressMessages(
    derive_hes(data.table::copy(d), name = "t2d", icd10 = "E11", match = "exact",
               disease_cols = "p41270", date_cols = date_cols)
  )
  expect_true(sum(r_exact$t2d_hes) <= sum(r_prefix$t2d_hes))
})

test_that("derive_hes() returns data.table", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result   <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11",
               disease_cols = "p41270",
               date_cols    = date_cols)
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_cancer_registry()
# =============================================================================

test_that("derive_cancer_registry() stops on non-data.frame input", {
  expect_error(
    derive_cancer_registry("not a df", name = "skin", icd10 = "^C44"),
    "data.frame"
  )
})

test_that("derive_cancer_registry() stops on non-scalar icd10 regex", {
  d <- data.table::copy(DT)
  expect_error(
    suppressMessages(
      derive_cancer_registry(d, name = "skin", icd10 = c("^C44", "^C50"))
    ),
    "single regex"
  )
})

test_that("derive_cancer_registry() adds {name}_cancer and {name}_cancer_date", {
  d    <- data.table::copy(DT)
  code <- grep("^p40006_i", names(d), value = TRUE)
  hist <- grep("^p40011_i", names(d), value = TRUE)
  behv <- grep("^p40012_i", names(d), value = TRUE)
  date <- grep("^p40005_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_cancer_registry(d, name = "skin", icd10 = "^C44",
                           code_cols = code, hist_cols = hist,
                           behv_cols = behv, date_cols = date)
  )
  expect_true("skin_cancer"      %in% names(result))
  expect_true("skin_cancer_date" %in% names(result))
})

test_that("derive_cancer_registry() status is logical and date is IDate", {
  d    <- data.table::copy(DT)
  code <- grep("^p40006_i", names(d), value = TRUE)
  hist <- grep("^p40011_i", names(d), value = TRUE)
  behv <- grep("^p40012_i", names(d), value = TRUE)
  date <- grep("^p40005_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_cancer_registry(d, name = "skin", icd10 = "^C44",
                           code_cols = code, hist_cols = hist,
                           behv_cols = behv, date_cols = date)
  )
  expect_true(is.logical(result$skin_cancer))
  expect_true(inherits(result$skin_cancer_date, "Date"))
})

test_that("derive_cancer_registry() behaviour filter narrows case count", {
  d    <- data.table::copy(DT)
  code <- grep("^p40006_i", names(d), value = TRUE)
  hist <- grep("^p40011_i", names(d), value = TRUE)
  behv <- grep("^p40012_i", names(d), value = TRUE)
  date <- grep("^p40005_i", names(d), value = TRUE)
  r_all     <- suppressMessages(
    derive_cancer_registry(data.table::copy(d), name = "skin",  icd10 = "^C44",
                           code_cols = code, hist_cols = hist,
                           behv_cols = behv, date_cols = date)
  )
  r_malign  <- suppressMessages(
    derive_cancer_registry(data.table::copy(d), name = "skin2", icd10 = "^C44",
                           behaviour = 3L,
                           code_cols = code, hist_cols = hist,
                           behv_cols = behv, date_cols = date)
  )
  expect_true(sum(r_malign$skin2_cancer) <= sum(r_all$skin_cancer))
})

test_that("derive_cancer_registry() non-cases have NA date", {
  d    <- data.table::copy(DT)
  code <- grep("^p40006_i", names(d), value = TRUE)
  hist <- grep("^p40011_i", names(d), value = TRUE)
  behv <- grep("^p40012_i", names(d), value = TRUE)
  date <- grep("^p40005_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_cancer_registry(d, name = "skin", icd10 = "^C44",
                           code_cols = code, hist_cols = hist,
                           behv_cols = behv, date_cols = date)
  )
  expect_true(all(is.na(result[skin_cancer == FALSE, skin_cancer_date])))
})

test_that("derive_cancer_registry() returns data.table", {
  d    <- data.table::copy(DT)
  code <- grep("^p40006_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_cancer_registry(d, name = "skin", icd10 = "^C44", code_cols = code)
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_death_registry()
# =============================================================================

test_that("derive_death_registry() stops on non-data.frame input", {
  expect_error(
    derive_death_registry("not a df", name = "cvd", icd10 = "I21"),
    "data.frame"
  )
})

test_that("derive_death_registry() adds {name}_death and {name}_death_date", {
  d    <- data.table::copy(DT)
  pri  <- grep("^p40001_i", names(d), value = TRUE)
  sec  <- grep("^p40002_i", names(d), value = TRUE)
  dts  <- grep("^p40000_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_death_registry(d, name = "cvd", icd10 = "I",
                          primary_cols   = pri,
                          secondary_cols = sec,
                          date_cols      = dts)
  )
  expect_true("cvd_death"      %in% names(result))
  expect_true("cvd_death_date" %in% names(result))
})

test_that("derive_death_registry() status is logical and date is IDate", {
  d    <- data.table::copy(DT)
  pri  <- grep("^p40001_i", names(d), value = TRUE)
  sec  <- grep("^p40002_i", names(d), value = TRUE)
  dts  <- grep("^p40000_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_death_registry(d, name = "cvd", icd10 = "I",
                          primary_cols   = pri,
                          secondary_cols = sec,
                          date_cols      = dts)
  )
  expect_true(is.logical(result$cvd_death))
  expect_true(inherits(result$cvd_death_date, "Date"))
})

test_that("derive_death_registry() exact match is subset of prefix match", {
  d   <- data.table::copy(DT)
  pri <- grep("^p40001_i", names(d), value = TRUE)
  sec <- grep("^p40002_i", names(d), value = TRUE)
  dts <- grep("^p40000_i", names(d), value = TRUE)
  r_prefix <- suppressMessages(
    derive_death_registry(data.table::copy(d), name = "cvd",  icd10 = "I",
                          match = "prefix",
                          primary_cols = pri, secondary_cols = sec, date_cols = dts)
  )
  r_exact  <- suppressMessages(
    derive_death_registry(data.table::copy(d), name = "cvd2", icd10 = "I25.9",
                          match = "exact",
                          primary_cols = pri, secondary_cols = sec, date_cols = dts)
  )
  expect_true(sum(r_exact$cvd2_death) <= sum(r_prefix$cvd_death))
})

test_that("derive_death_registry() non-cases have NA date", {
  d   <- data.table::copy(DT)
  pri <- grep("^p40001_i", names(d), value = TRUE)
  sec <- grep("^p40002_i", names(d), value = TRUE)
  dts <- grep("^p40000_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_death_registry(d, name = "cvd", icd10 = "I",
                          primary_cols = pri, secondary_cols = sec, date_cols = dts)
  )
  expect_true(all(is.na(result[cvd_death == FALSE, cvd_death_date])))
})

test_that("derive_death_registry() returns data.table", {
  d   <- data.table::copy(DT)
  pri <- grep("^p40001_i", names(d), value = TRUE)
  sec <- grep("^p40002_i", names(d), value = TRUE)
  dts <- grep("^p40000_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_death_registry(d, name = "cvd", icd10 = "I",
                          primary_cols = pri, secondary_cols = sec, date_cols = dts)
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_icd10()
# =============================================================================

test_that("derive_icd10() adds {name}_icd10 and {name}_icd10_date", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  pri       <- grep("^p40001_i", names(d), value = TRUE)
  sec       <- grep("^p40002_i", names(d), value = TRUE)
  dts       <- grep("^p40000_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source          = c("hes", "death"),
                 hes_code_col    = "p41270",
                 hes_date_cols   = date_cols,
                 primary_cols    = pri,
                 secondary_cols  = sec,
                 death_date_cols = dts)
  )
  expect_true("t2d_icd10"      %in% names(result))
  expect_true("t2d_icd10_date" %in% names(result))
})

test_that("derive_icd10() retains intermediate source columns", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result <- suppressMessages(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source       = "hes",
                 hes_code_col = "p41270",
                 hes_date_cols = date_cols)
  )
  expect_true("t2d_hes"      %in% names(result))
  expect_true("t2d_hes_date" %in% names(result))
})

test_that("derive_icd10() combined count >= any single source count", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  pri       <- grep("^p40001_i", names(d), value = TRUE)
  sec       <- grep("^p40002_i", names(d), value = TRUE)
  dts       <- grep("^p40000_i", names(d), value = TRUE)
  result <- suppressMessages(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source          = c("hes", "death"),
                 hes_code_col    = "p41270",
                 hes_date_cols   = date_cols,
                 primary_cols    = pri,
                 secondary_cols  = sec,
                 death_date_cols = dts)
  )
  expect_true(sum(result$t2d_icd10) >= sum(result$t2d_hes))
  expect_true(sum(result$t2d_icd10) >= sum(result$t2d_death))
})

test_that("derive_icd10() warns when first_occurrence selected without fo_field/fo_col", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  expect_message(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source        = c("hes", "first_occurrence"),
                 hes_code_col  = "p41270",
                 hes_date_cols = date_cols),
    regexp = "fo_field|fo_col|skipping",
    ignore.case = TRUE
  )
})

test_that("derive_icd10() returns data.table", {
  d        <- data.table::copy(DT)
  date_cols <- grep("^p41280_a", names(d), value = TRUE)
  result   <- suppressMessages(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source       = "hes",
                 hes_code_col = "p41270",
                 hes_date_cols = date_cols)
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_case()
# =============================================================================

test_that("derive_case() stops on non-data.frame input", {
  expect_error(derive_case("not a df", name = "t2d"), "data.frame")
})

test_that("derive_case() aborts when neither status column found", {
  d <- data.table::data.table(eid = 1:3, x = 1:3)
  expect_error(
    suppressMessages(derive_case(d, name = "t2d")),
    "not found|found in data",
    ignore.case = TRUE
  )
})

test_that("derive_case() adds {name}_status and {name}_date", {
  d      <- .case_dt()
  result <- suppressMessages(derive_case(d, name = "t2d"))
  expect_true("t2d_status" %in% names(result))
  expect_true("t2d_date"   %in% names(result))
})

test_that("derive_case() OR-combines status correctly", {
  d      <- .case_dt()
  result <- suppressMessages(derive_case(d, name = "t2d"))
  expect_true(result$t2d_status[1])    # icd10 only
  expect_true(result$t2d_status[2])    # selfreport only
  expect_true(result$t2d_status[3])    # both
  expect_false(result$t2d_status[4])   # neither
  expect_true(result$t2d_status[5])    # icd10 only
})

test_that("derive_case() takes earliest date across sources", {
  d      <- .case_dt()
  result <- suppressMessages(derive_case(d, name = "t2d"))
  # Row 3: icd10_date=2015-06-01, selfreport_date=2013-01-01 → 2013-01-01
  expect_equal(result$t2d_date[3], data.table::as.IDate("2013-01-01"))
  # Row 1: icd10_date=2010-01-01, selfreport_date=NA → 2010-01-01
  expect_equal(result$t2d_date[1], data.table::as.IDate("2010-01-01"))
})

test_that("derive_case() returns data.table", {
  d      <- .case_dt()
  result <- suppressMessages(derive_case(d, name = "t2d"))
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_age()
# =============================================================================

test_that("derive_age() stops on non-data.frame input", {
  expect_error(
    derive_age("not a df", name = "t2d",
               baseline_col = "date_baseline", age_col = "age_recruitment"),
    "data.frame"
  )
})

test_that("derive_age() stops on empty name", {
  d <- .age_dt()
  expect_error(
    derive_age(d, name = character(0),
               baseline_col = "date_baseline", age_col = "age_recruitment"),
    "non-empty"
  )
})

test_that("derive_age() stops when baseline_col missing", {
  d <- .age_dt()
  expect_error(
    derive_age(d, name = "t2d",
               baseline_col = "nonexistent", age_col = "age_recruitment"),
    "nonexistent"
  )
})

test_that("derive_age() adds age_at_{name} column", {
  d      <- .age_dt()
  result <- suppressMessages(
    derive_age(d, name = "t2d",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true("age_at_t2d" %in% names(result))
})

test_that("derive_age() computes correct age for integer-status case", {
  d      <- .age_dt()
  result <- suppressMessages(
    derive_age(d, name = "t2d",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  # Row 1: age=55, date=2010-01-01, baseline=2008-01-01
  expected <- 55 + as.numeric(
    data.table::as.IDate("2010-01-01") - data.table::as.IDate("2008-01-01")
  ) / 365.25
  expect_equal(result$age_at_t2d[1], expected)
})

test_that("derive_age() returns NA for non-cases (status = 0)", {
  d      <- .age_dt()
  result <- suppressMessages(
    derive_age(d, name = "t2d",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true(is.na(result$age_at_t2d[3]))
})

test_that("derive_age() handles logical status column", {
  d <- data.table::data.table(
    eid             = 1:3,
    t2d             = c(TRUE, FALSE, TRUE),
    t2d_date        = data.table::as.IDate(c("2012-06-01", NA, "2017-09-01")),
    date_baseline   = data.table::as.IDate("2010-01-01"),
    age_recruitment = c(50.0, 60.0, 55.0)
  )
  result <- suppressMessages(
    derive_age(d, name = "t2d",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_false(is.na(result$age_at_t2d[1]))
  expect_true(is.na(result$age_at_t2d[2]))   # FALSE → NA
})

test_that("derive_age() processes multiple names in one call", {
  d      <- .age_dt()
  result <- suppressMessages(
    derive_age(d, name = c("t2d", "cvd"),
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true("age_at_t2d" %in% names(result))
  expect_true("age_at_cvd" %in% names(result))
})

test_that("derive_age() warns and skips when date column not found", {
  d <- .age_dt()
  expect_message(
    derive_age(d, name = "unknown_outcome",
               baseline_col = "date_baseline", age_col = "age_recruitment"),
    regexp = "not found|skipping",
    ignore.case = TRUE
  )
  expect_false("age_at_unknown_outcome" %in% names(d))
})

test_that("derive_age() returns data.table", {
  d      <- .age_dt()
  result <- suppressMessages(
    derive_age(d, name = "t2d",
               baseline_col = "date_baseline", age_col = "age_recruitment")
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_followup()
# =============================================================================

test_that("derive_followup() stops on non-data.frame input", {
  expect_error(
    derive_followup("not a df", name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01")),
    "data.frame"
  )
})

test_that("derive_followup() stops when event_col missing", {
  d <- .followup_dt()
  expect_error(
    suppressMessages(
      derive_followup(d, name = "t2d", event_col = "nonexistent",
                      baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"))
    ),
    "nonexistent"
  )
})

test_that("derive_followup() adds {name}_followup_end and {name}_followup_years", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"))
  )
  expect_true("t2d_followup_end"   %in% names(result))
  expect_true("t2d_followup_years" %in% names(result))
})

test_that("derive_followup() end = event_date when event precedes censor", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"),
                    death_col = "date_death", lost_col = "date_lost")
  )
  # Row 1: t2d 2018-01-01 < censor
  expect_equal(result$t2d_followup_end[1], data.table::as.IDate("2018-01-01"))
})

test_that("derive_followup() end = censor_date when event exceeds censor", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"),
                    death_col = "date_death", lost_col = "date_lost")
  )
  # Row 3: t2d 2023-01-01 > censor
  expect_equal(result$t2d_followup_end[3], data.table::as.IDate("2022-06-01"))
})

test_that("derive_followup() end = death_date when death precedes censor", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"),
                    death_col = "date_death", lost_col = "date_lost")
  )
  # Row 2: no t2d, death 2020-06-01 < censor
  expect_equal(result$t2d_followup_end[2], data.table::as.IDate("2020-06-01"))
})

test_that("derive_followup() end = lost_date when lost precedes censor", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"),
                    death_col = "date_death", lost_col = "date_lost")
  )
  # Row 4: no t2d, no death, lost 2019-03-01 < censor
  expect_equal(result$t2d_followup_end[4], data.table::as.IDate("2019-03-01"))
})

test_that("derive_followup() followup_years computed correctly", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"))
  )
  expected <- as.numeric(
    data.table::as.IDate("2018-01-01") - data.table::as.IDate("2008-01-01")
  ) / 365.25
  expect_equal(result$t2d_followup_years[1], expected)
})

test_that("derive_followup() followup_years all positive and finite", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"))
  )
  yrs <- result$t2d_followup_years
  expect_true(all(yrs > 0, na.rm = TRUE))
  expect_true(all(is.finite(yrs)))
})

test_that("derive_followup() accepts character censor_date", {
  d <- .followup_dt()
  expect_no_error(
    suppressMessages(
      derive_followup(d, name = "t2d", event_col = "t2d_date",
                      baseline_col = "date_baseline", censor_date = "2022-06-01")
    )
  )
})

test_that("derive_followup() returns data.table", {
  d      <- .followup_dt()
  result <- suppressMessages(
    derive_followup(d, name = "t2d", event_col = "t2d_date",
                    baseline_col = "date_baseline", censor_date = as.Date("2022-06-01"))
  )
  expect_true(data.table::is.data.table(result))
})


# =============================================================================
# derive_timing()
# =============================================================================

test_that("derive_timing() stops on non-data.frame input", {
  expect_error(
    derive_timing("not a df", name = "t2d", baseline_col = "date_baseline"),
    "data.frame"
  )
})

test_that("derive_timing() stops when required column missing", {
  d <- .timing_dt()
  expect_error(
    suppressMessages(derive_timing(d, name = "t2d", baseline_col = "nonexistent")),
    "nonexistent"
  )
})

test_that("derive_timing() adds {name}_timing column", {
  d      <- .timing_dt()
  result <- suppressMessages(
    derive_timing(d, name = "t2d", baseline_col = "date_baseline")
  )
  expect_true("t2d_timing" %in% names(result))
})

test_that("derive_timing() codes 0 for no-disease rows", {
  d      <- .timing_dt()
  result <- suppressMessages(
    derive_timing(d, name = "t2d", baseline_col = "date_baseline")
  )
  expect_equal(result$t2d_timing[1], 0L)
  expect_equal(result$t2d_timing[5], 0L)
})

test_that("derive_timing() codes 1 for prevalent (date <= baseline)", {
  d      <- .timing_dt()
  result <- suppressMessages(
    derive_timing(d, name = "t2d", baseline_col = "date_baseline")
  )
  # Row 2: t2d_date 2010-01-01 < baseline 2015-01-01 → prevalent
  expect_equal(result$t2d_timing[2], 1L)
})

test_that("derive_timing() codes 2 for incident (date > baseline)", {
  d      <- .timing_dt()
  result <- suppressMessages(
    derive_timing(d, name = "t2d", baseline_col = "date_baseline")
  )
  # Row 3: t2d_date 2018-06-01 > baseline 2015-01-01 → incident
  expect_equal(result$t2d_timing[3], 2L)
})

test_that("derive_timing() codes NA when case has no date", {
  d      <- .timing_dt()
  result <- suppressMessages(
    derive_timing(d, name = "t2d", baseline_col = "date_baseline")
  )
  # Row 4: status TRUE but date NA
  expect_true(is.na(result$t2d_timing[4]))
})

test_that("derive_timing() respects explicit status_col and date_col overrides", {
  d <- data.table::data.table(
    eid           = 1:2,
    my_status     = c(TRUE, FALSE),
    my_date       = data.table::as.IDate(c("2012-01-01", NA)),
    date_baseline = data.table::as.IDate("2015-01-01")
  )
  result <- suppressMessages(
    derive_timing(d, name = "x",
                  status_col   = "my_status",
                  date_col     = "my_date",
                  baseline_col = "date_baseline")
  )
  expect_equal(result$x_timing[1], 1L)   # prevalent
  expect_equal(result$x_timing[2], 0L)   # no disease
})

test_that("derive_timing() returns data.table", {
  d      <- .timing_dt()
  result <- suppressMessages(
    derive_timing(d, name = "t2d", baseline_col = "date_baseline")
  )
  expect_true(data.table::is.data.table(result))
})
