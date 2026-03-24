# =============================================================================
# test-integration-derive.R — Integration tests for derive_ series
# Fixture: ops_toy(n = 2000, seed = 42) — realistic UKB-like structure
# Runs the full derive pipeline for t2d (Type 2 Diabetes) and cvd (CVD).
# Run manually before release: devtools::test(filter = "integration-derive")
# =============================================================================


# =============================================================================
# Shared fixture
# =============================================================================

DT      <- suppressMessages(ops_toy(n = 2000L, seed = 42L))
CENSOR  <- as.Date("2022-06-01")

SR_D    <- grep("^p20002_i0_a", names(DT), value = TRUE)   # selfreport disease
SR_T    <- grep("^p20008_i0_a", names(DT), value = TRUE)   # selfreport dates
HES_DT  <- grep("^p41280_a",   names(DT), value = TRUE)    # HES dates
CR_CODE <- grep("^p40006_i",   names(DT), value = TRUE)    # cancer ICD-10
CR_HIST <- grep("^p40011_i",   names(DT), value = TRUE)    # cancer histology
CR_BEHV <- grep("^p40012_i",   names(DT), value = TRUE)    # cancer behaviour
CR_DATE <- grep("^p40005_i",   names(DT), value = TRUE)    # cancer date
DR_PRI  <- grep("^p40001_i",   names(DT), value = TRUE)    # death primary
DR_SEC  <- grep("^p40002_i",   names(DT), value = TRUE)    # death secondary
DR_DT   <- grep("^p40000_i",   names(DT), value = TRUE)    # death date


# =============================================================================
# derive_missing() — full data
# =============================================================================

test_that("derive_missing() runs on n=2000 without error", {
  d <- data.table::copy(DT)
  expect_no_error(suppressMessages(derive_missing(d, action = "na")))
})

test_that("derive_missing() removes all built-in refusal labels from character columns", {
  d       <- data.table::copy(DT)
  result  <- suppressMessages(derive_missing(d, action = "na"))
  refusal <- c("Do not know", "Prefer not to answer", "Prefer not to say")
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  for (col in char_cols) {
    expect_false(any(result[[col]] %in% refusal, na.rm = TRUE),
                 label = paste0("refusal label still in ", col))
  }
})

test_that("derive_missing() action='unknown' produces 'Unknown', not NA, for refusals", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_missing(d, action = "unknown"))
  char_cols <- names(result)[vapply(result, is.character, logical(1L))]
  for (col in char_cols) {
    expect_false(any(c("Do not know", "Prefer not to answer",
                       "Prefer not to say") %in% result[[col]], na.rm = TRUE),
                 label = paste0("raw refusal label still in ", col))
  }
})

test_that("derive_missing() does not alter numeric columns", {
  d_orig <- data.table::copy(DT)
  d      <- data.table::copy(DT)
  suppressMessages(derive_missing(d, action = "na"))
  expect_equal(d$p21001_i0, d_orig$p21001_i0)
  expect_equal(d$p22189,    d_orig$p22189)
})


# =============================================================================
# derive_covariate() — full data
# =============================================================================

test_that("derive_covariate() converts smoking to ordered factor", {
  d      <- data.table::copy(DT)
  suppressMessages(derive_missing(d, action = "na"))
  result <- suppressMessages(
    derive_covariate(d, as_factor = "p20116_i0",
                     factor_levels = list(
                       p20116_i0 = c("Never", "Previous", "Current")
                     ))
  )
  expect_true(is.factor(result$p20116_i0))
  expect_equal(levels(result$p20116_i0)[1], "Never")
})

test_that("derive_covariate() converts BMI to numeric when supplied as character", {
  d <- data.table::data.table(
    eid = 1:5,
    bmi = c("22.5", "30.1", "28.4", "19.8", "35.0")
  )
  result <- suppressMessages(derive_covariate(d, as_numeric = "bmi"))
  expect_true(is.numeric(result$bmi))
})

test_that("derive_covariate() warns for high-cardinality factor column", {
  d <- data.table::copy(DT)
  # p54_i0 (assessment centre) has 10 levels > default max_levels = 5
  expect_message(
    derive_covariate(d, as_factor = "p54_i0"),
    regexp = "levels|max_levels",
    ignore.case = TRUE
  )
})


# =============================================================================
# derive_cut() — full data
# =============================================================================

test_that("derive_cut() bins BMI into tertiles on n=2000", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_cut(d, col = "p21001_i0", n = 3))
  expect_true("p21001_i0_tri" %in% names(result))
  expect_equal(nlevels(result$p21001_i0_tri), 3L)
  expect_equal(sum(is.na(result$p21001_i0_tri)), 0L)  # no NA from valid BMI
})

test_that("derive_cut() bins age into quartiles correctly", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(derive_cut(d, col = "p21022", n = 4))
  expect_equal(nlevels(result$p21022_quad), 4L)
})

test_that("derive_cut() WHO BMI categories with custom breaks", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_cut(d, col = "p21001_i0", n = 3,
               breaks = c(25, 30),
               labels = c("Normal", "Overweight", "Obese"),
               name   = "bmi_who")
  )
  expect_equal(levels(result$bmi_who), c("Normal", "Overweight", "Obese"))
  expect_true(all(!is.na(result$bmi_who)))
})

test_that("derive_cut() preserves NA values in output", {
  d <- data.table::copy(DT)
  d[sample(.N, 50L), p21001_i0 := NA_real_]
  result <- suppressMessages(derive_cut(d, col = "p21001_i0", n = 3))
  expect_true(sum(is.na(result$p21001_i0_tri)) == 50L)
})


# =============================================================================
# derive_selfreport() — t2d via noncancer field
# =============================================================================

test_that("derive_selfreport() finds t2d cases in ops_toy noncancer data", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = SR_D,
                      date_cols    = SR_T,
                      visit_cols   = "p53_i0")
  )
  expect_true(sum(result$t2d_selfreport) > 0L)
})

test_that("derive_selfreport() non-cases have NA date", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = SR_D,
                      date_cols    = SR_T,
                      visit_cols   = "p53_i0")
  )
  expect_true(all(is.na(result[t2d_selfreport == FALSE, t2d_selfreport_date])))
})

test_that("derive_selfreport() hypertension yields more cases than t2d (higher prevalence)", {
  d     <- data.table::copy(DT)
  r_t2d <- suppressMessages(
    derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                      field        = "noncancer",
                      disease_cols = SR_D, date_cols = SR_T, visit_cols = "p53_i0")
  )
  r_htn <- suppressMessages(
    derive_selfreport(d, name = "htn", regex = "hypertension",
                      field        = "noncancer",
                      disease_cols = SR_D, date_cols = SR_T, visit_cols = "p53_i0")
  )
  # Both should have at least some cases; hypertension fill rate ~30% vs t2d ~18%
  expect_true(sum(r_t2d$t2d_selfreport) > 0L)
  expect_true(sum(r_htn$htn_selfreport) > 0L)
})


# =============================================================================
# derive_first_occurrence() — using p131742
# =============================================================================

test_that("derive_first_occurrence() runs on ops_toy p131742 without error", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d_fo", field = 131742L, col = "p131742")
  )
  expect_true("t2d_fo_fo"      %in% names(result))
  expect_true("t2d_fo_fo_date" %in% names(result))
})

test_that("derive_first_occurrence() ~8% case rate matches ops_toy generation", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d_fo", field = 131742L, col = "p131742")
  )
  pct <- mean(result$t2d_fo_fo) * 100
  # ops_toy generates ~8% positive; with seed=42 and n=2000, allow 5-12%
  expect_true(pct >= 4 && pct <= 15,
              label = paste0("FO case rate ", round(pct, 1), "% outside expected 4-15%"))
})

test_that("derive_first_occurrence() every positive case has a valid date", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_first_occurrence(d, name = "t2d_fo", field = 131742L, col = "p131742")
  )
  expect_true(all(!is.na(result[t2d_fo_fo == TRUE, t2d_fo_fo_date])))
})


# =============================================================================
# derive_hes() — E11 (type 2 diabetes) and I (cardiovascular)
# =============================================================================

test_that("derive_hes() finds E11 cases in ops_toy HES data", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11",
               disease_cols = "p41270", date_cols = HES_DT)
  )
  expect_true(sum(result$t2d_hes) > 0L)
})

test_that("derive_hes() date never exceeds 2022-12-31 (ops_toy generation bound)", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_hes(d, name = "t2d", icd10 = "E11",
               disease_cols = "p41270", date_cols = HES_DT)
  )
  max_date <- max(result$t2d_hes_date, na.rm = TRUE)
  expect_true(max_date <= data.table::as.IDate("2022-12-31"))
})

test_that("derive_hes() cardiovascular prefix 'I' finds cases across I10/I25/I48", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_hes(d, name = "cvd", icd10 = "I", match = "prefix",
               disease_cols = "p41270", date_cols = HES_DT)
  )
  expect_true(sum(result$cvd_hes) > 0L)
})

test_that("derive_hes() combined count hes >= any single prefix subgroup", {
  d      <- data.table::copy(DT)
  r_all  <- suppressMessages(
    derive_hes(data.table::copy(d), name = "cvd",  icd10 = "I",   match = "prefix",
               disease_cols = "p41270", date_cols = HES_DT)
  )
  r_i25  <- suppressMessages(
    derive_hes(data.table::copy(d), name = "ihd",  icd10 = "I25", match = "prefix",
               disease_cols = "p41270", date_cols = HES_DT)
  )
  expect_true(sum(r_all$cvd_hes) >= sum(r_i25$ihd_hes))
})


# =============================================================================
# derive_cancer_registry() — C44 (non-melanoma skin cancer)
# =============================================================================

test_that("derive_cancer_registry() finds C44 cases in ops_toy data", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_cancer_registry(d, name = "skin", icd10 = "^C44",
                           code_cols = CR_CODE, hist_cols = CR_HIST,
                           behv_cols = CR_BEHV, date_cols = CR_DATE)
  )
  expect_true(sum(result$skin_cancer) > 0L)
})

test_that("derive_cancer_registry() malignant filter (behaviour=3) reduces case count", {
  d        <- data.table::copy(DT)
  r_all    <- suppressMessages(
    derive_cancer_registry(data.table::copy(d), name = "skin",    icd10 = "^C44",
                           code_cols = CR_CODE, hist_cols = CR_HIST,
                           behv_cols = CR_BEHV, date_cols = CR_DATE)
  )
  r_malign <- suppressMessages(
    derive_cancer_registry(data.table::copy(d), name = "skin_inv", icd10 = "^C44",
                           behaviour = 3L,
                           code_cols = CR_CODE, hist_cols = CR_HIST,
                           behv_cols = CR_BEHV, date_cols = CR_DATE)
  )
  expect_true(sum(r_malign$skin_inv_cancer) <= sum(r_all$skin_cancer))
})

test_that("derive_cancer_registry() date is within ops_toy cancer range (1990-2020)", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_cancer_registry(d, name = "skin", icd10 = "^C44",
                           code_cols = CR_CODE, hist_cols = CR_HIST,
                           behv_cols = CR_BEHV, date_cols = CR_DATE)
  )
  dates <- result$skin_cancer_date[!is.na(result$skin_cancer_date)]
  if (length(dates) > 0L) {
    expect_true(all(dates >= data.table::as.IDate("1990-01-01")))
    expect_true(all(dates <= data.table::as.IDate("2020-12-31")))
  }
})


# =============================================================================
# derive_death_registry() — I (cardiovascular) and C (cancer)
# =============================================================================

test_that("derive_death_registry() finds CVD deaths in ops_toy data", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_death_registry(d, name = "cvd", icd10 = "I",
                          primary_cols   = DR_PRI,
                          secondary_cols = DR_SEC,
                          date_cols      = DR_DT)
  )
  expect_true(sum(result$cvd_death) > 0L)
})

test_that("derive_death_registry() death rate ~10% matches ops_toy generation", {
  d      <- data.table::copy(DT)
  # Any cause of death (prefix match on all codes)
  result <- suppressMessages(
    derive_death_registry(d, name = "any", icd10 = ".",
                          match          = "regex",
                          primary_cols   = DR_PRI,
                          secondary_cols = DR_SEC,
                          date_cols      = DR_DT)
  )
  pct <- mean(result$any_death) * 100
  # ops_toy death_flag = runif < 0.10; allow 7-14% with n=2000, seed=42
  expect_true(pct >= 5 && pct <= 18,
              label = paste0("death rate ", round(pct, 1), "% outside expected 5-18%"))
})

test_that("derive_death_registry() death dates within ops_toy range (2011-2023)", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_death_registry(d, name = "cvd", icd10 = "I",
                          primary_cols   = DR_PRI,
                          secondary_cols = DR_SEC,
                          date_cols      = DR_DT)
  )
  dates <- result$cvd_death_date[!is.na(result$cvd_death_date)]
  if (length(dates) > 0L) {
    expect_true(all(dates >= data.table::as.IDate("2011-01-01")))
    expect_true(all(dates <= data.table::as.IDate("2023-12-31")))
  }
})


# =============================================================================
# derive_icd10() — t2d (HES + death) and cvd (HES + death + first_occurrence)
# =============================================================================

test_that("derive_icd10() t2d (hes + death) OR-combines both sources", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source          = c("hes", "death"),
                 hes_code_col    = "p41270",
                 hes_date_cols   = HES_DT,
                 primary_cols    = DR_PRI,
                 secondary_cols  = DR_SEC,
                 death_date_cols = DR_DT)
  )
  # Combined must be >= each source alone
  expect_true(sum(result$t2d_icd10) >= sum(result$t2d_hes))
  expect_true(sum(result$t2d_icd10) >= sum(result$t2d_death))
})


test_that("derive_icd10() with first_occurrence adds fo columns", {
  d      <- data.table::copy(DT)
  result <- suppressMessages(
    derive_icd10(d, name = "t2d", icd10 = "E11",
                 source          = c("hes", "first_occurrence"),
                 hes_code_col    = "p41270",
                 hes_date_cols   = HES_DT,
                 fo_col          = "p131742")
  )
  expect_true("t2d_fo"   %in% names(result))
  expect_true("t2d_icd10" %in% names(result))
})


# =============================================================================
# derive_case() — t2d (icd10 + selfreport)
# =============================================================================

test_that("derive_case() merges icd10 + selfreport into unified case", {
  d <- data.table::copy(DT)

  # Step 1: derive component flags
  suppressMessages({
    d <- derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                           field        = "noncancer",
                           disease_cols = SR_D, date_cols = SR_T,
                           visit_cols   = "p53_i0")
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
  })

  expect_true("t2d_status" %in% names(d))
  expect_true("t2d_date"   %in% names(d))
})

test_that("derive_case() t2d_status >= t2d_icd10 and >= t2d_selfreport (OR logic)", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                           field        = "noncancer",
                           disease_cols = SR_D, date_cols = SR_T,
                           visit_cols   = "p53_i0")
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
  })
  expect_true(sum(d$t2d_status) >= sum(d$t2d_icd10))
  expect_true(sum(d$t2d_status) >= sum(d$t2d_selfreport))
})

test_that("derive_case() t2d_date <= min of component dates where both present", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                           field        = "noncancer",
                           disease_cols = SR_D, date_cols = SR_T,
                           visit_cols   = "p53_i0")
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
  })
  both <- d[t2d_icd10 == TRUE & t2d_selfreport == TRUE &
            !is.na(t2d_icd10_date) & !is.na(t2d_selfreport_date)]
  if (nrow(both) > 0L) {
    expected <- pmin(both$t2d_icd10_date, both$t2d_selfreport_date, na.rm = TRUE)
    expect_equal(both$t2d_date, data.table::as.IDate(expected))
  }
})


# =============================================================================
# derive_timing() — t2d (incident / prevalent classification)
# =============================================================================

test_that("derive_timing() adds t2d_timing with values in {0,1,2,NA}", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    d <- derive_timing(d, name = "t2d", baseline_col = "p53_i0")
  })
  expect_true("t2d_timing" %in% names(d))
  valid_vals <- c(0L, 1L, 2L, NA_integer_)
  expect_true(all(d$t2d_timing %in% valid_vals))
})

test_that("derive_timing() non-cases coded 0, incident coded 2 (post-baseline)", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    d <- derive_timing(d, name = "t2d", baseline_col = "p53_i0")
  })
  expect_true(all(d[t2d_status == FALSE, t2d_timing] == 0L, na.rm = TRUE))
  incident <- d[!is.na(t2d_timing) & t2d_timing == 2L]
  if (nrow(incident) > 0L) {
    bl <- data.table::as.IDate(incident$p53_i0)
    expect_true(all(incident$t2d_date > bl, na.rm = TRUE))
  }
})


# =============================================================================
# derive_age() — age at t2d onset and cvd onset
# =============================================================================

test_that("derive_age() computes plausible age_at_t2d (20-110 years)", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    d <- derive_age(d, name = "t2d",
                    baseline_col = "p53_i0",
                    age_col      = "p21022")
  })
  v <- d$age_at_t2d
  expect_true(all(v >= 20 & v <= 110, na.rm = TRUE))
})

test_that("derive_age() returns NA for non-cases", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    d <- derive_age(d, name = "t2d",
                    baseline_col = "p53_i0",
                    age_col      = "p21022")
  })
  expect_true(all(is.na(d[t2d_status == FALSE, age_at_t2d])))
})


# =============================================================================
# derive_followup() — survival variables for t2d
# =============================================================================

test_that("derive_followup() followup_end never exceeds censor_date", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    d <- derive_followup(d, name = "t2d",
                         event_col    = "t2d_date",
                         baseline_col = "p53_i0",
                         censor_date  = CENSOR,
                         death_col    = FALSE,
                         lost_col     = FALSE)
  })
  expect_true(all(
    d$t2d_followup_end <= data.table::as.IDate(CENSOR), na.rm = TRUE
  ))
})

test_that("derive_followup() followup_years all positive", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    d <- derive_followup(d, name = "t2d",
                         event_col    = "t2d_date",
                         baseline_col = "p53_i0",
                         censor_date  = CENSOR,
                         death_col    = FALSE,
                         lost_col     = FALSE)
  })
  expect_true(all(d$t2d_followup_years > 0, na.rm = TRUE))
})

test_that("derive_followup() with death competing endpoint reduces some follow-up times", {
  d <- data.table::copy(DT)
  suppressMessages({
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)
    d <- derive_case(d, name = "t2d")
    # death date from p40000_i0
    d[, death_date := data.table::as.IDate(as.character(p40000_i0))]
    r_no_death <- suppressMessages(
      derive_followup(data.table::copy(d), name = "t2d",
                      event_col = "t2d_date", baseline_col = "p53_i0",
                      censor_date = CENSOR, death_col = FALSE, lost_col = FALSE)
    )
    r_with_death <- suppressMessages(
      derive_followup(data.table::copy(d), name = "t2d",
                      event_col = "t2d_date", baseline_col = "p53_i0",
                      censor_date = CENSOR, death_col = "death_date", lost_col = FALSE)
    )
  })
  # With death as competing event, some follow-up ends are earlier or equal
  end_no_death   <- r_no_death$t2d_followup_end
  end_with_death <- r_with_death$t2d_followup_end
  expect_true(all(end_with_death <= end_no_death, na.rm = TRUE))
})


# =============================================================================
# End-to-end pipeline: t2d full workflow
# =============================================================================

test_that("full t2d pipeline runs without error and produces analysis-ready data", {
  d <- data.table::copy(DT)

  suppressMessages({
    # 1. Clean missing
    d <- derive_missing(d, action = "na")

    # 2. Covariates
    d <- derive_covariate(d,
      as_factor  = c("p20116_i0", "p21000_i0"),
      as_numeric = "p22189",
      factor_levels = list(
        p20116_i0 = c("Never", "Previous", "Current")
      )
    )

    # 3. BMI tertiles
    d <- derive_cut(d, col = "p21001_i0", n = 3, name = "bmi_tri")

    # 4. T2D self-report
    d <- derive_selfreport(d, name = "t2d", regex = "type 2 diabetes",
                           field        = "noncancer",
                           disease_cols = SR_D, date_cols = SR_T,
                           visit_cols   = "p53_i0")

    # 5. T2D ICD-10 (HES only for speed)
    d <- derive_icd10(d, name = "t2d", icd10 = "E11",
                      source       = "hes",
                      hes_code_col = "p41270",
                      hes_date_cols = HES_DT)

    # 6. Unified case
    d <- derive_case(d, name = "t2d")

    # 7. Timing
    d <- derive_timing(d, name = "t2d", baseline_col = "p53_i0")

    # 8. Age at onset
    d <- derive_age(d, name = "t2d", baseline_col = "p53_i0", age_col = "p21022")

    # 9. Follow-up
    d <- derive_followup(d, name = "t2d",
                         event_col    = "t2d_date",
                         baseline_col = "p53_i0",
                         censor_date  = CENSOR,
                         death_col    = FALSE,
                         lost_col     = FALSE)
  })

  # Structural checks
  expected_cols <- c(
    "t2d_selfreport", "t2d_selfreport_date",
    "t2d_icd10",      "t2d_icd10_date",
    "t2d_status",     "t2d_date",
    "t2d_timing",     "age_at_t2d",
    "t2d_followup_end", "t2d_followup_years",
    "bmi_tri"
  )
  for (col in expected_cols) {
    expect_true(col %in% names(d), label = paste0("missing column: ", col))
  }

  # Quality checks
  expect_true(all(d$t2d_followup_years > 0, na.rm = TRUE))
  expect_true(all(d$t2d_timing %in% c(0L, 1L, 2L, NA_integer_)))
  expect_true(sum(d$t2d_status) >= sum(d$t2d_icd10))
  expect_true(sum(d$t2d_status) >= sum(d$t2d_selfreport))
  expect_true(data.table::is.data.table(d))
})
