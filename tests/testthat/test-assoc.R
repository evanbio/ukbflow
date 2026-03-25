# =============================================================================
# test-assoc.R — Unit tests for assoc_ series (simulated data, no real files)
# =============================================================================


# ===========================================================================
# Shared helpers
# ===========================================================================

.fake_assoc_dt <- function(n = 300, seed = 42) {
  set.seed(seed)
  dt <- data.table::data.table(
    eid                = seq_len(n),
    followup_years     = round(runif(n, 1, 15), 2),
    copd_01            = rbinom(n, 1, 0.10),
    t2d_01              = rbinom(n, 1, 0.20),
    t2d_tf              = as.logical(rbinom(n, 1, 0.20)),
    bmi_cat            = factor(
      sample(c("Normal", "Overweight", "Obese"), n, TRUE, c(0.4, 0.35, 0.25)),
      levels = c("Normal", "Overweight", "Obese")
    ),
    bmi_num            = round(rnorm(n, 27, 5), 1),
    age_at_recruitment = round(rnorm(n, 57, 8), 1),
    sex                = factor(sample(c("Male", "Female"), n, TRUE)),
    tdi                = rnorm(n, -1, 3),
    smoking            = factor(sample(c("Never", "Previous", "Current"), n, TRUE))
  )
  # Inject some NA into tdi for listwise deletion tests
  dt[sample(n, 20L), tdi := NA_real_]
  dt
}

.fake_competing_dt <- function(n = 300, seed = 42) {
  dt <- .fake_assoc_dt(n = n, seed = seed)
  set.seed(seed + 1L)
  dt[, death_01 := rbinom(n, 1, 0.05)]
  # Prevent simultaneous primary + competing event
  dt[copd_01 == 1L & death_01 == 1L, death_01 := 0L]
  dt[, censoring_type := data.table::fcase(
    copd_01  == 1L, 1L,
    death_01 == 1L, 2L,
    default  = 0L
  )]
  dt
}


# ===========================================================================
# assoc_coxph()
# ===========================================================================

test_that("assoc_coxph() aborts on non-data.frame input", {
  expect_error(
    assoc_coxph("not a df", "copd_01", "followup_years", "t2d_01"),
    "data.frame"
  )
})

test_that("assoc_coxph() aborts on missing column", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(assoc_coxph(dt, "nonexistent", "followup_years", "t2d_01")),
    "missing"
  )
})

test_that("assoc_coxph() aborts when base=FALSE and no covariates", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(assoc_coxph(dt, "copd_01", "followup_years", "t2d_01",
                                 base = FALSE)),
    "covariates"
  )
})

test_that("assoc_coxph() returns data.table", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(data.table::is.data.table(res))
})

test_that("assoc_coxph() output has required columns", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(all(c("exposure", "term", "model", "n", "n_events",
                    "person_years", "HR", "CI_lower", "CI_upper",
                    "p_value", "HR_label") %in% names(res)))
})

test_that("assoc_coxph() produces Unadjusted and Age-sex models by default", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true("Unadjusted" %in% levels(res$model))
  expect_true("Age and sex adjusted" %in% levels(res$model))
})

test_that("assoc_coxph() model is ordered factor", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(is.ordered(res$model))
})

test_that("assoc_coxph() HR > 0 and CI_lower < HR < CI_upper", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(all(res$HR > 0))
  expect_true(all(res$CI_lower < res$HR))
  expect_true(all(res$HR < res$CI_upper))
})

test_that("assoc_coxph() p_value in [0, 1]", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(all(res$p_value >= 0 & res$p_value <= 1))
})

test_that("assoc_coxph() binary term name matches exposure name (no suffix)", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(all(res$term == "t2d_01"))
})

test_that("assoc_coxph() logical exposure converts to integer (no TRUE suffix)", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_tf")
  )
  expect_true(all(res$term == "t2d_tf"))
})

test_that("assoc_coxph() factor exposure produces n_levels - 1 term rows per model", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "bmi_cat")
  )
  n_per_model <- nrow(res[res$model == "Unadjusted", ])
  expect_equal(n_per_model, 2L)  # 3 levels → 2 non-reference terms
})

test_that("assoc_coxph() Fully adjusted model included when covariates given", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01",
                covariates = c("tdi", "smoking"))
  )
  expect_true("Fully adjusted" %in% levels(res$model))
})

test_that("assoc_coxph() Fully adjusted n <= Unadjusted n (listwise deletion)", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", "t2d_01",
                covariates = c("tdi", "smoking"))
  )
  n_full <- res[res$model == "Fully adjusted", "n"][[1L]]
  n_unadj <- res[res$model == "Unadjusted", "n"][[1L]]
  expect_lte(n_full, n_unadj)
})

test_that("assoc_coxph() multiple exposures stack rows correctly", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph(dt, "copd_01", "followup_years", c("t2d_01", "bmi_num"))
  )
  expect_equal(length(unique(res$exposure)), 2L)
})

test_that("assoc_cox() alias matches assoc_coxph()", {
  dt   <- .fake_assoc_dt()
  res1 <- suppressMessages(assoc_coxph(dt, "copd_01", "followup_years", "t2d_01"))
  res2 <- suppressMessages(assoc_cox(dt,   "copd_01", "followup_years", "t2d_01"))
  expect_equal(res1$HR, res2$HR)
})


# ===========================================================================
# assoc_logistic()
# ===========================================================================

test_that("assoc_logistic() aborts on non-data.frame input", {
  expect_error(
    assoc_logistic("not a df", "copd_01", "t2d_01"),
    "data.frame"
  )
})

test_that("assoc_logistic() aborts on missing column", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(assoc_logistic(dt, "nonexistent", "t2d_01")),
    "missing"
  )
})

test_that("assoc_logistic() returns data.table with OR columns", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(assoc_logistic(dt, "copd_01", "t2d_01"))
  expect_true(data.table::is.data.table(res))
  expect_true(all(c("OR", "CI_lower", "CI_upper", "p_value", "OR_label") %in%
                    names(res)))
})

test_that("assoc_logistic() OR > 0 and CI_lower < OR < CI_upper", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(assoc_logistic(dt, "copd_01", "t2d_01"))
  expect_true(all(res$OR > 0))
  expect_true(all(res$CI_lower < res$OR & res$OR < res$CI_upper))
})

test_that("assoc_logistic() aborts on non-binary outcome", {
  dt <- .fake_assoc_dt()
  dt[, bmi_int := as.integer(bmi_num)]
  expect_error(
    suppressMessages(assoc_logistic(dt, "bmi_int", "t2d_01")),
    "0/1"
  )
})

test_that("assoc_logit() alias matches assoc_logistic()", {
  dt   <- .fake_assoc_dt()
  res1 <- suppressMessages(assoc_logistic(dt, "copd_01", "t2d_01"))
  res2 <- suppressMessages(assoc_logit(dt,    "copd_01", "t2d_01"))
  expect_equal(res1$OR, res2$OR)
})


# ===========================================================================
# assoc_linear()
# ===========================================================================

test_that("assoc_linear() aborts on non-data.frame input", {
  expect_error(
    assoc_linear("not a df", "bmi_num", "t2d_01"),
    "data.frame"
  )
})

test_that("assoc_linear() returns data.table with beta/se columns", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(assoc_linear(dt, "bmi_num", "t2d_01"))
  expect_true(data.table::is.data.table(res))
  expect_true(all(c("beta", "se", "CI_lower", "CI_upper",
                    "p_value", "beta_label") %in% names(res)))
})

test_that("assoc_linear() se > 0", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(assoc_linear(dt, "bmi_num", "t2d_01"))
  expect_true(all(res$se > 0))
})

test_that("assoc_linear() p_value in [0, 1]", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(assoc_linear(dt, "bmi_num", "t2d_01"))
  expect_true(all(res$p_value >= 0 & res$p_value <= 1))
})

test_that("assoc_lm() alias matches assoc_linear()", {
  dt   <- .fake_assoc_dt()
  res1 <- suppressMessages(assoc_linear(dt, "bmi_num", "t2d_01"))
  res2 <- suppressMessages(assoc_lm(dt,     "bmi_num", "t2d_01"))
  expect_equal(res1$beta, res2$beta)
})


# ===========================================================================
# assoc_coxph_zph()
# ===========================================================================

test_that("assoc_coxph_zph() aborts on missing column", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_coxph_zph(dt, "nonexistent", "followup_years", "t2d_01")
    ),
    "missing"
  )
})

test_that("assoc_coxph_zph() returns data.table with zph columns", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph_zph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(data.table::is.data.table(res))
  expect_true(all(c("term", "chisq", "df", "p_value",
                    "ph_satisfied", "global_p") %in% names(res)))
})

test_that("assoc_coxph_zph() p_value in [0, 1]", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_coxph_zph(dt, "copd_01", "followup_years", "t2d_01")
  )
  expect_true(all(res$p_value >= 0 & res$p_value <= 1, na.rm = TRUE))
})

test_that("assoc_zph() alias matches assoc_coxph_zph()", {
  dt   <- .fake_assoc_dt()
  res1 <- suppressMessages(assoc_coxph_zph(dt, "copd_01", "followup_years", "t2d_01"))
  res2 <- suppressMessages(assoc_zph(dt,        "copd_01", "followup_years", "t2d_01"))
  expect_equal(res1$p_value, res2$p_value)
})


# ===========================================================================
# assoc_subgroup()
# ===========================================================================

test_that("assoc_subgroup() aborts on missing by column", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01", by = "nonexistent")
    ),
    "missing"
  )
})

test_that("assoc_subgroup() aborts when by is not length 1", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01",
                     by = c("sex", "smoking"))
    ),
    "single"
  )
})

test_that("assoc_subgroup() returns data.table with subgroup_level column", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01", by = "sex")
  )
  expect_true(data.table::is.data.table(res))
  expect_true("subgroup_level" %in% names(res))
})

test_that("assoc_subgroup() produces one result row per subgroup level", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01", by = "sex")
  )
  expect_equal(length(unique(res$subgroup_level)), 2L)  # Male / Female
})

test_that("assoc_subgroup() contains p_interaction column", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01", by = "sex")
  )
  expect_true("p_interaction" %in% names(res))
})

test_that("assoc_subgroup() p_interaction is shared across subgroup levels", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01", by = "sex",
                   covariates = "tdi")
  )
  # Same model → same p_interaction value for all levels
  pi_vals <- unique(res[res$model == "Fully adjusted", "p_interaction"])
  expect_equal(nrow(pi_vals), 1L)
})

test_that("assoc_sub() alias matches assoc_subgroup()", {
  dt   <- .fake_assoc_dt()
  res1 <- suppressMessages(
    assoc_subgroup(dt, "copd_01", "followup_years", "t2d_01", by = "sex"))
  res2 <- suppressMessages(
    assoc_sub(dt, "copd_01", "followup_years", "t2d_01", by = "sex"))
  expect_equal(res1$HR, res2$HR)
})


# ===========================================================================
# assoc_trend()
# ===========================================================================

test_that("assoc_trend() aborts when exposure is not factor", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_trend(dt, "copd_01", "followup_years", "t2d_01", method = "coxph")
    ),
    "factor"
  )
})

test_that("assoc_trend() aborts when scores length != nlevels", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_trend(dt, "copd_01", "followup_years", "bmi_cat",
                  method = "coxph", scores = c(0, 1))  # 3 levels, 2 scores
    ),
    "length|scores"
  )
})

test_that("assoc_trend() returns data.table with level and p_trend columns", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat", method = "coxph")
  )
  expect_true(data.table::is.data.table(res))
  expect_true("level"   %in% names(res))
  expect_true("p_trend" %in% names(res))
})

test_that("assoc_trend() reference row has HR=1 and NA CI", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat", method = "coxph")
  )
  ref <- res[res$level == "Normal" & res$model == "Unadjusted", ]
  expect_equal(ref$HR[1L], 1.0)
  expect_true(is.na(ref$CI_lower[1L]))
})

test_that("assoc_trend() p_trend is last column", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat", method = "coxph")
  )
  expect_equal(names(res)[ncol(res)], "p_trend")
})

test_that("assoc_trend() level is factor", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat", method = "coxph")
  )
  expect_true(is.factor(res$level))
})

test_that("assoc_trend() HR_per_score differs with custom scores", {
  dt    <- .fake_assoc_dt()
  res_a <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat",
                method = "coxph", scores = c(0, 1, 2))
  )
  res_b <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat",
                method = "coxph", scores = c(0, 5, 10))
  )
  # Larger score interval → smaller per-unit HR
  expect_false(isTRUE(all.equal(
    res_a[res_a$model == "Unadjusted", "HR_per_score"][[1L]][1L],
    res_b[res_b$model == "Unadjusted", "HR_per_score"][[1L]][1L]
  )))
})

test_that("assoc_tr() alias matches assoc_trend()", {
  dt   <- .fake_assoc_dt()
  res1 <- suppressMessages(
    assoc_trend(dt, "copd_01", "followup_years", "bmi_cat", method = "coxph"))
  res2 <- suppressMessages(
    assoc_tr(dt,   "copd_01", "followup_years", "bmi_cat", method = "coxph"))
  expect_equal(res1$HR, res2$HR)
})


# ===========================================================================
# assoc_competing()
# ===========================================================================

test_that("assoc_competing() aborts on missing column", {
  dt <- .fake_competing_dt()
  expect_error(
    suppressMessages(
      assoc_competing(dt, "nonexistent", "followup_years", "t2d_01")
    ),
    "missing"
  )
})

test_that("assoc_competing() returns data.table with SHR columns", {
  dt  <- .fake_competing_dt()
  res <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val = 1L, compete_val = 2L)
  )
  expect_true(data.table::is.data.table(res))
  expect_true(all(c("SHR", "CI_lower", "CI_upper",
                    "p_value", "SHR_label", "n_compete") %in% names(res)))
})

test_that("assoc_competing() has no HR column (SHR not HR)", {
  dt  <- .fake_competing_dt()
  res <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val = 1L, compete_val = 2L)
  )
  expect_false("HR" %in% names(res))
})

test_that("assoc_competing() SHR > 0 and CI_lower < SHR < CI_upper", {
  dt  <- .fake_competing_dt()
  res <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val = 1L, compete_val = 2L)
  )
  expect_true(all(res$SHR > 0))
  expect_true(all(res$CI_lower < res$SHR & res$SHR < res$CI_upper))
})

test_that("assoc_competing() Mode B produces same n_events as Mode A", {
  dt  <- .fake_competing_dt()
  res_a <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val = 1L, compete_val = 2L)
  )
  res_b <- suppressMessages(
    assoc_competing(dt, "copd_01", "followup_years", "t2d_01",
                    compete_col = "death_01")
  )
  expect_equal(
    res_a[res_a$model == "Unadjusted", "n_events"][[1L]],
    res_b[res_b$model == "Unadjusted", "n_events"][[1L]]
  )
})

test_that("assoc_competing() logical exposure normalised (no TRUE suffix in term)", {
  dt  <- .fake_competing_dt()
  res <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_tf",
                    event_val = 1L, compete_val = 2L)
  )
  expect_true(all(res$term == "t2d_tf"))
})

test_that("assoc_competing() Fully adjusted n <= Unadjusted n", {
  dt  <- .fake_competing_dt()
  res <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val  = 1L, compete_val = 2L,
                    covariates = c("tdi", "smoking"))
  )
  n_full  <- res[res$model == "Fully adjusted", "n"][[1L]]
  n_unadj <- res[res$model == "Unadjusted",     "n"][[1L]]
  expect_lte(n_full, n_unadj)
})

test_that("assoc_competing() skips Age and sex adjusted when age/sex columns absent", {
  dt <- .fake_competing_dt()
  # Remove both age and sex columns so auto-detection fails
  dt[, c("age_at_recruitment", "sex") := NULL]
  res <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val = 1L, compete_val = 2L)
  )
  expect_false("Age and sex adjusted" %in% as.character(unique(res$model)))
})

test_that("assoc_fg() alias matches assoc_competing()", {
  dt   <- .fake_competing_dt()
  res1 <- suppressMessages(
    assoc_competing(dt, "censoring_type", "followup_years", "t2d_01",
                    event_val = 1L, compete_val = 2L))
  res2 <- suppressMessages(
    assoc_fg(dt, "censoring_type", "followup_years", "t2d_01",
             event_val = 1L, compete_val = 2L))
  expect_equal(res1$SHR, res2$SHR)
})


# ===========================================================================
# assoc_lag()
# ===========================================================================

test_that("assoc_lag() aborts on missing column", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_lag(dt, "nonexistent", "followup_years", "t2d_01")
    ),
    "missing"
  )
})

test_that("assoc_lag() aborts when base=FALSE and no covariates", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_lag(dt, "copd_01", "followup_years", "t2d_01", base = FALSE)
    ),
    "covariates"
  )
})

test_that("assoc_lag() aborts on negative lag_years", {
  dt <- .fake_assoc_dt()
  expect_error(
    suppressMessages(
      assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(-1, 2))
    ),
    "non-negative"
  )
})

test_that("assoc_lag() returns data.table with lag_years and n_excluded", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(1, 2))
  )
  expect_true(data.table::is.data.table(res))
  expect_true("lag_years"  %in% names(res))
  expect_true("n_excluded" %in% names(res))
})

test_that("assoc_lag() produces one result set per lag value", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(1, 2))
  )
  expect_equal(sort(unique(res$lag_years)), c(1, 2))
})

test_that("assoc_lag() lag=0 excludes nobody (n_excluded = 0)", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(0, 2))
  )
  expect_equal(res[res$lag_years == 0, "n_excluded"][[1L]][1L], 0L)
})

test_that("assoc_lag() larger lag excludes more participants", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(2, 5))
  )
  n_ex_2 <- res[res$lag_years == 2, "n_excluded"][[1L]][1L]
  n_ex_5 <- res[res$lag_years == 5, "n_excluded"][[1L]][1L]
  expect_gte(n_ex_5, n_ex_2)
})

test_that("assoc_lag() larger lag gives smaller or equal n", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(2, 5))
  )
  n_2 <- res[res$lag_years == 2 & res$model == "Unadjusted", "n"][[1L]]
  n_5 <- res[res$lag_years == 5 & res$model == "Unadjusted", "n"][[1L]]
  expect_lte(n_5, n_2)
})

test_that("assoc_lag() HR > 0 across all lags", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = c(1, 2))
  )
  expect_true(all(res$HR > 0))
})

test_that("assoc_lag() multiple exposures produce correct row count", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years",
              exposure_col = c("t2d_01", "bmi_num"),
              lag_years    = c(1, 2))
  )
  # 2 lag × 2 exposure × 2 model (Unadjusted + Age-sex) = 8 rows
  expect_equal(nrow(res), 8L)
})

test_that("assoc_lag() lag_years and n_excluded placed after model column", {
  dt  <- .fake_assoc_dt()
  res <- suppressMessages(
    assoc_lag(dt, "copd_01", "followup_years", "t2d_01", lag_years = 1)
  )
  col_pos <- match(c("model", "lag_years", "n_excluded"), names(res))
  expect_true(col_pos[2L] == col_pos[1L] + 1L)
  expect_true(col_pos[3L] == col_pos[1L] + 2L)
})
