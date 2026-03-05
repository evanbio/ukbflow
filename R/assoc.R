# =============================================================================
# assoc.R — association analysis for UKB survival data
# =============================================================================


#' Cox proportional hazards association analysis
#'
#' Fits one or more Cox models for each exposure variable and returns a tidy
#' result table suitable for downstream forest plots. By default, two standard
#' adjustment models are always included alongside any user-specified model:
#'
#' \itemize{
#'   \item \strong{Unadjusted} — no covariates (crude).
#'   \item \strong{Age and sex adjusted} — age + sex auto-detected from the
#'     data via UKB field IDs (21022 and 31). Skipped with a warning if either
#'     column cannot be found.
#'   \item \strong{Fully adjusted} — the covariates supplied via the
#'     \code{covariates} argument. Only run when \code{covariates} is non-NULL.
#' }
#'
#' \strong{Outcome coding}: \code{outcome_col} may be \code{logical}
#' (\code{TRUE}/\code{FALSE}) or integer/numeric (\code{0}/\code{1}).
#' Logical values are converted to integer internally.
#'
#' \strong{Exposure types supported}:
#' \itemize{
#'   \item \emph{Binary} — \code{0}/\code{1} or \code{TRUE}/\code{FALSE};
#'     produces one \code{term} row per model.
#'   \item \emph{Factor} — produces one \code{term} row per non-reference level.
#'   \item \emph{Numeric} (continuous) — produces one \code{term} row per model.
#' }
#'
#' @param data (data.frame or data.table) Analysis dataset. Must contain all
#'   columns referenced by \code{outcome_col}, \code{time_col}, and
#'   \code{exposure_col}.
#' @param outcome_col (character) Name of the event indicator column.
#'   Accepts \code{logical} (\code{TRUE}/\code{FALSE}) or numeric/integer
#'   (\code{0}/\code{1}).
#' @param time_col (character) Name of the follow-up time column (numeric,
#'   in consistent units, e.g. years).
#' @param exposure_col (character) One or more exposure variable names.
#'   Each variable is analysed separately; results are stacked row-wise.
#' @param covariates (character or NULL) Additional covariate column names for
#'   the \strong{Fully adjusted} model (e.g.
#'   \code{c("tdi", "smoking", paste0("pc", 1:10))}). When \code{NULL}
#'   (default), the Fully adjusted model is not run.
#' @param base (logical) If \code{TRUE} (default), always include the
#'   \strong{Unadjusted} and \strong{Age and sex adjusted} models in addition
#'   to any user-specified \code{covariates} model. Set to \code{FALSE} to run
#'   only the Fully adjusted model (requires \code{covariates} to be non-NULL).
#' @param strata (character or NULL) Optional stratification variable.
#'   Passed to \code{survival::strata()} in the Cox formula.
#' @param conf_level (numeric) Confidence level for hazard ratio intervals.
#'   Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per exposure \eqn{\times} term
#'   \eqn{\times} model combination, and the following columns:
#'   \describe{
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{term}}{Coefficient name as returned by \code{coxph} (e.g.
#'       \code{"bmi_categoryObese"} for a factor, or the variable name itself
#'       for numeric/binary exposures).}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Age and sex adjusted} < \code{Fully adjusted}.}
#'     \item{\code{n}}{Number of participants included in the model (after
#'       \code{NA} removal).}
#'     \item{\code{n_events}}{Total number of events in the dataset.}
#'     \item{\code{person_years}}{Total person-years of follow-up (rounded).}
#'     \item{\code{HR}}{Hazard ratio (point estimate).}
#'     \item{\code{CI_lower}}{Lower bound of the confidence interval.}
#'     \item{\code{CI_upper}}{Upper bound of the confidence interval.}
#'     \item{\code{p_value}}{Wald test p-value.}
#'     \item{\code{HR_label}}{Formatted string, e.g.
#'       \code{"1.23 (1.05\u20131.44)"}.}
#'   }
#'
#' @importFrom survival coxph Surv
#' @export
#'
#' @examples
#' \dontrun{
#' # Minimal: crude + age-sex adjusted only
#' res <- assoc_coxph(
#'   data        = cohort,
#'   outcome_col = "cscc_status",   # 0/1 or TRUE/FALSE
#'   time_col    = "followup_years",
#'   exposure_col = c("ad_icd10", "bmi_category")
#' )
#'
#' # Add a Fully adjusted model (Model 3)
#' res <- assoc_coxph(
#'   data         = cohort,
#'   outcome_col  = "cscc_status",
#'   time_col     = "followup_years",
#'   exposure_col = c("ad_icd10", "ad_status"),
#'   covariates   = c("tdi", "smoking", "alcohol_freq",
#'                    paste0("pc", 1:10))
#' )
#'
#' # Only run the Fully adjusted model (skip Unadjusted + Age-sex)
#' res <- assoc_coxph(
#'   data         = cohort,
#'   outcome_col  = "cscc_status",
#'   time_col     = "followup_years",
#'   exposure_col = "ad_icd10",
#'   covariates   = c("age_at_recruitment", "sex", "tdi"),
#'   base         = FALSE
#' )
#' }
assoc_coxph <- function(data,
                         outcome_col,
                         time_col,
                         exposure_col,
                         covariates  = NULL,
                         base        = TRUE,
                         strata      = NULL,
                         conf_level  = 0.95) {

  # ---------------------------------------------------------------------------
  # 0. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }
  all_cols <- names(data)

  missing_cols <- setdiff(
    c(outcome_col, time_col, exposure_col, covariates, strata),
    all_cols
  )
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Column{?s} not found in {.arg data}: {.field {missing_cols}}"
    )
  }

  if (!base && is.null(covariates)) {
    cli::cli_abort(
      "When {.arg base = FALSE}, {.arg covariates} must be supplied."
    )
  }

  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }

  # ---------------------------------------------------------------------------
  # 1. Prepare working copy: normalise outcome + logical exposures
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))

  dt[, .ukb_event := .normalise_event(dt[[outcome_col]], outcome_col)]
  .normalise_logical_exposures(dt, exposure_col)

  # ---------------------------------------------------------------------------
  # 2. Build model list: name -> covariates vector (NULL = crude)
  # ---------------------------------------------------------------------------
  model_list <- list()

  if (base) {
    # Reason: single-bracket + list(NULL) is required to store a NULL value in a
    # named list. Double-bracket assignment [["key"]] <- NULL silently deletes
    # the key instead of setting it, which would drop the Unadjusted model.
    model_list["Unadjusted"] <- list(NULL)

    age_col <- .detect_age_col(dt)
    sex_col <- .detect_sex_col(dt)

    if (is.null(age_col) || is.null(sex_col)) {
      cli::cli_alert_warning(
        paste0(
          "Age and sex adjusted model skipped: ",
          if (is.null(age_col)) "age column (UKB field 21022) not found" else "",
          if (is.null(age_col) && is.null(sex_col)) " and " else "",
          if (is.null(sex_col)) "sex column (UKB field 31) not found" else "",
          "."
        )
      )
    } else {
      model_list[["Age and sex adjusted"]] <- c(age_col, sex_col)
    }
  }

  if (!is.null(covariates) && length(covariates) > 0L) {
    model_list[["Fully adjusted"]] <- covariates
  }

  # ---------------------------------------------------------------------------
  # 3. Run models: each exposure × each model
  # ---------------------------------------------------------------------------
  n_models    <- length(model_list)
  n_exposures <- length(exposure_col)

  cli::cli_h1("assoc_coxph")
  cli::cli_alert_info(
    "{n_exposures} exposure{?s} \u00d7 {n_models} model{?s} = \\
     {n_exposures * n_models} Cox regression{?s}"
  )
  cli::cli_alert_info(
    "Input cohort: {nrow(dt)} participants \\
     (n/n_events/person_years reflect each model\u2019s actual analysis set)"
  )

  results <- vector("list", n_exposures * n_models)
  idx      <- 1L

  for (exp in exposure_col) {

    cli::cli_h2("{.field {exp}}")

    for (model_label in names(model_list)) {

      covs <- model_list[[model_label]]
      res  <- .run_one_cox_model(
        dt           = dt,
        time_col     = time_col,
        exposure     = exp,
        covariates   = covs,
        strata       = strata,
        model_label  = model_label,
        conf_level   = conf_level
      )

      if (!is.null(res)) {
        # Print each term result
        for (i in seq_len(nrow(res))) {
          cli::cli_alert_success(
            "  {model_label} | {res$term[i]}: \\
             HR {res$HR_label[i]}, p = {format.pval(res$p_value[i], digits = 3L)}"
          )
        }
        results[[idx]] <- res
      }
      idx <- idx + 1L
    }
  }

  # ---------------------------------------------------------------------------
  # 4. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), results))

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned — check model warnings above.")
    return(out)
  }

  # Ordered factor for downstream plot ordering
  model_levels <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  out[, model := factor(model, levels = model_levels, ordered = TRUE)]

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {uniqueN(out$exposure)} exposure{?s} and \\
     {uniqueN(out$model)} model{?s}."
  )

  out[]
}


#' @rdname assoc_coxph
#' @export
assoc_cox <- assoc_coxph


#' Logistic regression association analysis
#'
#' Fits one or more logistic regression models for each exposure variable and
#' returns a tidy result table suitable for downstream forest plots. By default,
#' two standard adjustment models are always included:
#'
#' \itemize{
#'   \item \strong{Unadjusted} — no covariates (crude).
#'   \item \strong{Age and sex adjusted} — age + sex auto-detected from the
#'     data via UKB field IDs (21022 and 31). Skipped with a warning if either
#'     column cannot be found.
#'   \item \strong{Fully adjusted} — the covariates supplied via the
#'     \code{covariates} argument. Only run when \code{covariates} is non-NULL.
#' }
#'
#' \strong{Outcome coding}: \code{outcome_col} may be \code{logical}
#' (\code{TRUE}/\code{FALSE}) or integer/numeric (\code{0}/\code{1}).
#' Logical values are converted to integer internally.
#'
#' \strong{CI methods}:
#' \itemize{
#'   \item \code{"wald"} (default) — fast, appropriate for large UKB samples.
#'   \item \code{"profile"} — profile likelihood CI via \code{confint.glm()};
#'     slower but more accurate for small or sparse data.
#' }
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Binary outcome column (\code{0}/\code{1} or
#'   \code{TRUE}/\code{FALSE}).
#' @param exposure_col (character) One or more exposure variable names.
#' @param covariates (character or NULL) Covariate column names for the
#'   \strong{Fully adjusted} model. Default: \code{NULL}.
#' @param base (logical) Include \strong{Unadjusted} and \strong{Age and sex
#'   adjusted} models. Default: \code{TRUE}.
#' @param ci_method (character) CI calculation method: \code{"wald"} (default)
#'   or \code{"profile"}.
#' @param conf_level (numeric) Confidence level. Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per exposure \eqn{\times} term
#'   \eqn{\times} model combination, and columns:
#'   \describe{
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{term}}{Coefficient name (e.g. \code{"bmi_categoryObese"}).}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Age and sex adjusted} < \code{Fully adjusted}.}
#'     \item{\code{n}}{Participants in model (after NA removal).}
#'     \item{\code{n_cases}}{Number of cases (outcome = 1) in model.}
#'     \item{\code{OR}}{Odds ratio (point estimate).}
#'     \item{\code{CI_lower}}{Lower confidence bound.}
#'     \item{\code{CI_upper}}{Upper confidence bound.}
#'     \item{\code{p_value}}{Wald test p-value.}
#'     \item{\code{OR_label}}{Formatted string, e.g. \code{"1.23 (1.05\u20131.44)"}.}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Minimal: crude + age-sex adjusted
#' res <- assoc_logistic(
#'   data         = cohort,
#'   outcome_col  = "case_status",
#'   exposure_col = c("ad_icd10", "bmi_category")
#' )
#'
#' # With Fully adjusted model + profile likelihood CI
#' res <- assoc_logistic(
#'   data         = cohort,
#'   outcome_col  = "case_status",
#'   exposure_col = "ad_icd10",
#'   covariates   = c("tdi", "smoking", paste0("pc", 1:10)),
#'   ci_method    = "profile"
#' )
#' }
assoc_logistic <- function(data,
                            outcome_col,
                            exposure_col,
                            covariates = NULL,
                            base       = TRUE,
                            ci_method  = c("wald", "profile"),
                            conf_level = 0.95) {

  ci_method <- match.arg(ci_method)

  # ---------------------------------------------------------------------------
  # 0. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }

  missing_cols <- setdiff(
    c(outcome_col, exposure_col, covariates),
    names(data)
  )
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Column{?s} not found in {.arg data}: {.field {missing_cols}}"
    )
  }

  if (!base && is.null(covariates)) {
    cli::cli_abort(
      "When {.arg base = FALSE}, {.arg covariates} must be supplied."
    )
  }

  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }

  # ---------------------------------------------------------------------------
  # 1. Prepare working copy
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))

  dt[, .ukb_event := .normalise_event(dt[[outcome_col]], outcome_col)]
  .normalise_logical_exposures(dt, exposure_col)

  # ---------------------------------------------------------------------------
  # 2. Build model list
  # ---------------------------------------------------------------------------
  model_list <- list()

  if (base) {
    model_list["Unadjusted"] <- list(NULL)

    age_col <- .detect_age_col(dt)
    sex_col <- .detect_sex_col(dt)

    if (is.null(age_col) || is.null(sex_col)) {
      cli::cli_alert_warning(
        paste0(
          "Age and sex adjusted model skipped: ",
          if (is.null(age_col)) "age column (UKB field 21022) not found" else "",
          if (is.null(age_col) && is.null(sex_col)) " and " else "",
          if (is.null(sex_col)) "sex column (UKB field 31) not found" else "",
          "."
        )
      )
    } else {
      model_list[["Age and sex adjusted"]] <- c(age_col, sex_col)
    }
  }

  if (!is.null(covariates) && length(covariates) > 0L) {
    model_list[["Fully adjusted"]] <- covariates
  }

  # ---------------------------------------------------------------------------
  # 3. Run models: each exposure × each model
  # ---------------------------------------------------------------------------
  n_models    <- length(model_list)
  n_exposures <- length(exposure_col)

  cli::cli_h1("assoc_logistic")
  cli::cli_alert_info(
    "{n_exposures} exposure{?s} \u00d7 {n_models} model{?s} = \\
     {n_exposures * n_models} logistic regression{?s}"
  )
  cli::cli_alert_info(
    "Input cohort: {nrow(dt)} participants | CI method: {ci_method} \\
     (n/n_cases reflect each model\u2019s actual analysis set)"
  )

  results <- vector("list", n_exposures * n_models)
  idx      <- 1L

  for (exp in exposure_col) {

    cli::cli_h2("{.field {exp}}")

    for (model_label in names(model_list)) {

      covs <- model_list[[model_label]]
      res  <- .run_one_logistic_model(
        dt          = dt,
        exposure    = exp,
        covariates  = covs,
        model_label = model_label,
        ci_method   = ci_method,
        conf_level  = conf_level
      )

      if (!is.null(res)) {
        for (i in seq_len(nrow(res))) {
          cli::cli_alert_success(
            "  {model_label} | {res$term[i]}: \\
             OR {res$OR_label[i]}, p = {format.pval(res$p_value[i], digits = 3L)}"
          )
        }
        results[[idx]] <- res
      }
      idx <- idx + 1L
    }
  }

  # ---------------------------------------------------------------------------
  # 4. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), results))

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned — check model warnings above.")
    return(out)
  }

  model_levels <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  out[, model := factor(model, levels = model_levels, ordered = TRUE)]

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {uniqueN(out$exposure)} exposure{?s} and \\
     {uniqueN(out$model)} model{?s}."
  )

  out[]
}


#' @rdname assoc_logistic
#' @export
assoc_logit <- assoc_logistic


#' Linear regression association analysis
#'
#' Fits one or more linear regression models for each exposure variable and
#' returns a tidy result table. By default, two standard adjustment models are
#' always included:
#'
#' \itemize{
#'   \item \strong{Unadjusted} — no covariates (crude).
#'   \item \strong{Age and sex adjusted} — age + sex auto-detected from the
#'     data via UKB field IDs (21022 and 31). Skipped with a warning if either
#'     column cannot be found.
#'   \item \strong{Fully adjusted} — the covariates supplied via the
#'     \code{covariates} argument. Only run when \code{covariates} is non-NULL.
#' }
#'
#' \strong{Outcome}: must be a continuous numeric variable. Passing a binary
#' (0/1) or logical column will trigger a warning, as logistic regression is
#' more appropriate in that case.
#'
#' \strong{CI method}: based on the t-distribution via \code{confint.lm()},
#' which is exact under the normal linear model assumption. There is no
#' \code{ci_method} argument (unlike \code{\link{assoc_logistic}}) as profile
#' likelihood does not apply to \code{lm}.
#'
#' \strong{SE column}: the standard error of \eqn{\beta} is included to
#' support downstream meta-analysis and GWAS-style summary statistics.
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Name of the continuous numeric outcome column.
#' @param exposure_col (character) One or more exposure variable names.
#' @param covariates (character or NULL) Covariate column names for the
#'   \strong{Fully adjusted} model. Default: \code{NULL}.
#' @param base (logical) Include \strong{Unadjusted} and \strong{Age and sex
#'   adjusted} models. Default: \code{TRUE}.
#' @param conf_level (numeric) Confidence level. Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per exposure \eqn{\times} term
#'   \eqn{\times} model combination, and columns:
#'   \describe{
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{term}}{Coefficient name (e.g. \code{"bmi_categoryObese"}).}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Age and sex adjusted} < \code{Fully adjusted}.}
#'     \item{\code{n}}{Participants in model (after NA removal).}
#'     \item{\code{beta}}{Regression coefficient (\eqn{\beta}).}
#'     \item{\code{se}}{Standard error of \eqn{\beta}.}
#'     \item{\code{CI_lower}}{Lower confidence bound.}
#'     \item{\code{CI_upper}}{Upper confidence bound.}
#'     \item{\code{p_value}}{t-test p-value.}
#'     \item{\code{beta_label}}{Formatted string, e.g.
#'       \code{"0.23 (0.05\u20130.41)"}.}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Minimal: crude + age-sex adjusted
#' res <- assoc_linear(
#'   data         = cohort,
#'   outcome_col  = "bmi",
#'   exposure_col = c("ad_icd10", "smoking_pack_years")
#' )
#'
#' # With Fully adjusted model
#' res <- assoc_linear(
#'   data         = cohort,
#'   outcome_col  = "bmi",
#'   exposure_col = "ad_icd10",
#'   covariates   = c("tdi", "alcohol_freq", paste0("pc", 1:10))
#' )
#' }
assoc_linear <- function(data,
                          outcome_col,
                          exposure_col,
                          covariates = NULL,
                          base       = TRUE,
                          conf_level = 0.95) {

  # ---------------------------------------------------------------------------
  # 0. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }

  missing_cols <- setdiff(
    c(outcome_col, exposure_col, covariates),
    names(data)
  )
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Column{?s} not found in {.arg data}: {.field {missing_cols}}"
    )
  }

  if (!base && is.null(covariates)) {
    cli::cli_abort(
      "When {.arg base = FALSE}, {.arg covariates} must be supplied."
    )
  }

  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }

  # Warn if outcome looks binary — logistic regression is more appropriate
  outcome_vec <- data[[outcome_col]]
  if (is.logical(outcome_vec) ||
      (is.numeric(outcome_vec) &&
       all(stats::na.omit(unique(outcome_vec)) %in% c(0, 1)))) {
    cli::cli_alert_warning(
      "outcome_col {.field {outcome_col}} appears binary (0/1 or logical). \\
       Consider {.fn assoc_logistic} instead."
    )
  }

  if (!is.numeric(outcome_vec) && !is.logical(outcome_vec)) {
    cli::cli_abort(
      "outcome_col {.field {outcome_col}} must be numeric. \\
       Found: {class(outcome_vec)[1]}."
    )
  }

  # ---------------------------------------------------------------------------
  # 1. Prepare working copy: normalise logical exposures only
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))
  .normalise_logical_exposures(dt, exposure_col)

  # ---------------------------------------------------------------------------
  # 2. Build model list
  # ---------------------------------------------------------------------------
  model_list <- list()

  if (base) {
    model_list["Unadjusted"] <- list(NULL)

    age_col <- .detect_age_col(dt)
    sex_col <- .detect_sex_col(dt)

    if (is.null(age_col) || is.null(sex_col)) {
      cli::cli_alert_warning(
        paste0(
          "Age and sex adjusted model skipped: ",
          if (is.null(age_col)) "age column (UKB field 21022) not found" else "",
          if (is.null(age_col) && is.null(sex_col)) " and " else "",
          if (is.null(sex_col)) "sex column (UKB field 31) not found" else "",
          "."
        )
      )
    } else {
      model_list[["Age and sex adjusted"]] <- c(age_col, sex_col)
    }
  }

  if (!is.null(covariates) && length(covariates) > 0L) {
    model_list[["Fully adjusted"]] <- covariates
  }

  # ---------------------------------------------------------------------------
  # 3. Run models: each exposure × each model
  # ---------------------------------------------------------------------------
  n_models    <- length(model_list)
  n_exposures <- length(exposure_col)

  cli::cli_h1("assoc_linear")
  cli::cli_alert_info(
    "{n_exposures} exposure{?s} \u00d7 {n_models} model{?s} = \\
     {n_exposures * n_models} linear regression{?s}"
  )
  cli::cli_alert_info(
    "Input cohort: {nrow(dt)} participants \\
     (n reflects each model\u2019s actual analysis set)"
  )

  results <- vector("list", n_exposures * n_models)
  idx      <- 1L

  for (exp in exposure_col) {

    cli::cli_h2("{.field {exp}}")

    for (model_label in names(model_list)) {

      covs <- model_list[[model_label]]
      res  <- .run_one_linear_model(
        dt          = dt,
        outcome_col = outcome_col,
        exposure    = exp,
        covariates  = covs,
        model_label = model_label,
        conf_level  = conf_level
      )

      if (!is.null(res)) {
        for (i in seq_len(nrow(res))) {
          cli::cli_alert_success(
            "  {model_label} | {res$term[i]}: \\
             \u03b2 {res$beta_label[i]}, p = {format.pval(res$p_value[i], digits = 3L)}"
          )
        }
        results[[idx]] <- res
      }
      idx <- idx + 1L
    }
  }

  # ---------------------------------------------------------------------------
  # 4. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), results))

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned — check model warnings above.")
    return(out)
  }

  model_levels <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  out[, model := factor(model, levels = model_levels, ordered = TRUE)]

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {uniqueN(out$exposure)} exposure{?s} and \\
     {uniqueN(out$model)} model{?s}."
  )

  out[]
}


#' @rdname assoc_linear
#' @export
assoc_lm <- assoc_linear


#' Proportional hazards assumption test for Cox regression
#'
#' Tests the proportional hazards (PH) assumption using Schoenfeld residuals
#' via \code{\link[survival]{cox.zph}}. Re-fits the same models as
#' \code{\link{assoc_coxph}} (same interface) and returns a tidy result table
#' with term-level and global test statistics.
#'
#' A non-significant p-value (p > 0.05) indicates the PH assumption is
#' satisfied for that term. The global test (\code{global_p}) reflects the
#' overall PH assumption for the whole model.
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Binary event indicator (\code{0}/\code{1}
#'   or \code{TRUE}/\code{FALSE}).
#' @param time_col (character) Follow-up time column name.
#' @param exposure_col (character) One or more exposure variable names.
#' @param covariates (character or NULL) Covariates for the Fully adjusted
#'   model. Default: \code{NULL}.
#' @param base (logical) Include Unadjusted and Age and sex adjusted models.
#'   Default: \code{TRUE}.
#' @param strata (character or NULL) Optional stratification variable.
#'
#' @return A \code{data.table} with one row per exposure \eqn{\times} term
#'   \eqn{\times} model combination, and columns:
#'   \describe{
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{term}}{Coefficient name.}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Age and sex adjusted} < \code{Fully adjusted}.}
#'     \item{\code{chisq}}{Schoenfeld residual chi-squared statistic.}
#'     \item{\code{df}}{Degrees of freedom.}
#'     \item{\code{p_value}}{P-value for the PH test (term-level).}
#'     \item{\code{ph_satisfied}}{Logical; \code{TRUE} if \code{p_value > 0.05}.}
#'     \item{\code{global_chisq}}{Global chi-squared for the whole model.}
#'     \item{\code{global_df}}{Global degrees of freedom.}
#'     \item{\code{global_p}}{Global p-value for the whole model.}
#'   }
#'
#' @importFrom survival cox.zph
#' @export
#'
#' @examples
#' \dontrun{
#' # Check PH assumption for same models as assoc_coxph()
#' zph <- assoc_coxph_zph(
#'   data         = cohort,
#'   outcome_col  = "cscc_status",
#'   time_col     = "followup_years",
#'   exposure_col = c("ad_icd10", "bmi_category"),
#'   covariates   = c("tdi", "smoking", paste0("pc", 1:10))
#' )
#'
#' # Quick check: any violations?
#' zph[ph_satisfied == FALSE]
#' }
assoc_coxph_zph <- function(data,
                              outcome_col,
                              time_col,
                              exposure_col,
                              covariates = NULL,
                              base       = TRUE,
                              strata     = NULL) {

  # ---------------------------------------------------------------------------
  # 0. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }

  missing_cols <- setdiff(
    c(outcome_col, time_col, exposure_col, covariates, strata),
    names(data)
  )
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Column{?s} not found in {.arg data}: {.field {missing_cols}}"
    )
  }

  if (!base && is.null(covariates)) {
    cli::cli_abort(
      "When {.arg base = FALSE}, {.arg covariates} must be supplied."
    )
  }

  # ---------------------------------------------------------------------------
  # 1. Prepare working copy
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))
  dt[, .ukb_event := .normalise_event(dt[[outcome_col]], outcome_col)]
  .normalise_logical_exposures(dt, exposure_col)

  # ---------------------------------------------------------------------------
  # 2. Build model list (identical logic to assoc_coxph)
  # ---------------------------------------------------------------------------
  model_list <- list()

  if (base) {
    model_list["Unadjusted"] <- list(NULL)

    age_col <- .detect_age_col(dt)
    sex_col <- .detect_sex_col(dt)

    if (is.null(age_col) || is.null(sex_col)) {
      cli::cli_alert_warning(
        paste0(
          "Age and sex adjusted model skipped: ",
          if (is.null(age_col)) "age column (UKB field 21022) not found" else "",
          if (is.null(age_col) && is.null(sex_col)) " and " else "",
          if (is.null(sex_col)) "sex column (UKB field 31) not found" else "",
          "."
        )
      )
    } else {
      model_list[["Age and sex adjusted"]] <- c(age_col, sex_col)
    }
  }

  if (!is.null(covariates) && length(covariates) > 0L) {
    model_list[["Fully adjusted"]] <- covariates
  }

  # ---------------------------------------------------------------------------
  # 3. Run zph tests: each exposure × each model
  # ---------------------------------------------------------------------------
  n_models    <- length(model_list)
  n_exposures <- length(exposure_col)

  cli::cli_h1("assoc_coxph_zph")
  cli::cli_alert_info(
    "{n_exposures} exposure{?s} \u00d7 {n_models} model{?s} = \\
     {n_exposures * n_models} PH assumption test{?s}"
  )

  results <- vector("list", n_exposures * n_models)
  idx      <- 1L

  for (exp in exposure_col) {

    cli::cli_h2("{.field {exp}}")

    for (model_label in names(model_list)) {

      covs <- model_list[[model_label]]
      res  <- .run_one_zph_test(
        dt          = dt,
        time_col    = time_col,
        exposure    = exp,
        covariates  = covs,
        strata      = strata,
        model_label = model_label
      )

      if (!is.null(res)) {
        for (i in seq_len(nrow(res))) {
          status <- if (res$ph_satisfied[i]) "\u2713 satisfied" else "\u2717 VIOLATED"
          cli::cli_alert_success(
            "  {model_label} | {res$term[i]}: \\
             \u03c7\u00b2 = {round(res$chisq[i], 3)}, \\
             p = {format.pval(res$p_value[i], digits = 3L)} {status}"
          )
        }
        cli::cli_alert_info(
          "  Global: \u03c7\u00b2 = {round(res$global_chisq[1], 3)}, \\
           p = {format.pval(res$global_p[1], digits = 3L)}"
        )
        results[[idx]] <- res
      }
      idx <- idx + 1L
    }
  }

  # ---------------------------------------------------------------------------
  # 4. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), results))

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned — check model warnings above.")
    return(out)
  }

  model_levels <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  out[, model := factor(model, levels = model_levels, ordered = TRUE)]

  n_violated <- sum(!out$ph_satisfied)
  if (n_violated == 0L) {
    cli::cli_alert_success(
      "Done: all {nrow(out)} term{?s} satisfy the PH assumption."
    )
  } else {
    cli::cli_alert_warning(
      "Done: {n_violated}/{nrow(out)} term{?s} violate the PH assumption \\
       (p \u2264 0.05) \u2014 consider {.code strata()} or time-varying effects."
    )
  }

  out[]
}


#' @rdname assoc_coxph_zph
#' @export
assoc_zph <- assoc_coxph_zph
