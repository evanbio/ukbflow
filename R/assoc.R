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
#'   data         = cohort,
#'   outcome_col  = "outcome_status",   # 0/1 or TRUE/FALSE
#'   time_col     = "followup_years",
#'   exposure_col = c("exposure", "bmi_category")
#' )
#'
#' # Add a Fully adjusted model (Model 3)
#' res <- assoc_coxph(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = "exposure",
#'   covariates   = c("tdi", "smoking", "alcohol_freq",
#'                    paste0("pc", 1:10))
#' )
#'
#' # Only run the Fully adjusted model (skip Unadjusted + Age-sex)
#' res <- assoc_coxph(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = "exposure",
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
#'   outcome_col  = "outcome_status",
#'   exposure_col = c("exposure", "bmi_category")
#' )
#'
#' # With Fully adjusted model + profile likelihood CI
#' res <- assoc_logistic(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   exposure_col = "exposure",
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
#'   exposure_col = c("exposure", "smoking_pack_years")
#' )
#'
#' # With Fully adjusted model
#' res <- assoc_linear(
#'   data         = cohort,
#'   outcome_col  = "bmi",
#'   exposure_col = "exposure",
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
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = c("exposure", "bmi_category"),
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


#' Subgroup association analysis with optional interaction test
#'
#' Stratifies the dataset by a single grouping variable (\code{by}) and runs
#' the specified association model (\code{coxph}, \code{logistic}, or
#' \code{linear}) within each subgroup. Unlike \code{\link{assoc_coxph}} and
#' its siblings, there is no automatic age-and-sex-adjusted model: at the
#' subgroup level the variable that defines the stratum would have zero
#' variance, making the auto-detected adjustment meaningless. Instead, two
#' models are available:
#'
#' \itemize{
#'   \item \strong{Unadjusted} — always run (no covariates).
#'   \item \strong{Fully adjusted} — run when \code{covariates} is non-NULL.
#'     Users are responsible for excluding the \code{by} variable from
#'     \code{covariates} (a warning is issued if it is included).
#' }
#'
#' \strong{Interaction test}: when \code{interaction = TRUE} (default), a
#' likelihood ratio test (LRT) for the exposure \eqn{\times} by interaction is
#' computed on the \emph{full} dataset for each exposure \eqn{\times} model
#' combination and appended as \code{p_interaction}. LRT is preferred over
#' Wald because it handles factor, binary, and continuous \code{by} variables
#' uniformly without requiring the user to recode the \code{by} variable.
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Outcome column name.
#' @param time_col (character or NULL) Follow-up time column (required when
#'   \code{method = "coxph"}).
#' @param exposure_col (character) One or more exposure variable names.
#' @param by (character) Single stratification variable name. Its unique
#'   non-NA values (or factor levels, in order) define the subgroups.
#' @param method (character) Regression method: \code{"coxph"} (default),
#'   \code{"logistic"}, or \code{"linear"}.
#' @param covariates (character or NULL) Covariate column names for the Fully
#'   adjusted model. When \code{NULL}, only the Unadjusted model is run.
#' @param interaction (logical) Compute the LRT p-value for the exposure
#'   \eqn{\times} by interaction on the full dataset. Default: \code{TRUE}.
#' @param conf_level (numeric) Confidence level. Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per subgroup level \eqn{\times}
#'   exposure \eqn{\times} term \eqn{\times} model, containing:
#'   \describe{
#'     \item{\code{subgroup}}{Name of the \code{by} variable.}
#'     \item{\code{subgroup_level}}{Factor: level of the \code{by} variable
#'       (ordered by original level / sort order).}
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{term}}{Coefficient name from the fitted model.}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Fully adjusted}.}
#'     \item{\code{n}}{Participants in model (after NA removal).}
#'     \item{...}{Effect estimate columns: \code{HR}/\code{OR}/\code{beta},
#'       \code{CI_lower}, \code{CI_upper}, \code{p_value}, and a formatted
#'       label column. Cox models additionally include \code{n_events} and
#'       \code{person_years}; logistic models include \code{n_cases}; linear
#'       models include \code{se}.}
#'     \item{\code{p_interaction}}{LRT p-value for the exposure \eqn{\times}
#'       by interaction on the full dataset. Shared across all subgroup levels
#'       for the same exposure \eqn{\times} model. \code{NA} when the
#'       interaction model fails. Only present when
#'       \code{interaction = TRUE}.}
#'   }
#'
#' @importFrom survival coxph Surv
#' @export
#'
#' @examples
#' \dontrun{
#' # Subgroup by sex, coxph, unadjusted only
#' res <- assoc_subgroup(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = c("exposure", "bmi_category"),
#'   by           = "sex",
#'   method       = "coxph"
#' )
#'
#' # With Fully adjusted model (exclude 'sex' from covariates)
#' res <- assoc_subgroup(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = "exposure",
#'   by           = "sex",
#'   method       = "coxph",
#'   covariates   = c("age_at_recruitment", "tdi", "smoking")
#' )
#' }
assoc_subgroup <- function(data,
                            outcome_col,
                            time_col    = NULL,
                            exposure_col,
                            by,
                            method      = c("coxph", "logistic", "linear"),
                            covariates  = NULL,
                            interaction = TRUE,
                            conf_level  = 0.95) {

  method <- match.arg(method)

  # ---------------------------------------------------------------------------
  # 0. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }
  if (!is.character(by) || length(by) != 1L) {
    cli::cli_abort("{.arg by} must be a single character string.")
  }
  if (method == "coxph" && is.null(time_col)) {
    cli::cli_abort("{.arg time_col} is required when {.arg method = 'coxph'}.")
  }
  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }

  missing_cols <- setdiff(
    c(outcome_col, time_col, exposure_col, by, covariates),
    names(data)
  )
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Column{?s} not found in {.arg data}: {.field {missing_cols}}"
    )
  }

  # Warn if by is also listed as a covariate (collinearity within subgroups)
  if (!is.null(covariates) && by %in% covariates) {
    cli::cli_alert_warning(
      "{.arg by} variable {.field {by}} is also in {.arg covariates} \\
       \u2014 collinearity risk within each subgroup."
    )
  }

  # ---------------------------------------------------------------------------
  # 1. Prepare working copy: normalise outcome + logical exposures
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))

  if (method %in% c("coxph", "logistic")) {
    dt[, .ukb_event := .normalise_event(dt[[outcome_col]], outcome_col)]
  }
  .normalise_logical_exposures(dt, exposure_col)

  # ---------------------------------------------------------------------------
  # 2. Build model list (no age/sex auto-detection at subgroup level)
  # ---------------------------------------------------------------------------
  model_list <- list()
  model_list["Unadjusted"] <- list(NULL)
  if (!is.null(covariates) && length(covariates) > 0L) {
    model_list[["Fully adjusted"]] <- covariates
  }

  # ---------------------------------------------------------------------------
  # 3. Subgroup levels (preserve factor order; sort otherwise)
  # ---------------------------------------------------------------------------
  by_vec    <- dt[[by]]
  levels_by <- if (is.factor(by_vec)) {
    levels(by_vec)
  } else {
    sort(unique(stats::na.omit(as.character(by_vec))))
  }

  n_levels    <- length(levels_by)
  n_models    <- length(model_list)
  n_exposures <- length(exposure_col)

  cli::cli_h1("assoc_subgroup")
  cli::cli_alert_info(
    "{n_exposures} exposure{?s} \u00d7 {n_models} model{?s} \u00d7 \\
     {n_levels} subgroup{?s} ({.field {by}})"
  )

  # ---------------------------------------------------------------------------
  # 4. Interaction LRT on full data (one p-value per exposure \u00d7 model)
  # ---------------------------------------------------------------------------
  interaction_dt <- NULL
  if (interaction) {
    cli::cli_alert_info(
      "Computing interaction LRT (exposure \u00d7 {.field {by}}) on full data ..."
    )
    inter_rows <- vector("list", n_exposures * n_models)
    k <- 1L

    for (exp in exposure_col) {
      for (model_label in names(model_list)) {
        covs  <- model_list[[model_label]]
        p_int <- .run_one_interaction_lrt(
          dt          = dt,
          method      = method,
          outcome_col = outcome_col,
          time_col    = time_col,
          exposure    = exp,
          by          = by,
          covariates  = covs,
          model_label = model_label
        )
        p_fmt <- if (is.na(p_int)) "NA" else format.pval(p_int, digits = 3L)
        cli::cli_alert_info(
          "  {model_label} | {.field {exp}}: p_interaction = {p_fmt}"
        )
        inter_rows[[k]] <- data.table::data.table(
          exposure      = exp,
          model         = model_label,
          p_interaction = p_int
        )
        k <- k + 1L
      }
    }
    interaction_dt <- data.table::rbindlist(inter_rows)
  }

  # ---------------------------------------------------------------------------
  # 5. Subgroup loop: filter \u2192 run models \u2192 collect results
  # ---------------------------------------------------------------------------
  all_results <- vector("list", n_levels * n_exposures * n_models)
  idx <- 1L

  for (lv in levels_by) {

    sub_dt <- dt[as.character(dt[[by]]) == lv]
    cli::cli_h2("{.field {by}} = {lv}  (n = {nrow(sub_dt)})")

    # Warn if events are sparse for this subgroup
    if (method %in% c("coxph", "logistic")) {
      n_ev <- sum(sub_dt$.ukb_event, na.rm = TRUE)
      if (n_ev < 10L) {
        cli::cli_alert_warning(
          "  {.field {by}} = {lv}: only {n_ev} event{?s} \\
           \u2014 results may be unstable."
        )
      }
    }

    for (exp in exposure_col) {

      cli::cli_h3("{.field {exp}}")

      for (model_label in names(model_list)) {

        covs      <- model_list[[model_label]]
        warn_label <- sprintf("[%s=%s] %s", by, lv, model_label)

        res <- switch(method,
          coxph = .run_one_cox_model(
            dt          = sub_dt,
            time_col    = time_col,
            exposure    = exp,
            covariates  = covs,
            strata      = NULL,
            model_label = warn_label,
            conf_level  = conf_level
          ),
          logistic = .run_one_logistic_model(
            dt          = sub_dt,
            exposure    = exp,
            covariates  = covs,
            model_label = warn_label,
            ci_method   = "wald",
            conf_level  = conf_level
          ),
          linear = .run_one_linear_model(
            dt          = sub_dt,
            outcome_col = outcome_col,
            exposure    = exp,
            covariates  = covs,
            model_label = warn_label,
            conf_level  = conf_level
          )
        )

        if (!is.null(res)) {
          # Overwrite model column with clean label (helpers store warn_label)
          res[, model := model_label]
          res[, `:=`(subgroup = by, subgroup_level = lv)]

          # Print per-term results
          for (i in seq_len(nrow(res))) {
            est_label <- switch(method,
              coxph    = sprintf("HR %s",       res$HR_label[i]),
              logistic = sprintf("OR %s",       res$OR_label[i]),
              linear   = sprintf("\u03b2 %s",   res$beta_label[i])
            )
            cli::cli_alert_success(
              "  {model_label} | {res$term[i]}: \\
               {est_label}, p = {format.pval(res$p_value[i], digits = 3L)}"
            )
          }
          all_results[[idx]] <- res
        }
        idx <- idx + 1L
      }
    }
  }

  # ---------------------------------------------------------------------------
  # 6. Combine and finalise
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), all_results))

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned \u2014 check model warnings above.")
    return(out)
  }

  # Merge p_interaction via update-by-reference join (model still character)
  if (!is.null(interaction_dt)) {
    out[interaction_dt, on = c("exposure", "model"),
        p_interaction := i.p_interaction]
  }

  # Ordered factor for model
  model_levels   <- c("Unadjusted", "Fully adjusted")
  present_levels <- intersect(model_levels, as.character(unique(out$model)))
  out[, model := factor(model, levels = present_levels, ordered = TRUE)]

  # Factor for subgroup_level (preserve original level order)
  out[, subgroup_level := factor(subgroup_level, levels = levels_by)]

  # Put subgroup identifiers first
  front_cols <- c("subgroup", "subgroup_level", "exposure", "term", "model")
  other_cols <- setdiff(names(out), front_cols)
  data.table::setcolorder(out, c(front_cols, other_cols))

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {data.table::uniqueN(out$exposure)} exposure{?s}, \\
     {data.table::uniqueN(out$model)} model{?s}, \\
     {data.table::uniqueN(out$subgroup_level)} subgroup{?s}."
  )

  out[]
}


#' @rdname assoc_subgroup
#' @export
assoc_sub <- assoc_subgroup


#' Dose-response trend analysis
#'
#' Fits categorical and trend models simultaneously for each ordered-factor
#' exposure, returning per-category effect estimates alongside a p-value for
#' linear trend. Two models are run internally per exposure \eqn{\times}
#' adjustment combination:
#'
#' \enumerate{
#'   \item \strong{Categorical model} — exposure treated as a factor; produces
#'     one row per non-reference level (HR / OR / \eqn{\beta} vs reference).
#'   \item \strong{Trend model} — exposure recoded as numeric scores (default:
#'     0, 1, 2, \ldots); produces the per-score-unit effect estimate
#'     (\code{*_per_score}) and \code{p_trend}.
#' }
#'
#' Both results are merged: the output contains a reference row (effect = 1 /
#' 0, CI = NA) followed by non-reference rows, with \code{*_per_score} and
#' \code{p_trend} appended as shared columns (same value within each
#' exposure \eqn{\times} model combination).
#'
#' \strong{Scores}: By default levels are scored 0, 1, 2, \ldots so the
#' reference group = 0 and each step = 1 unit. Supply \code{scores} to use
#' meaningful units (e.g. median years per category) — only \code{p_trend} and
#' the per-score estimate change; per-category HRs are unaffected.
#'
#' \strong{Adjustment models}: follows the same logic as
#' \code{\link{assoc_coxph}} — Unadjusted and Age-and-sex-adjusted models are
#' included by default (\code{base = TRUE}); a Fully adjusted model is added
#' when \code{covariates} is non-NULL.
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Outcome column name.
#' @param time_col (character or NULL) Follow-up time column (required when
#'   \code{method = "coxph"}).
#' @param exposure_col (character) One or more exposure column names. Each
#'   must be a \code{factor} (ordered or unordered). The first level is used
#'   as the reference group.
#' @param method (character) Regression method: \code{"coxph"} (default),
#'   \code{"logistic"}, or \code{"linear"}.
#' @param covariates (character or NULL) Covariates for the Fully adjusted
#'   model. Default: \code{NULL}.
#' @param base (logical) Include Unadjusted and Age-and-sex-adjusted models.
#'   Default: \code{TRUE}.
#' @param scores (numeric or NULL) Numeric scores assigned to factor levels in
#'   level order. Length must equal \code{nlevels} of every exposure.
#'   \code{NULL} (default) uses \code{0, 1, 2, \ldots}
#' @param conf_level (numeric) Confidence level. Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per exposure \eqn{\times} level
#'   \eqn{\times} model, containing:
#'   \describe{
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{level}}{Factor level (ordered factor preserving original
#'       level order).}
#'     \item{\code{term}}{Coefficient name as returned by the model (reference
#'       row uses \code{paste0(exposure, ref_level)}).}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Age and sex adjusted} < \code{Fully adjusted}.}
#'     \item{\code{n}}{Participants in model (after NA removal).}
#'     \item{...}{Effect estimate columns from the categorical model:
#'       \code{HR}/\code{OR}/\code{beta}, \code{CI_lower}, \code{CI_upper},
#'       \code{p_value}, and a formatted label. Reference row has
#'       \code{HR = 1} / \code{beta = 0} and \code{NA} for CI and p.
#'       Cox models additionally include \code{n_events} and
#'       \code{person_years}; logistic includes \code{n_cases}; linear
#'       includes \code{se}.}
#'     \item{\code{HR_per_score} / \code{OR_per_score} /
#'       \code{beta_per_score}}{Per-score-unit effect estimate from the trend
#'       model. Shared across all levels within the same exposure \eqn{\times}
#'       model.}
#'     \item{\code{HR_per_score_label} / \code{OR_per_score_label} /
#'       \code{beta_per_score_label}}{Formatted string for the per-score
#'       estimate.}
#'     \item{\code{p_trend}}{P-value for linear trend from the trend model.
#'       Shared across all levels within the same exposure \eqn{\times}
#'       model.}
#'   }
#'
#' @importFrom survival coxph Surv
#' @export
#'
#' @examples
#' \dontrun{
#' # Create an ordered factor exposure with 3 levels
#' cohort[, exposure_cat := factor(exposure_source,
#'                                  levels = c(0, 1, 2),
#'                                  labels = c("None", "Mild", "Severe"))]
#'
#' # Trend analysis: default scores 0, 1, 2
#' res <- assoc_trend(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = "exposure_cat",
#'   method       = "coxph",
#'   covariates   = c("age_at_recruitment", "sex", "tdi", "smoking")
#' )
#'
#' # Custom scores (e.g. median value per category)
#' res <- assoc_trend(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = "exposure_cat",
#'   method       = "coxph",
#'   covariates   = c("age_at_recruitment", "sex", "tdi"),
#'   scores       = c(0, 5, 14)
#' )
#' }
assoc_trend <- function(data,
                         outcome_col,
                         time_col    = NULL,
                         exposure_col,
                         method      = c("coxph", "logistic", "linear"),
                         covariates  = NULL,
                         base        = TRUE,
                         scores      = NULL,
                         conf_level  = 0.95) {

  method <- match.arg(method)

  # ---------------------------------------------------------------------------
  # 0. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }
  if (method == "coxph" && is.null(time_col)) {
    cli::cli_abort("{.arg time_col} is required when {.arg method = 'coxph'}.")
  }
  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }
  if (!base && is.null(covariates)) {
    cli::cli_abort("When {.arg base = FALSE}, {.arg covariates} must be supplied.")
  }

  missing_cols <- setdiff(
    c(outcome_col, time_col, exposure_col, covariates),
    names(data)
  )
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Column{?s} not found in {.arg data}: {.field {missing_cols}}"
    )
  }

  # All exposures must be factors
  non_factor <- exposure_col[!vapply(exposure_col,
                                      function(e) is.factor(data[[e]]),
                                      logical(1L))]
  if (length(non_factor) > 0L) {
    cli::cli_abort(
      "exposure_col must be a factor. Non-factor column{?s}: {.field {non_factor}}. \\
       Use {.fn factor} or {.fn derive_cut} first."
    )
  }

  # Warn if any exposure is unordered
  unordered <- exposure_col[!vapply(exposure_col,
                                     function(e) is.ordered(data[[e]]),
                                     logical(1L))]
  if (length(unordered) > 0L) {
    cli::cli_alert_warning(
      "Exposure{?s} {.field {unordered}} {?is/are} not an ordered factor \\
       \u2014 levels will be scored 0, 1, 2, \u2026 (equal spacing assumed)."
    )
  }

  # Validate custom scores
  if (!is.null(scores)) {
    nlv_all <- vapply(exposure_col,
                      function(e) nlevels(data[[e]]), integer(1L))
    bad <- exposure_col[nlv_all != length(scores)]
    if (length(bad) > 0L) {
      cli::cli_abort(
        "{.arg scores} has length {length(scores)} but \\
         exposure{?s} {.field {bad}} ha{?s/ve} {nlv_all[exposure_col %in% bad]} \\
         level{?s}. Length must equal nlevels."
      )
    }
  }

  # ---------------------------------------------------------------------------
  # 1. Prepare working copy
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))

  if (method %in% c("coxph", "logistic")) {
    dt[, .ukb_event := .normalise_event(dt[[outcome_col]], outcome_col)]
  }

  # Convert ordered factors to unordered (preserve level order) so that the
  # categorical model uses treatment contrasts and produces term names like
  # "exposureMild" rather than polynomial contrasts ("exposure.L", ".Q").
  # The trend model uses a separate numeric column, so this does not affect
  # p_trend or HR_per_score.
  for (exp in exposure_col) {
    if (is.ordered(dt[[exp]])) {
      lv_tmp <- levels(dt[[exp]])
      dt[, (exp) := factor(get(exp), levels = lv_tmp, ordered = FALSE)]
    }
  }

  # ---------------------------------------------------------------------------
  # 2. Build model list (same logic as assoc_coxph)
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
  # 3. Run analyses: each exposure x each model
  # ---------------------------------------------------------------------------
  n_models    <- length(model_list)
  n_exposures <- length(exposure_col)

  cli::cli_h1("assoc_trend")
  cli::cli_alert_info(
    "{n_exposures} exposure{?s} \u00d7 {n_models} model{?s} \\
     (categorical + trend model per combination)"
  )

  all_results <- vector("list", n_exposures * n_models)
  idx <- 1L

  for (exp in exposure_col) {

    cli::cli_h2("{.field {exp}}")

    lv   <- levels(dt[[exp]])
    n_lv <- length(lv)

    # Determine scores for this exposure
    exp_scores <- if (!is.null(scores)) scores else seq(0L, n_lv - 1L)

    cli::cli_alert_info(
      "Levels: {paste(lv, collapse = ' \u2192 ')} \\
       | Scores: {paste(exp_scores, collapse = ', ')}"
    )

    # Add numeric trend score column: map factor integer index (1-based) → score
    # Reason: as.integer(factor) gives 1-based index; exp_scores is 1-indexed in R
    dt[, .ukb_trend_score := exp_scores[as.integer(get(exp))]]

    for (model_label in names(model_list)) {

      covs <- model_list[[model_label]]

      # ---- Categorical model (factor exposure → per-category estimates) ----
      res_cat <- switch(method,
        coxph = .run_one_cox_model(
          dt, time_col, exp, covs, NULL, model_label, conf_level
        ),
        logistic = .run_one_logistic_model(
          dt, exp, covs, model_label, "wald", conf_level
        ),
        linear = .run_one_linear_model(
          dt, outcome_col, exp, covs, model_label, conf_level
        )
      )

      # ---- Trend model (numeric score → per-unit estimate + p_trend) ----
      res_trend <- switch(method,
        coxph = .run_one_cox_model(
          dt, time_col, ".ukb_trend_score", covs, NULL,
          paste0(model_label, " [trend]"), conf_level
        ),
        logistic = .run_one_logistic_model(
          dt, ".ukb_trend_score", covs,
          paste0(model_label, " [trend]"), "wald", conf_level
        ),
        linear = .run_one_linear_model(
          dt, outcome_col, ".ukb_trend_score", covs,
          paste0(model_label, " [trend]"), conf_level
        )
      )

      if (is.null(res_cat) || is.null(res_trend)) {
        idx <- idx + 1L
        next
      }

      # ---- Build reference row + extract trend statistics ----
      p_trend <- res_trend$p_value[1L]

      if (method == "coxph") {

        est_per   <- res_trend$HR[1L]
        per_label <- sprintf("%.2f (%.2f\u2013%.2f)",
                             est_per, res_trend$CI_lower[1L], res_trend$CI_upper[1L])

        ref_row <- data.table::data.table(
          exposure     = exp,
          term         = paste0(exp, lv[1L]),
          model        = model_label,
          n            = res_cat$n[1L],
          n_events     = res_cat$n_events[1L],
          person_years = res_cat$person_years[1L],
          HR           = 1.00,
          CI_lower     = NA_real_,
          CI_upper     = NA_real_,
          p_value      = NA_real_,
          HR_label     = "1.00 (ref)"
        )
        res_cat[, `:=`(HR_per_score       = est_per,
                        HR_per_score_label = per_label,
                        p_trend            = p_trend)]
        ref_row[, `:=`(HR_per_score       = est_per,
                        HR_per_score_label = per_label,
                        p_trend            = p_trend)]

        per_str <- sprintf("HR_per_score = %s", per_label)

      } else if (method == "logistic") {

        est_per   <- res_trend$OR[1L]
        per_label <- sprintf("%.2f (%.2f\u2013%.2f)",
                             est_per, res_trend$CI_lower[1L], res_trend$CI_upper[1L])

        ref_row <- data.table::data.table(
          exposure = exp,
          term     = paste0(exp, lv[1L]),
          model    = model_label,
          n        = res_cat$n[1L],
          n_cases  = res_cat$n_cases[1L],
          OR       = 1.00,
          CI_lower = NA_real_,
          CI_upper = NA_real_,
          p_value  = NA_real_,
          OR_label = "1.00 (ref)"
        )
        res_cat[, `:=`(OR_per_score       = est_per,
                        OR_per_score_label = per_label,
                        p_trend            = p_trend)]
        ref_row[, `:=`(OR_per_score       = est_per,
                        OR_per_score_label = per_label,
                        p_trend            = p_trend)]

        per_str <- sprintf("OR_per_score = %s", per_label)

      } else {  # linear

        est_per   <- res_trend$beta[1L]
        per_label <- sprintf("%.2f (%.2f\u2013%.2f)",
                             est_per, res_trend$CI_lower[1L], res_trend$CI_upper[1L])

        ref_row <- data.table::data.table(
          exposure   = exp,
          term       = paste0(exp, lv[1L]),
          model      = model_label,
          n          = res_cat$n[1L],
          beta       = 0.00,
          se         = NA_real_,
          CI_lower   = NA_real_,
          CI_upper   = NA_real_,
          p_value    = NA_real_,
          beta_label = "0.00 (ref)"
        )
        res_cat[, `:=`(beta_per_score       = est_per,
                        beta_per_score_label = per_label,
                        p_trend              = p_trend)]
        ref_row[, `:=`(beta_per_score       = est_per,
                        beta_per_score_label = per_label,
                        p_trend              = p_trend)]

        per_str <- sprintf("\u03b2_per_score = %s", per_label)
      }

      # ---- Combine reference row + non-reference rows ----
      combined <- data.table::rbindlist(list(ref_row, res_cat), fill = TRUE)

      # Add level column: strip the exposure prefix from term to get level name
      # Reason: coxph term names are paste0(exposure, level); reference row
      # follows the same convention, so stripping the prefix recovers the level.
      term_to_lv <- stats::setNames(lv, paste0(exp, lv))
      combined[, level := factor(term_to_lv[term], levels = lv)]

      # Print per-term progress
      cli::cli_alert_info("  {model_label} | {combined$term[1L]}: 1.00 (ref)")
      for (i in seq(2L, nrow(combined))) {
        est_str <- switch(method,
          coxph    = sprintf("HR %s",     combined$HR_label[i]),
          logistic = sprintf("OR %s",     combined$OR_label[i]),
          linear   = sprintf("\u03b2 %s", combined$beta_label[i])
        )
        cli::cli_alert_success(
          "  {model_label} | {combined$term[i]}: \\
           {est_str}, p = {format.pval(combined$p_value[i], digits = 3L)}"
        )
      }
      cli::cli_alert_info(
        "  {model_label} | trend: {per_str}, \\
         p_trend = {format.pval(p_trend, digits = 3L)}"
      )

      all_results[[idx]] <- combined
      idx <- idx + 1L
    }

    # Remove temporary score column before next exposure
    dt[, .ukb_trend_score := NULL]
  }

  # ---------------------------------------------------------------------------
  # 4. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), all_results), fill = TRUE)

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned \u2014 check model warnings above.")
    return(out)
  }

  # Ordered factor for model
  model_levels   <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  present_levels <- intersect(model_levels, as.character(unique(out$model)))
  out[, model := factor(model, levels = present_levels, ordered = TRUE)]

  # Column ordering: identifiers first, p_trend last
  front_cols <- c("exposure", "level", "term", "model")
  end_cols   <- intersect("p_trend", names(out))
  mid_cols   <- setdiff(names(out), c(front_cols, end_cols))
  data.table::setcolorder(out, c(front_cols, mid_cols, end_cols))

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {data.table::uniqueN(out$exposure)} exposure{?s} and \\
     {data.table::uniqueN(out$model)} model{?s}."
  )

  out[]
}


#' @rdname assoc_trend
#' @export
assoc_tr <- assoc_trend


# =============================================================================
# assoc_competing / assoc_fg — Fine-Gray competing risks analysis
# =============================================================================


#' Fine-Gray competing risks association analysis
#'
#' Fits a Fine-Gray subdistribution hazard model (via
#' \code{survival::finegray()} + weighted \code{coxph()}) for each exposure
#' variable and returns a tidy result table with subdistribution hazard ratios
#' (SHR).
#'
#' Two input modes are supported depending on how the outcome is coded in your
#' dataset:
#'
#' \describe{
#'   \item{\strong{Mode A — single multi-value column}}{
#'     \code{compete_col = NULL} (default). \code{outcome_col} contains all
#'     event codes in one column (e.g. \code{0}/\code{1}/\code{2}/\code{3}).
#'     Use \code{event_val} and \code{compete_val} to identify the event of
#'     interest and the competing event; all other values are treated as
#'     censored. Example: UKB \code{censoring_type} where 1 = event, 2 = death
#'     (competing), 0/3 = censored.
#'   }
#'   \item{\strong{Mode B — dual binary columns}}{
#'     \code{compete_col} is the name of a separate 0/1 column for the
#'     competing event. \code{outcome_col} is a 0/1 column for the primary
#'     event. When both are 1 for the same participant, the primary event takes
#'     priority. Example: \code{outcome_col = "cscc_status"},
#'     \code{compete_col = "death_status"}.
#'   }
#' }
#'
#' Internally both modes are converted to a three-level factor
#' \code{c("censor", "event", "compete")} before being passed to
#' \code{finegray()}.
#'
#' Three adjustment models are produced (where data allow):
#' \itemize{
#'   \item \strong{Unadjusted} — always included.
#'   \item \strong{Age and sex adjusted} — when \code{base = TRUE} and
#'     age/sex columns are detected.
#'   \item \strong{Fully adjusted} — when \code{covariates} is non-NULL.
#' }
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Primary event column. In Mode A: a
#'   multi-value column (any integer or character codes). In Mode B: a 0/1
#'   binary column.
#' @param time_col (character) Follow-up time column (numeric, e.g. years).
#' @param exposure_col (character) One or more exposure variable names.
#' @param compete_col (character or NULL) Mode B only: name of the 0/1
#'   competing event column. When \code{NULL} (default), Mode A is used.
#' @param event_val Scalar value in \code{outcome_col} indicating the primary
#'   event (Mode A only). Default: \code{1L}.
#' @param compete_val Scalar value in \code{outcome_col} indicating the
#'   competing event (Mode A only). Default: \code{2L}.
#' @param covariates (character or NULL) Covariate names for the Fully
#'   adjusted model. When \code{NULL}, only Unadjusted (and Age/sex adjusted
#'   if \code{base = TRUE}) are run.
#' @param base (logical) Whether to auto-detect age and sex columns and include
#'   an Age and sex adjusted model. Default: \code{TRUE}.
#' @param conf_level (numeric) Confidence level for SHR intervals.
#'   Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per exposure \eqn{\times} term
#'   \eqn{\times} model combination:
#'   \describe{
#'     \item{\code{exposure}}{Exposure variable name.}
#'     \item{\code{term}}{Coefficient name as returned by \code{coxph}.}
#'     \item{\code{model}}{Ordered factor: \code{Unadjusted} <
#'       \code{Age and sex adjusted} < \code{Fully adjusted}.}
#'     \item{\code{n}}{Participants in the model (after NA removal).}
#'     \item{\code{n_events}}{Primary events in the analysis set.}
#'     \item{\code{n_compete}}{Competing events in the analysis set.}
#'     \item{\code{SHR}}{Subdistribution hazard ratio.}
#'     \item{\code{CI_lower}}{Lower CI bound.}
#'     \item{\code{CI_upper}}{Upper CI bound.}
#'     \item{\code{p_value}}{Robust z-test p-value from weighted Cox.}
#'     \item{\code{SHR_label}}{Formatted string, e.g. \code{"1.23 (1.05--1.44)"}.}
#'   }
#'
#' @importFrom survival finegray coxph Surv
#' @export
#'
#' @examples
#' \dontrun{
#' # Mode A: single multi-value column (0 = censored, 1 = event, 2 = competing)
#' assoc_competing(
#'   data         = cohort,
#'   outcome_col  = "censoring_type",
#'   time_col     = "followup_years",
#'   exposure_col = "exposure",
#'   event_val    = 1L,
#'   compete_val  = 2L,
#'   covariates   = c("tdi", "smoking")
#' )
#'
#' # Mode B: separate 0/1 columns for primary and competing events
#' assoc_competing(
#'   data         = cohort,
#'   outcome_col  = "outcome_status",
#'   time_col     = "followup_years",
#'   exposure_col = c("exposure", "bmi_category"),
#'   compete_col  = "death_status",
#'   covariates   = c("tdi", "smoking")
#' )
#' }
assoc_competing <- function(data,
                             outcome_col,
                             time_col,
                             exposure_col,
                             compete_col = NULL,
                             event_val   = 1L,
                             compete_val = 2L,
                             covariates  = NULL,
                             base        = TRUE,
                             conf_level  = 0.95) {

  # ---------------------------------------------------------------------------
  # 1. Input validation
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }

  dt <- data.table::as.data.table(data)

  req_cols <- c(outcome_col, time_col, exposure_col, compete_col, covariates)
  missing_cols <- setdiff(req_cols, names(dt))
  if (length(missing_cols) > 0L) {
    cli::cli_abort("Column{?s} not found in data: {.field {missing_cols}}")
  }

  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }

  # Normalise logical exposures → integer (avoids "ad_tfTRUE" term names)
  dt <- data.table::copy(dt)
  .normalise_logical_exposures(dt, exposure_col)

  # ---------------------------------------------------------------------------
  # 2. Build .fg_status: factor(censor / event / compete)
  # ---------------------------------------------------------------------------
  if (is.null(compete_col)) {
    # Mode A: single multi-value column
    raw <- dt[[outcome_col]]
    fg_vec <- data.table::fcase(
      raw == event_val,   "event",
      raw == compete_val, "compete",
      default = "censor"
    )
    cli::cli_alert_info(
      "Mode A: {.field {outcome_col}} \u2192 event={event_val}, \\
       compete={compete_val}, rest=censor"
    )
  } else {
    # Mode B: dual binary columns; primary event takes priority
    ev  <- suppressWarnings(as.integer(dt[[outcome_col]]))
    cmp <- suppressWarnings(as.integer(dt[[compete_col]]))
    fg_vec <- data.table::fcase(
      ev  == 1L, "event",
      cmp == 1L, "compete",
      default = "censor"
    )
    cli::cli_alert_info(
      "Mode B: {.field {outcome_col}} (event) + {.field {compete_col}} (compete)"
    )
  }

  dt[, .fg_status := factor(fg_vec, levels = c("censor", "event", "compete"))]

  n_event_total   <- sum(dt$.fg_status == "event",   na.rm = TRUE)
  n_compete_total <- sum(dt$.fg_status == "compete",  na.rm = TRUE)
  cli::cli_alert_info(
    "Events: {n_event_total}, Competing: {n_compete_total}, \\
     Censored: {sum(dt$.fg_status == 'censor', na.rm=TRUE)}"
  )

  # ---------------------------------------------------------------------------
  # 3. Build model list (Unadjusted / Age and sex adjusted / Fully adjusted)
  # ---------------------------------------------------------------------------
  base_covs <- NULL
  if (isTRUE(base)) {
    age_col <- .detect_age_col(dt)
    sex_col <- .detect_sex_col(dt)
    if (is.null(age_col)) {
      cli::cli_alert_warning(
        "Age column not detected \u2014 Age and sex adjusted model may be incomplete."
      )
    }
    if (is.null(sex_col)) {
      cli::cli_alert_warning(
        "Sex column not detected \u2014 Age and sex adjusted model may be incomplete."
      )
    }
    base_covs <- c(age_col, sex_col)
    base_covs <- base_covs[!is.null(base_covs)]
  }

  models <- list(list(label = "Unadjusted", covs = NULL))
  if (length(base_covs) > 0L) {
    models <- c(models, list(list(label = "Age and sex adjusted", covs = base_covs)))
  }
  if (!is.null(covariates)) {
    full_covs <- unique(c(base_covs, covariates))
    models    <- c(models, list(list(label = "Fully adjusted", covs = full_covs)))
  }

  # ---------------------------------------------------------------------------
  # 4. Loop over exposures × models
  # ---------------------------------------------------------------------------
  all_results <- list()

  for (exp in exposure_col) {
    cli::cli_alert_info("Exposure: {.field {exp}}")

    for (m in models) {
      cli::cli_alert_info("  Model: {m$label}")
      res <- .run_one_fg_model(
        dt          = dt,
        time_col    = time_col,
        exposure    = exp,
        covariates  = m$covs,
        model_label = m$label,
        conf_level  = conf_level
      )
      all_results <- c(all_results, list(res))
    }
  }

  # ---------------------------------------------------------------------------
  # 5. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), all_results), fill = TRUE)

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned \u2014 check model warnings above.")
    return(out)
  }

  model_levels   <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  present_levels <- intersect(model_levels, as.character(unique(out$model)))
  out[, model := factor(model, levels = present_levels, ordered = TRUE)]

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {data.table::uniqueN(out$exposure)} exposure{?s} and \\
     {data.table::uniqueN(out$model)} model{?s}."
  )

  out[]
}


#' @rdname assoc_competing
#' @export
assoc_fg <- assoc_competing


# =============================================================================
# assoc_lag — Cox lag (landmark) sensitivity analysis
# =============================================================================


#' Cox regression lag sensitivity analysis
#'
#' Runs Cox proportional hazards models at one or more lag periods to assess
#' whether associations are robust to the exclusion of early events. For each
#' lag, participants whose follow-up time is less than \code{lag_years} are
#' removed from the analysis dataset; follow-up time is kept on its original
#' scale (not shifted). This mirrors the approach used in UK Biobank sensitivity
#' analyses to address reverse causation and detection bias.
#'
#' Setting \code{lag_years = 0} (or including \code{0} in the vector) runs the
#' model on the full unfiltered cohort, providing a reference against which
#' lagged results can be compared.
#'
#' The same three adjustment models produced by \code{\link{assoc_coxph}} are
#' available here (\strong{Unadjusted}, \strong{Age and sex adjusted},
#' \strong{Fully adjusted}).
#'
#' @param data (data.frame or data.table) Analysis dataset.
#' @param outcome_col (character) Event indicator column (0/1 or logical).
#' @param time_col (character) Follow-up time column (numeric, e.g. years).
#' @param exposure_col (character) One or more exposure variable names.
#' @param lag_years (numeric) One or more lag periods in the same units as
#'   \code{time_col}. Default: \code{c(1, 2)}. Use \code{0} to include the
#'   unfiltered full-cohort result as a reference.
#' @param covariates (character or NULL) Covariates for the Fully adjusted
#'   model. When \code{NULL}, only Unadjusted (and Age and sex adjusted if
#'   \code{base = TRUE}) are run.
#' @param base (logical) Auto-detect age and sex and include an Age and sex
#'   adjusted model. Default: \code{TRUE}.
#' @param strata (character or NULL) Optional stratification variable passed to
#'   \code{survival::strata()}.
#' @param conf_level (numeric) Confidence level for HR intervals.
#'   Default: \code{0.95}.
#'
#' @return A \code{data.table} with one row per lag \eqn{\times} exposure
#'   \eqn{\times} term \eqn{\times} model combination, containing all columns
#'   produced by \code{\link{assoc_coxph}} plus:
#'   \describe{
#'     \item{\code{lag_years}}{The lag period applied (numeric).}
#'     \item{\code{n_excluded}}{Number of participants excluded because their
#'       follow-up time was less than \code{lag_years}.}
#'   }
#'   \code{lag_years} and \code{n_excluded} are placed immediately after
#'   \code{model} in the column order.
#'
#' @importFrom survival coxph Surv
#' @export
#'
#' @examples
#' \dontrun{
#' assoc_lag(
#'   data         = ukb_df,
#'   outcome_col  = "cscc_status",
#'   time_col     = "followup_years",
#'   exposure_col = "ad_tf",
#'   lag_years    = c(0, 1, 2),
#'   covariates   = c("tdi", "smoking")
#' )
#' }
assoc_lag <- function(data,
                       outcome_col,
                       time_col,
                       exposure_col,
                       lag_years  = c(1, 2),
                       covariates = NULL,
                       base       = TRUE,
                       strata     = NULL,
                       conf_level = 0.95) {

  # ---------------------------------------------------------------------------
  # 1. Input validation
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

  if (!is.numeric(lag_years) || any(lag_years < 0)) {
    cli::cli_abort("{.arg lag_years} must be a non-negative numeric vector.")
  }

  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a number between 0 and 1.")
  }

  lag_years <- sort(unique(lag_years))

  # ---------------------------------------------------------------------------
  # 2. Prepare full working copy
  # ---------------------------------------------------------------------------
  dt <- data.table::copy(data.table::as.data.table(data))
  dt[, .ukb_event := .normalise_event(dt[[outcome_col]], outcome_col)]
  .normalise_logical_exposures(dt, exposure_col)

  n_full <- nrow(dt)

  # ---------------------------------------------------------------------------
  # 3. Build model list (same logic as assoc_coxph)
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
          if (is.null(age_col)) "age column not found" else "",
          if (is.null(age_col) && is.null(sex_col)) " and " else "",
          if (is.null(sex_col)) "sex column not found" else "",
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
  # 4. Loop: lag × exposure × model
  # ---------------------------------------------------------------------------
  cli::cli_h1("assoc_lag")
  cli::cli_alert_info(
    "{length(lag_years)} lag period{?s} \u00d7 {length(exposure_col)} \\
     exposure{?s} \u00d7 {length(model_list)} model{?s}"
  )

  all_results <- list()

  for (lag in lag_years) {

    cli::cli_h2("Lag: {lag} year{?s}")

    # Filter: exclude participants with follow-up < lag
    sub <- if (lag == 0) {
      dt
    } else {
      dt[dt[[time_col]] >= lag, ]
    }

    n_excluded <- n_full - nrow(sub)
    n_events   <- sum(sub$.ukb_event, na.rm = TRUE)

    cli::cli_alert_info(
      "Excluded (time < {lag} yr): {n_excluded} \u2014 \\
       remaining: {nrow(sub)}, events: {n_events}"
    )

    for (exp in exposure_col) {
      cli::cli_h2("{.field {exp}}")

      for (model_label in names(model_list)) {

        res <- .run_one_cox_model(
          dt          = sub,
          time_col    = time_col,
          exposure    = exp,
          covariates  = model_list[[model_label]],
          strata      = strata,
          model_label = model_label,
          conf_level  = conf_level
        )

        if (!is.null(res)) {
          res[, `:=`(lag_years = lag, n_excluded = n_excluded)]
        }

        all_results <- c(all_results, list(res))
      }
    }
  }

  # ---------------------------------------------------------------------------
  # 5. Combine and return
  # ---------------------------------------------------------------------------
  out <- data.table::rbindlist(Filter(Negate(is.null), all_results), fill = TRUE)

  if (nrow(out) == 0L) {
    cli::cli_alert_warning("No results returned \u2014 check model warnings above.")
    return(out)
  }

  # Ordered factor for model
  model_levels   <- c("Unadjusted", "Age and sex adjusted", "Fully adjusted")
  present_levels <- intersect(model_levels, as.character(unique(out$model)))
  out[, model := factor(model, levels = present_levels, ordered = TRUE)]

  # Column order: identifiers first, lag_years + n_excluded after model
  front_cols <- c("exposure", "term", "model", "lag_years", "n_excluded")
  mid_cols   <- setdiff(names(out), front_cols)
  data.table::setcolorder(out, c(front_cols, mid_cols))

  cli::cli_alert_success(
    "Done: {nrow(out)} result row{?s} across \\
     {data.table::uniqueN(out$lag_years)} lag period{?s}, \\
     {data.table::uniqueN(out$exposure)} exposure{?s}, and \\
     {data.table::uniqueN(out$model)} model{?s}."
  )

  out[]
}
