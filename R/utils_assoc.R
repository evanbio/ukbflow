# =============================================================================
# utils_assoc.R — internal helpers for assoc_ series
# =============================================================================


# Normalise the outcome vector to integer 0/1.
# Accepts logical (T/F) or integer/numeric (0/1). Aborts on any other values.
.normalise_event <- function(x, col) {
  if (is.logical(x)) {
    cli::cli_alert_info(
      "outcome_col {.field {col}}: logical detected, converting TRUE/FALSE -> 1/0"
    )
    return(as.integer(x))
  }
  xi  <- suppressWarnings(as.integer(x))
  bad <- setdiff(stats::na.omit(unique(xi)), c(0L, 1L))
  if (length(bad) > 0L) {
    cli::cli_abort(
      "outcome_col {.field {col}}: values other than 0/1/NA found: {bad}",
      call = NULL
    )
  }
  xi
}


# Normalise logical exposure columns to integer in-place (on a data.table copy).
# Logical TRUE/FALSE -> 1/0 so coxph produces clean term names (e.g. "ad_tf"
# rather than "ad_tfTRUE").
.normalise_logical_exposures <- function(dt, exposure_cols) {
  for (col in exposure_cols) {
    if (is.logical(dt[[col]])) {
      cli::cli_alert_info(
        "exposure_col {.field {col}}: logical detected, converting TRUE/FALSE -> 1/0"
      )
      dt[, (col) := as.integer(get(col))]
    }
  }
  invisible(dt)
}


# Auto-detect the age column via UKB field 21022 (age at recruitment).
# Falls back to a grep on "^age" if the field cache is unavailable.
# Returns NULL with a warning when not found.
.detect_age_col <- function(data) {
  cols <- .detect_cols_by_field(data, 21022L)
  if (length(cols) > 0L) return(cols[1L])
  cols <- grep("^age", names(data), value = TRUE, ignore.case = TRUE)
  if (length(cols) > 0L) return(cols[1L])
  NULL
}


# Auto-detect the sex column via UKB field 31.
# Falls back to an exact "sex" match then a case-insensitive grep.
# Returns NULL with a warning when not found.
.detect_sex_col <- function(data) {
  cols <- .detect_cols_by_field(data, 31L)
  if (length(cols) > 0L) return(cols[1L])
  if ("sex" %in% names(data)) return("sex")
  cols <- grep("^sex$", names(data), value = TRUE, ignore.case = TRUE)
  if (length(cols) > 0L) return(cols[1L])
  NULL
}


# Extract tidy HR / CI / p-value rows for one exposure from a fitted coxph model.
# For factor exposures, all level rows are returned (one per non-reference level).
# For numeric / binary exposures, a single row is returned.
#
# Args:
#   model      (coxph)   Fitted model.
#   exposure   (character) Exposure variable name as it appears in the formula.
#   is_factor  (logical)   Whether the exposure is a factor in the data.
#   conf_level (numeric)   Confidence level, e.g. 0.95.
#
# Returns:
#   data.table with columns: term, HR, CI_lower, CI_upper, p_value.
#   NULL if no matching terms are found.
.extract_cox_terms <- function(model, exposure, is_factor, conf_level) {
  coef_mat  <- summary(model)$coefficients
  # confint() returns log-scale CI; exp() converts to HR scale
  ci_log    <- confint(model, level = conf_level)
  if (!is.matrix(ci_log)) {
    ci_log <- matrix(ci_log, nrow = 1L,
                     dimnames = list(exposure, names(ci_log)))
  }

  all_terms <- rownames(coef_mat)

  # Factor: terms are paste0(exposure, level) — use startsWith
  # Numeric / binary: term equals exposure name exactly
  idx <- if (is_factor) {
    which(startsWith(all_terms, exposure))
  } else {
    which(all_terms == exposure)
  }

  if (length(idx) == 0L) {
    cli::cli_alert_warning(
      "  No terms found for exposure {.field {exposure}} -- skipped."
    )
    return(NULL)
  }

  data.table::data.table(
    term     = all_terms[idx],
    HR       = exp(coef_mat[idx, "coef"]),
    CI_lower = exp(ci_log[idx, 1L]),
    CI_upper = exp(ci_log[idx, 2L]),
    p_value  = coef_mat[idx, "Pr(>|z|)"]
  )
}


# Fit one coxph model for a single exposure and return a tidy data.table.
# The event column is expected to be pre-added as ".ukb_event" in dt.
#
# n, n_events, and person_years are all extracted from the fitted model object
# so that listwise deletion (due to covariate NA) is automatically reflected —
# each model reports the statistics for its actual analysis set, not the
# full input data.
#
# Args:
#   dt           (data.table) Analysis dataset with ".ukb_event" column.
#   time_col     (character)  Follow-up time column name.
#   exposure     (character)  Single exposure variable name.
#   covariates   (character or NULL) Covariate column names.
#   strata       (character or NULL) Strata variable name.
#   model_label  (character)  Human-readable model name for the output.
#   conf_level   (numeric)    Confidence level for CI.
#
# Returns:
#   data.table or NULL on failure.
.run_one_cox_model <- function(dt, time_col, exposure, covariates,
                                strata, model_label, conf_level) {

  is_factor <- is.factor(dt[[exposure]])

  rhs_parts <- c(exposure, covariates)
  if (!is.null(strata)) {
    rhs_parts <- c(rhs_parts, paste0("strata(", strata, ")"))
  }
  rhs <- paste(rhs_parts, collapse = " + ")

  fml <- stats::as.formula(
    sprintf("Surv(%s, .ukb_event) ~ %s", time_col, rhs)
  )

  model <- tryCatch(
    survival::coxph(fml, data = dt),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] model failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(model)) return(NULL)

  terms_dt <- .extract_cox_terms(model, exposure, is_factor, conf_level)
  if (is.null(terms_dt)) return(NULL)

  # Extract n, n_events, person_years from the model itself so that listwise
  # deletion due to covariate missingness is automatically reflected.
  # model$y is the Surv matrix for the actual analysis set (after NA removal).
  # For Surv(time, event), column 1 = time, column 2 = status.
  surv_mat     <- model$y
  n_events_mod <- model$nevent
  person_years_mod <- round(sum(surv_mat[, 1L], na.rm = TRUE))

  terms_dt[, `:=`(
    exposure     = exposure,
    model        = model_label,
    n            = model$n,
    n_events     = n_events_mod,
    person_years = person_years_mod,
    HR_label     = sprintf("%.2f (%.2f-%.2f)", HR, CI_lower, CI_upper)
  )]

  data.table::setcolorder(
    terms_dt,
    c("exposure", "term", "model", "n", "n_events", "person_years",
      "HR", "CI_lower", "CI_upper", "p_value", "HR_label")
  )
  terms_dt
}


# Fit one logistic regression model for a single exposure and return a tidy
# data.table. The event column is expected to be pre-added as ".ukb_event" in dt.
#
# n and n_cases are extracted from the fitted model so that listwise deletion
# due to covariate missingness is automatically reflected.
#
# Args:
#   dt           (data.table) Analysis dataset with ".ukb_event" column.
#   exposure     (character)  Single exposure variable name.
#   covariates   (character or NULL) Covariate column names.
#   model_label  (character)  Human-readable model name for the output.
#   ci_method    (character)  "wald" (default) or "profile".
#   conf_level   (numeric)    Confidence level for CI.
#
# Returns:
#   data.table or NULL on failure.
.run_one_logistic_model <- function(dt, exposure, covariates,
                                     model_label, ci_method, conf_level) {

  is_factor <- is.factor(dt[[exposure]])

  rhs <- paste(c(exposure, covariates), collapse = " + ")
  fml <- stats::as.formula(sprintf(".ukb_event ~ %s", rhs))

  model <- tryCatch(
    stats::glm(fml, data = dt, family = stats::binomial(link = "logit")),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] model failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(model)) return(NULL)

  coef_mat  <- summary(model)$coefficients
  all_terms <- rownames(coef_mat)

  idx <- if (is_factor) {
    which(startsWith(all_terms, exposure))
  } else {
    which(all_terms == exposure)
  }

  if (length(idx) == 0L) {
    cli::cli_alert_warning(
      "  No terms found for exposure {.field {exposure}} -- skipped."
    )
    return(NULL)
  }

  # CI on log-OR scale; exp() gives OR CI
  # Reason: confint.default() = Wald (fast); confint.glm() = profile likelihood
  ci_log <- if (ci_method == "wald") {
    stats::confint.default(model, level = conf_level)
  } else {
    suppressMessages(stats::confint(model, level = conf_level))
  }
  if (!is.matrix(ci_log)) {
    ci_log <- matrix(ci_log, nrow = 1L,
                     dimnames = list(all_terms[idx], names(ci_log)))
  }

  terms_dt <- data.table::data.table(
    term     = all_terms[idx],
    OR       = exp(coef_mat[idx, "Estimate"]),
    CI_lower = exp(ci_log[idx, 1L]),
    CI_upper = exp(ci_log[idx, 2L]),
    p_value  = coef_mat[idx, "Pr(>|z|)"]
  )

  # n and n_cases from the model's actual analysis set (after listwise deletion)
  n_cases_mod <- sum(model$y, na.rm = TRUE)

  terms_dt[, `:=`(
    exposure = exposure,
    model    = model_label,
    n        = stats::nobs(model),
    n_cases  = n_cases_mod,
    OR_label = sprintf("%.2f (%.2f-%.2f)", OR, CI_lower, CI_upper)
  )]

  data.table::setcolorder(
    terms_dt,
    c("exposure", "term", "model", "n", "n_cases",
      "OR", "CI_lower", "CI_upper", "p_value", "OR_label")
  )
  terms_dt
}


# Fit one linear regression model for a single exposure and return a tidy
# data.table. The outcome column is used directly (continuous numeric).
#
# n is extracted from the fitted model so that listwise deletion due to
# covariate missingness is automatically reflected.
# SE is included alongside beta to support downstream meta-analysis.
#
# Args:
#   dt           (data.table) Analysis dataset.
#   outcome_col  (character)  Continuous outcome column name.
#   exposure     (character)  Single exposure variable name.
#   covariates   (character or NULL) Covariate column names.
#   model_label  (character)  Human-readable model name for the output.
#   conf_level   (numeric)    Confidence level for CI (t-distribution based).
#
# Returns:
#   data.table or NULL on failure.
.run_one_linear_model <- function(dt, outcome_col, exposure, covariates,
                                   model_label, conf_level) {

  is_factor <- is.factor(dt[[exposure]])

  rhs <- paste(c(exposure, covariates), collapse = " + ")
  fml <- stats::as.formula(sprintf("%s ~ %s", outcome_col, rhs))

  model <- tryCatch(
    stats::lm(fml, data = dt),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] model failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(model)) return(NULL)

  coef_mat  <- summary(model)$coefficients
  all_terms <- rownames(coef_mat)

  idx <- if (is_factor) {
    which(startsWith(all_terms, exposure))
  } else {
    which(all_terms == exposure)
  }

  if (length(idx) == 0L) {
    cli::cli_alert_warning(
      "  No terms found for exposure {.field {exposure}} -- skipped."
    )
    return(NULL)
  }

  # CI via confint.lm() uses t-distribution (exact for normal linear models)
  ci_mat <- stats::confint(model, level = conf_level)
  if (!is.matrix(ci_mat)) {
    ci_mat <- matrix(ci_mat, nrow = 1L,
                     dimnames = list(all_terms[idx], names(ci_mat)))
  }

  terms_dt <- data.table::data.table(
    term     = all_terms[idx],
    beta     = coef_mat[idx, "Estimate"],
    se       = coef_mat[idx, "Std. Error"],
    CI_lower = ci_mat[idx, 1L],
    CI_upper = ci_mat[idx, 2L],
    p_value  = coef_mat[idx, "Pr(>|t|)"]
  )

  terms_dt[, `:=`(
    exposure   = exposure,
    model      = model_label,
    n          = stats::nobs(model),
    beta_label = sprintf("%.2f (%.2f-%.2f)", beta, CI_lower, CI_upper)
  )]

  data.table::setcolorder(
    terms_dt,
    c("exposure", "term", "model", "n",
      "beta", "se", "CI_lower", "CI_upper", "p_value", "beta_label")
  )
  terms_dt
}


# Fit one coxph model and run cox.zph() PH assumption test for one exposure.
# Returns a tidy data.table with Schoenfeld residual test results.
# Term-level results (one row per exposure term) are combined with the
# global test for the whole model (global_chisq / global_df / global_p).
#
# Args:
#   dt           (data.table) Dataset with ".ukb_event" column pre-added.
#   time_col     (character)  Follow-up time column name.
#   exposure     (character)  Single exposure variable name.
#   covariates   (character or NULL) Covariate column names.
#   strata       (character or NULL) Strata variable name.
#   model_label  (character)  Human-readable model name for the output.
#
# Returns:
#   data.table or NULL on failure.
.run_one_zph_test <- function(dt, time_col, exposure, covariates,
                               strata, model_label) {

  is_factor <- is.factor(dt[[exposure]])

  rhs_parts <- c(exposure, covariates)
  if (!is.null(strata)) {
    rhs_parts <- c(rhs_parts, paste0("strata(", strata, ")"))
  }
  rhs <- paste(rhs_parts, collapse = " + ")
  fml <- stats::as.formula(
    sprintf("Surv(%s, .ukb_event) ~ %s", time_col, rhs)
  )

  model <- tryCatch(
    survival::coxph(fml, data = dt),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] coxph failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(model)) return(NULL)

  zph <- tryCatch(
    survival::cox.zph(model),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] cox.zph failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(zph)) return(NULL)

  tbl       <- zph$table           # rows = terms + "GLOBAL", cols = chisq, df, p
  all_terms <- rownames(tbl)

  # Global test row (one per model)
  global_chisq <- tbl["GLOBAL", "chisq"]
  global_df    <- tbl["GLOBAL", "df"]
  global_p     <- tbl["GLOBAL", "p"]

  # Exposure-specific term rows
  idx <- if (is_factor) {
    which(startsWith(all_terms, exposure))
  } else {
    which(all_terms == exposure)
  }

  if (length(idx) == 0L) {
    cli::cli_alert_warning(
      "  No terms found for exposure {.field {exposure}} in zph table -- skipped."
    )
    return(NULL)
  }

  terms_dt <- data.table::data.table(
    term         = all_terms[idx],
    chisq        = tbl[idx, "chisq"],
    df           = tbl[idx, "df"],
    p_value      = tbl[idx, "p"],
    ph_satisfied = tbl[idx, "p"] > 0.05,
    global_chisq = global_chisq,
    global_df    = global_df,
    global_p     = global_p
  )

  terms_dt[, `:=`(
    exposure = exposure,
    model    = model_label
  )]

  data.table::setcolorder(
    terms_dt,
    c("exposure", "term", "model",
      "chisq", "df", "p_value", "ph_satisfied",
      "global_chisq", "global_df", "global_p")
  )
  terms_dt
}


# Fit one Fine-Gray competing risks model (finegray + weighted coxph) for a
# single exposure and return a tidy data.table.
#
# The analysis dataset `dt` must already contain `.fg_status` (factor with
# levels "censor", "event", "compete") and `time_col`. Only the columns
# listed in `need_cols` are passed to finegray(), so the formula `~ .`
# carries exactly the right predictors into the weighted coxph step.
#
# SHR and CI are extracted from `summary()$conf.int` (columns 1, 3, 4):
#   1 = exp(coef)  →  SHR
#   3 = lower .xx  →  CI_lower
#   4 = upper .xx  →  CI_upper
# p-value from `summary()$coefficients[, "Pr(>|z|)"]` (robust z-based).
#
# n_compete is counted from the complete-case subset *before* finegray()
# expansion, i.e. the number of participants with a competing event who
# contributed to the analysis.
#
# Args:
#   dt           (data.table) Dataset with `.fg_status` pre-built.
#   time_col     (character)  Follow-up time column name.
#   exposure     (character)  Single exposure variable name.
#   covariates   (character or NULL) Covariate column names.
#   model_label  (character)  Human-readable model name for the output.
#   conf_level   (numeric)    Confidence level for CI.
#
# Returns:
#   data.table or NULL on failure.
.run_one_fg_model <- function(dt, time_col, exposure, covariates,
                               model_label, conf_level) {

  is_factor <- is.factor(dt[[exposure]])

  # Keep only columns needed; drop NA rows (complete-case analysis)
  need_cols <- unique(c(time_col, ".fg_status", exposure, covariates))
  need_cols <- intersect(need_cols, names(dt))
  sub <- stats::na.omit(dt[, need_cols, with = FALSE])

  if (nrow(sub) == 0L) {
    cli::cli_alert_warning(
      "  [{model_label} | {.field {exposure}}] no complete cases -- skipped."
    )
    return(NULL)
  }

  n_compete <- sum(sub$.fg_status == "compete", na.rm = TRUE)

  # Bind Surv locally so finegray() can resolve it when evaluating the formula.
  # finegray() evaluates formulas in the caller's environment, which inside a
  # package function does not automatically include survival:: exports.
  Surv <- survival::Surv  # nolint: object_usage_linter

  # Expand data with Fine-Gray inverse probability of censoring weights
  fg_fml  <- stats::as.formula(sprintf("Surv(%s, .fg_status) ~ .", time_col))
  fg_data <- tryCatch(
    survival::finegray(fg_fml, data = sub, etype = "event"),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] finegray() failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(fg_data)) return(NULL)

  # Weighted Cox on the expanded Fine-Gray dataset
  rhs     <- paste(c(exposure, covariates), collapse = " + ")
  cox_fml <- stats::as.formula(
    sprintf("Surv(fgstart, fgstop, fgstatus) ~ %s", rhs)
  )
  model <- tryCatch(
    survival::coxph(cox_fml, data = fg_data, weight = fgwt),
    error = function(e) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] weighted coxph failed: {conditionMessage(e)}"
      )
      NULL
    }
  )
  if (is.null(model)) return(NULL)

  s        <- summary(model)
  coef_mat <- s$coefficients  # coef | exp(coef) | se(coef) | robust se | z | Pr(>|z|)
  ci_mat   <- s$conf.int      # exp(coef) | exp(-coef) | lower .xx | upper .xx

  # Ensure matrix (single-term model returns named vector)
  if (!is.matrix(coef_mat)) {
    coef_mat <- matrix(coef_mat, nrow = 1L,
                       dimnames = list(exposure, names(coef_mat)))
    ci_mat   <- matrix(ci_mat,   nrow = 1L,
                       dimnames = list(exposure, names(ci_mat)))
  }

  all_terms <- rownames(coef_mat)
  idx <- if (is_factor) {
    which(startsWith(all_terms, exposure))
  } else {
    which(all_terms == exposure)
  }

  if (length(idx) == 0L) {
    cli::cli_alert_warning(
      "  No terms found for exposure {.field {exposure}} -- skipped."
    )
    return(NULL)
  }

  terms_dt <- data.table::data.table(
    term     = all_terms[idx],
    SHR      = ci_mat[idx, 1L],   # exp(coef)
    CI_lower = ci_mat[idx, 3L],   # lower .xx
    CI_upper = ci_mat[idx, 4L],   # upper .xx
    p_value  = coef_mat[idx, "Pr(>|z|)"]
  )

  terms_dt[, `:=`(
    exposure  = exposure,
    model     = model_label,
    n         = model$n,
    n_events  = model$nevent,
    n_compete = n_compete,
    SHR_label = sprintf("%.2f (%.2f-%.2f)", SHR, CI_lower, CI_upper)
  )]

  data.table::setcolorder(
    terms_dt,
    c("exposure", "term", "model", "n", "n_events", "n_compete",
      "SHR", "CI_lower", "CI_upper", "p_value", "SHR_label")
  )
  terms_dt
}


# Compute an LRT p-value for the exposure x by interaction on the full dataset.
# Fits a reduced model (exposure + by + covariates) and a full model
# (exposure * by + covariates) and extracts the LRT p-value via anova().
# Returns NA_real_ (with a warning) when either model fails or the p-value
# column cannot be located.
#
# For coxph: anova(mod_r, mod_f) uses the log-likelihood ratio.
# For glm:   anova(mod_r, mod_f, test = "Chisq") uses the deviance LRT.
# For lm:    anova(mod_r, mod_f) uses an F-test (equivalent to LRT for normal
#            linear models).
#
# The p-value column is identified by grepping for column names starting with
# "P" or "Pr", which covers all three anova output formats:
#   coxph   → "P(>|Chi|)"
#   glm     → "Pr(>Chi)"
#   lm      → "Pr(>F)"
#
# Args:
#   dt           (data.table) Full dataset; .ukb_event pre-added for coxph/logistic.
#   method       (character) "coxph", "logistic", or "linear".
#   outcome_col  (character) Outcome column name (continuous for linear).
#   time_col     (character or NULL) Follow-up time column (coxph only).
#   exposure     (character) Exposure variable name.
#   by           (character) Subgroup stratification variable name.
#   covariates   (character or NULL) Additional covariates.
#   model_label  (character) Label for warning messages.
#
# Returns:
#   numeric scalar p-value, or NA_real_ on failure.
.run_one_interaction_lrt <- function(dt, method, outcome_col, time_col,
                                      exposure, by, covariates, model_label) {

  rhs_base <- paste(c(exposure, by, covariates), collapse = " + ")
  rhs_full <- paste(c(paste0(exposure, " * ", by), covariates), collapse = " + ")

  lrt_p <- tryCatch({
    if (method == "coxph") {
      fml_r <- stats::as.formula(
        sprintf("Surv(%s, .ukb_event) ~ %s", time_col, rhs_base))
      fml_f <- stats::as.formula(
        sprintf("Surv(%s, .ukb_event) ~ %s", time_col, rhs_full))
      mod_r <- survival::coxph(fml_r, data = dt)
      mod_f <- survival::coxph(fml_f, data = dt)
      aov   <- anova(mod_r, mod_f)
    } else if (method == "logistic") {
      fml_r <- stats::as.formula(sprintf(".ukb_event ~ %s", rhs_base))
      fml_f <- stats::as.formula(sprintf(".ukb_event ~ %s", rhs_full))
      mod_r <- stats::glm(fml_r, data = dt, family = stats::binomial(link = "logit"))
      mod_f <- stats::glm(fml_f, data = dt, family = stats::binomial(link = "logit"))
      aov   <- stats::anova(mod_r, mod_f, test = "Chisq")
    } else {  # linear
      fml_r <- stats::as.formula(sprintf("%s ~ %s", outcome_col, rhs_base))
      fml_f <- stats::as.formula(sprintf("%s ~ %s", outcome_col, rhs_full))
      mod_r <- stats::lm(fml_r, data = dt)
      mod_f <- stats::lm(fml_f, data = dt)
      aov   <- stats::anova(mod_r, mod_f)
    }

    # Locate the p-value column (covers all three anova output formats)
    p_col <- grep("^(P|Pr)", colnames(aov), value = TRUE)[1L]
    if (is.na(p_col)) {
      cli::cli_alert_warning(
        "  [{model_label} | {.field {exposure}}] interaction LRT: p-value column not found in anova output."
      )
      return(NA_real_)
    }
    as.numeric(utils::tail(aov, 1L)[[p_col]])

  }, error = function(e) {
    cli::cli_alert_warning(
      "  [{model_label} | {.field {exposure}}] interaction LRT failed: {conditionMessage(e)}"
    )
    NA_real_
  })

  lrt_p
}
