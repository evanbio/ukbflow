# =============================================================================
# test-integration-assoc.R — Integration tests for assoc_ series
# Uses a larger simulated dataset (n=2000) to test real model behaviour.
# Run manually before release: devtools::test(filter = "integration-assoc")
# =============================================================================

skip_on_ci()
skip_on_cran()


# ===========================================================================
# Shared fixture (n=2000, realistic UKB-like distributions)
# ===========================================================================

set.seed(2024L)
N <- 2000L

DT <- data.table::data.table(
  eid                = seq_len(N),
  followup_years     = round(runif(N, 0.5, 15), 2),
  cscc_01            = rbinom(N, 1, 0.08),
  ad_01              = rbinom(N, 1, 0.15),
  ad_severity        = factor(
    sample(c("No AD", "Mild", "Moderate/Severe"), N, TRUE, c(0.70, 0.20, 0.10)),
    levels = c("No AD", "Mild", "Moderate/Severe")
  ),
  bmi_cat            = factor(
    sample(c("Normal", "Overweight", "Obese"), N, TRUE, c(0.40, 0.35, 0.25)),
    levels = c("Normal", "Overweight", "Obese")
  ),
  bmi_num            = round(rnorm(N, 27, 5), 1),
  age_at_recruitment = round(rnorm(N, 57, 8), 1),
  sex                = factor(sample(c("Male", "Female"), N, TRUE)),
  tdi                = rnorm(N, -1, 3),
  smoking            = factor(sample(c("Never", "Previous", "Current"), N, TRUE)),
  ethnicity          = factor(sample(c("White", "Asian", "Black", "Other"),
                                     N, TRUE, c(0.85, 0.07, 0.04, 0.04)))
)
# Inject NA into tdi to test listwise deletion
DT[sample(N, 150L), tdi := NA_real_]

# Competing risks columns
set.seed(2025L)
DT[, death_01      := rbinom(N, 1, 0.05)]
DT[cscc_01 == 1L & death_01 == 1L, death_01 := 0L]
DT[, censoring_type := data.table::fcase(
  cscc_01  == 1L, 1L,
  death_01 == 1L, 2L,
  default  = 0L
)]

COVS_FULL <- c("tdi", "smoking", "ethnicity")


# ===========================================================================
# assoc_coxph() — integration
# ===========================================================================

test_that("assoc_coxph() runs on n=2000 without error", {
  expect_no_error(suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", "ad_01",
                covariates = COVS_FULL)
  ))
})

test_that("assoc_coxph() 3-model output is numerically coherent", {
  res <- suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", "ad_01",
                covariates = COVS_FULL)
  )
  expect_equal(uniqueN(res$model), 3L)
  expect_true(all(res$HR > 0))
  expect_true(all(res$CI_lower < res$HR))
  expect_true(all(res$HR < res$CI_upper))
  expect_true(all(res$p_value >= 0 & res$p_value <= 1))
})

test_that("assoc_coxph() factor exposure returns n_levels - 1 terms per model", {
  res <- suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", "bmi_cat")
  )
  # Drop empty factor levels before counting (ordered factor may retain all levels)
  per_model <- table(droplevels(res$model))
  expect_true(all(per_model == 2L))   # 3 levels → 2 non-reference terms
})

test_that("assoc_coxph() HR_label format matches 'x.xx (x.xx-x.xx)'", {
  res <- suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", "ad_01")
  )
  expect_true(all(grepl("^\\d+\\.\\d+ \\(\\d+\\.\\d+", res$HR_label)))
})

test_that("assoc_coxph() person_years is positive and finite", {
  res <- suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", "ad_01")
  )
  expect_true(all(res$person_years > 0))
  expect_true(all(is.finite(res$person_years)))
})

test_that("assoc_coxph() n_events consistent with data", {
  res <- suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", "ad_01")
  )
  # Unadjusted model uses all rows (no covariate NA)
  expected_events <- sum(DT$cscc_01)
  expect_equal(res[res$model == "Unadjusted", "n_events"][[1L]], expected_events)
})

test_that("assoc_coxph() multiple exposures correct row count", {
  res <- suppressMessages(
    assoc_coxph(DT, "cscc_01", "followup_years", c("ad_01", "bmi_num", "bmi_cat"))
  )
  # ad_01: 1 term, bmi_num: 1 term, bmi_cat: 2 terms → 4 per model × 2 models = 8
  expect_equal(nrow(res), 8L)
})


# ===========================================================================
# assoc_logistic() — integration
# ===========================================================================

test_that("assoc_logistic() runs on n=2000 without error", {
  expect_no_error(suppressMessages(
    assoc_logistic(DT, "cscc_01", "ad_01", covariates = COVS_FULL)
  ))
})

test_that("assoc_logistic() OR > 0, CI spans OR, p in [0,1]", {
  res <- suppressMessages(
    assoc_logistic(DT, "cscc_01", "ad_01", covariates = COVS_FULL)
  )
  expect_true(all(res$OR > 0))
  expect_true(all(res$CI_lower < res$OR & res$OR < res$CI_upper))
  expect_true(all(res$p_value >= 0 & res$p_value <= 1))
})


# ===========================================================================
# assoc_linear() — integration
# ===========================================================================

test_that("assoc_linear() runs on n=2000 without error", {
  expect_no_error(suppressMessages(
    assoc_linear(DT, "bmi_num", "ad_01", covariates = COVS_FULL)
  ))
})

test_that("assoc_linear() se > 0 and p in [0,1]", {
  res <- suppressMessages(
    assoc_linear(DT, "bmi_num", "ad_01", covariates = COVS_FULL)
  )
  expect_true(all(res$se > 0))
  expect_true(all(res$p_value >= 0 & res$p_value <= 1))
})


# ===========================================================================
# assoc_coxph_zph() — integration
# ===========================================================================

test_that("assoc_coxph_zph() runs without error and returns ph_satisfied", {
  res <- suppressMessages(
    assoc_coxph_zph(DT, "cscc_01", "followup_years", "ad_01")
  )
  expect_true("ph_satisfied" %in% names(res))
  expect_true(is.logical(res$ph_satisfied))
})


# ===========================================================================
# assoc_subgroup() — integration
# ===========================================================================

test_that("assoc_subgroup() runs on n=2000 by sex without error", {
  expect_no_error(suppressMessages(
    assoc_subgroup(DT, "cscc_01", "followup_years", "ad_01",
                   by = "sex", covariates = COVS_FULL)
  ))
})

test_that("assoc_subgroup() p_interaction is numeric scalar in [0,1]", {
  res <- suppressMessages(
    assoc_subgroup(DT, "cscc_01", "followup_years", "ad_01",
                   by = "sex", covariates = COVS_FULL)
  )
  pi <- unique(stats::na.omit(res$p_interaction))
  expect_true(length(pi) >= 1L)
  expect_true(all(pi >= 0 & pi <= 1))
})

test_that("assoc_subgroup() subgroup n sums to <= total n", {
  res <- suppressMessages(
    assoc_subgroup(DT, "cscc_01", "followup_years", "ad_01", by = "sex")
  )
  total_n <- sum(res[res$model == "Unadjusted", "n"][[1L]])
  expect_lte(total_n, nrow(DT))
})

test_that("assoc_subgroup() works with 3-level by variable", {
  res <- suppressMessages(
    assoc_subgroup(DT, "cscc_01", "followup_years", "ad_01", by = "smoking")
  )
  expect_equal(uniqueN(res$subgroup_level), 3L)
})


# ===========================================================================
# assoc_trend() — integration
# ===========================================================================

test_that("assoc_trend() coxph on n=2000 returns reference row + non-ref rows", {
  res <- suppressMessages(
    assoc_trend(DT, "cscc_01", "followup_years", "ad_severity",
                method = "coxph")
  )
  ref_rows <- res[res$level == "No AD" & res$model == "Unadjusted", ]
  expect_equal(nrow(ref_rows), 1L)
  expect_equal(ref_rows$HR[1L], 1.0)
  expect_true(is.na(ref_rows$CI_lower[1L]))
})

test_that("assoc_trend() p_trend is numeric and in [0,1]", {
  res <- suppressMessages(
    assoc_trend(DT, "cscc_01", "followup_years", "ad_severity",
                method = "coxph")
  )
  pt <- stats::na.omit(unique(res$p_trend))
  expect_true(all(pt >= 0 & pt <= 1))
})

test_that("assoc_trend() logistic method returns OR_per_score", {
  res <- suppressMessages(
    assoc_trend(DT, "cscc_01", "followup_years", "ad_severity",
                method = "logistic")
  )
  expect_true("OR_per_score" %in% names(res))
})

test_that("assoc_trend() linear method returns beta_per_score", {
  res <- suppressMessages(
    assoc_trend(DT, "bmi_num", "followup_years", "ad_severity",
                method = "linear")
  )
  expect_true("beta_per_score" %in% names(res))
})


# ===========================================================================
# assoc_competing() — integration
# ===========================================================================

test_that("assoc_competing() Mode A runs on n=2000 without error", {
  expect_no_error(suppressMessages(
    assoc_competing(DT, "censoring_type", "followup_years", "ad_01",
                    event_val = 1L, compete_val = 2L,
                    covariates = COVS_FULL)
  ))
})

test_that("assoc_competing() Mode B runs without error", {
  expect_no_error(suppressMessages(
    assoc_competing(DT, "cscc_01", "followup_years", "ad_01",
                    compete_col = "death_01",
                    covariates  = COVS_FULL)
  ))
})

test_that("assoc_competing() SHR > 0, CI spans SHR, p in [0,1]", {
  res <- suppressMessages(
    assoc_competing(DT, "censoring_type", "followup_years", "ad_01",
                    event_val = 1L, compete_val = 2L,
                    covariates = COVS_FULL)
  )
  expect_true(all(res$SHR > 0))
  expect_true(all(res$CI_lower < res$SHR & res$SHR < res$CI_upper))
  expect_true(all(res$p_value >= 0 & res$p_value <= 1))
})

test_that("assoc_competing() n_compete matches expected competing event count", {
  res <- suppressMessages(
    assoc_competing(DT, "censoring_type", "followup_years", "ad_01",
                    event_val = 1L, compete_val = 2L)
  )
  expected_compete <- sum(DT$death_01)
  # n_compete in model may be <= raw count (complete cases only)
  expect_lte(res[res$model == "Unadjusted", "n_compete"][[1L]], expected_compete + 1L)
})

test_that("assoc_competing() Fully adjusted n <= Unadjusted n", {
  res <- suppressMessages(
    assoc_competing(DT, "censoring_type", "followup_years", "ad_01",
                    event_val = 1L, compete_val = 2L,
                    covariates = COVS_FULL)
  )
  n_full  <- res[res$model == "Fully adjusted", "n"][[1L]]
  n_unadj <- res[res$model == "Unadjusted",     "n"][[1L]]
  expect_lte(n_full, n_unadj)
})

test_that("assoc_competing() factor exposure produces correct term names", {
  res <- suppressMessages(
    assoc_competing(DT, "censoring_type", "followup_years", "bmi_cat",
                    event_val = 1L, compete_val = 2L)
  )
  expect_true("bmi_catOverweight" %in% res$term)
  expect_true("bmi_catObese"      %in% res$term)
})


# ===========================================================================
# assoc_lag() — integration
# ===========================================================================

test_that("assoc_lag() runs on n=2000 with lag=c(0,1,2) without error", {
  expect_no_error(suppressMessages(
    assoc_lag(DT, "cscc_01", "followup_years", "ad_01",
              lag_years  = c(0, 1, 2),
              covariates = COVS_FULL)
  ))
})

test_that("assoc_lag() lag=0 n equals total cohort size", {
  res <- suppressMessages(
    assoc_lag(DT, "cscc_01", "followup_years", "ad_01",
              lag_years = c(0, 2))
  )
  n_lag0 <- res[res$lag_years == 0 & res$model == "Unadjusted", "n"][[1L]]
  expect_equal(n_lag0, nrow(DT))
})

test_that("assoc_lag() HR positive and CI ordered for all lags", {
  res <- suppressMessages(
    assoc_lag(DT, "cscc_01", "followup_years", "ad_01",
              lag_years = c(1, 2, 5))
  )
  expect_true(all(res$HR > 0))
  expect_true(all(res$CI_lower < res$HR & res$HR < res$CI_upper))
})

test_that("assoc_lag() n_excluded monotonically increases with lag", {
  res <- suppressMessages(
    assoc_lag(DT, "cscc_01", "followup_years", "ad_01",
              lag_years = c(1, 2, 5))
  )
  excl <- unique(res[, c("lag_years", "n_excluded")])
  data.table::setorder(excl, lag_years)
  expect_true(all(diff(excl$n_excluded) >= 0))
})

test_that("assoc_lag() 3 lags × 2 exposures × 3 models = 18 rows", {
  res <- suppressMessages(
    assoc_lag(DT, "cscc_01", "followup_years",
              exposure_col = c("ad_01", "bmi_num"),
              lag_years    = c(1, 2, 5),
              covariates   = COVS_FULL)
  )
  expect_equal(nrow(res), 18L)
})

test_that("assoc_lag() column order: lag_years directly after model", {
  res <- suppressMessages(
    assoc_lag(DT, "cscc_01", "followup_years", "ad_01", lag_years = 2)
  )
  pos_model    <- which(names(res) == "model")
  pos_lag      <- which(names(res) == "lag_years")
  pos_excluded <- which(names(res) == "n_excluded")
  expect_equal(pos_lag,      pos_model + 1L)
  expect_equal(pos_excluded, pos_model + 2L)
})
