# =============================================================================
# derive.R — analysis-ready variable preparation for UKB data
# =============================================================================


#' Handle informative missing labels in UKB decoded data
#'
#' After \code{\link{decode_values}} converts categorical codes to character
#' labels, some values represent meaningful non-response rather than true data:
#' \code{"Do not know"}, \code{"Prefer not to answer"}, and
#' \code{"Prefer not to say"}. This function either converts them to \code{NA}
#' (for complete-case analysis) or retains them as \code{"Unknown"} (to
#' preserve the informative missingness as a model category).
#'
#' Empty strings (\code{""}) are always converted to \code{NA} regardless of
#' \code{action}, as they carry no informational content.
#'
#' Only character columns are modified; numeric, integer, Date, and logical
#' columns are silently skipped.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, modifications are made in-place via
#' \code{\link[data.table]{set}}. The returned object and the original variable
#' point to the same memory. If you need to preserve the original, pass
#' \code{data.table::copy(data)} instead.
#'
#' @param data (data.frame or data.table) Decoded UKB data, typically output
#'   of \code{\link{decode_values}} followed by \code{\link{decode_names}}.
#' @param cols <\code{\link[tidyselect]{tidyselect}}> Columns to process.
#'   Default: \code{everything()} (all columns). Non-character columns in the
#'   selection are silently skipped.
#' @param action (character) One of \code{"na"} (default) or \code{"unknown"}.
#'   \itemize{
#'     \item \code{"na"}: convert all informative missing labels to \code{NA}.
#'     \item \code{"unknown"}: convert informative missing labels to
#'       \code{"Unknown"}, preserving them as a distinct model category.
#'   }
#'   Empty strings are always converted to \code{NA} regardless of this
#'   parameter.
#' @param extra_labels (character or NULL) Additional labels to treat as
#'   informative missing, appended to the built-in list. Default: \code{NULL}.
#'
#' @return The input \code{data} with missing labels replaced in-place.
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(31, 20116, 2080)) |>
#'   decode_values() |>
#'   decode_names() |>
#'   derive_missing()                          # "Do not know" -> NA
#'
#' # Retain informative non-response as a model category
#' df <- derive_missing(df, action = "unknown")  # "Prefer not to answer" -> "Unknown"
#'
#' # Add a custom label
#' df <- derive_missing(df, extra_labels = "Not applicable")
#' }
derive_missing <- function(data,
                           cols         = tidyselect::everything(),
                           action       = c("na", "unknown"),
                           extra_labels = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }

  action <- match.arg(action)

  if (!is.null(extra_labels)) {
    if (!is.character(extra_labels)) {
      stop("extra_labels must be a character vector or NULL.", call. = FALSE)
    }
    extra_labels <- extra_labels[nchar(trimws(extra_labels)) > 0L]
  }

  # Convert to data.table in-place (no copy for data.table input)
  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  # Resolve tidyselect column indices, then keep only character columns
  selected_idx  <- tidyselect::eval_select(rlang::enquo(cols), data)
  selected_cols <- names(selected_idx)
  char_cols     <- selected_cols[vapply(data[, selected_cols, with = FALSE],
                                        is.character, logical(1L))]

  if (length(char_cols) == 0L) {
    cli::cli_alert_info("No character columns found in selection — nothing to do.")
    return(invisible(data))
  }

  # Build label sets
  informative_labels <- c(.ukb_informative_missing, extra_labels)
  replace_value      <- if (action == "na") NA_character_ else "Unknown"

  n_cols_affected  <- 0L
  n_vals_replaced  <- 0L

  for (col in char_cols) {

    x          <- data[[col]]
    empty_idx  <- which(x == "")
    inform_idx <- which(x %in% informative_labels)

    n_replaced <- length(empty_idx) + length(inform_idx)
    if (n_replaced == 0L) next

    # "" always -> NA; informative labels -> NA or "Unknown" per action
    data.table::set(data, i = empty_idx,  j = col, value = NA_character_)
    data.table::set(data, i = inform_idx, j = col, value = replace_value)

    n_cols_affected <- n_cols_affected + 1L
    n_vals_replaced <- n_vals_replaced + n_replaced
  }

  cli::cli_alert_success(
    "derive_missing: replaced {n_vals_replaced} value{?s} across \\
     {n_cols_affected} column{?s} (action = {.val {action}})."
  )

  data
}


#' Prepare UKB covariates for analysis
#'
#' Converts decoded UKB columns to analysis-ready types: character-encoded
#' numeric fields to \code{numeric}, and categorical fields to \code{factor}.
#' Prints a concise summary for each converted column — mean / median / SD /
#' missing rate for numeric columns, and level counts for factor columns — so
#' you can verify distributions without leaving the pipeline.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, modifications are made in-place. Pass
#' \code{data.table::copy(data)} to preserve the original.
#'
#' @param data (data.frame or data.table) UKB data, typically output of
#'   \code{\link{derive_missing}}.
#' @param as_numeric (character or NULL) Column names to convert to
#'   \code{numeric}. Values that cannot be coerced (e.g. residual text) become
#'   \code{NA} with a warning. Default: \code{NULL}.
#' @param as_factor (character or NULL) Column names to convert to
#'   \code{factor}. Default levels are the sorted unique non-NA values unless
#'   overridden by \code{factor_levels}. Default: \code{NULL}.
#' @param factor_levels (named list or NULL) Custom level ordering for specific
#'   factor columns. Names must match entries in \code{as_factor}; values are
#'   character vectors of levels in the desired order (first level = reference
#'   group in regression). Columns not listed use default ordering.
#'   Default: \code{NULL}.
#' @param max_levels (integer) Factor columns with more levels than this
#'   threshold trigger a warning suggesting the user consider collapsing
#'   categories. Default: \code{5L}.
#'
#' @return The input \code{data} with converted columns. Always returns a
#'   \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(31, 20116, 738, 874)) |>
#'   decode_values() |>
#'   decode_names() |>
#'   derive_missing() |>
#'   derive_covariate(
#'     as_numeric = "duration_of_walks_i0",
#'     as_factor  = c("sex", "smoking_status_i0"),
#'     factor_levels = list(
#'       smoking_status_i0 = c("Never", "Previous", "Current")
#'     )
#'   )
#' }
derive_covariate <- function(data,
                             as_numeric    = NULL,
                             as_factor     = NULL,
                             factor_levels = NULL,
                             max_levels    = 5L) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.null(factor_levels) && !is.list(factor_levels)) {
    stop("factor_levels must be a named list or NULL.", call. = FALSE)
  }
  if (!is.null(factor_levels) && is.null(names(factor_levels))) {
    stop("factor_levels must be a named list (names = column names).", call. = FALSE)
  }

  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  n_rows <- nrow(data)

  # ── as_numeric ──────────────────────────────────────────────────────────────
  if (!is.null(as_numeric)) {

    bad        <- setdiff(as_numeric, names(data))
    as_numeric <- intersect(as_numeric, names(data))
    if (length(bad) > 0L) {
      cli::cli_alert_warning("as_numeric: columns not found, skipped: {.val {bad}}")
    }

    if (length(as_numeric) > 0L) {
      cli::cli_rule(left = "Numeric")

      for (col in as_numeric) {
        na_before <- sum(is.na(data[[col]]))
        data.table::set(data, j = col,
                        value = suppressWarnings(as.numeric(data[[col]])))
        na_new <- sum(is.na(data[[col]])) - na_before
        if (na_new > 0L) {
          cli::cli_alert_warning(
            "{.field {col}}: {na_new} value{?s} coerced to NA."
          )
        }
        .cli_summarise_numeric(data[[col]], col, n_rows)
      }
    }
  }

  # ── as_factor ───────────────────────────────────────────────────────────────
  if (!is.null(as_factor)) {

    bad       <- setdiff(as_factor, names(data))
    as_factor <- intersect(as_factor, names(data))
    if (length(bad) > 0L) {
      cli::cli_alert_warning("as_factor: columns not found, skipped: {.val {bad}}")
    }

    if (length(as_factor) > 0L) {
      cli::cli_rule(left = "Factor")

      for (col in as_factor) {
        lvls  <- factor_levels[[col]]   # NULL → default sorted levels
        f_val <- if (is.null(lvls)) factor(data[[col]]) else factor(data[[col]], levels = lvls)
        data.table::set(data, j = col, value = f_val)
        .cli_summarise_factor(data[[col]], col, n_rows, max_levels)
      }
    }
  }

  data
}


#' Cut a continuous UKB variable into quantile-based or custom groups
#'
#' Creates a new factor column by binning a continuous variable into \code{n}
#' groups. When \code{breaks} is omitted, group boundaries are derived from
#' quantiles of the observed data (equal-frequency binning). When
#' \code{breaks} is supplied, those values are used as interior cut points.
#'
#' Before binning, a numeric summary (mean, median, SD, Q1, Q3, missing rate)
#' is printed for the source column. After binning, the group distribution is
#' printed via \code{\link{.cli_summarise_factor}}.
#'
#' Only one column can be processed per call; loop over columns explicitly
#' when binning multiple variables.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, the new column is added in-place. Pass
#' \code{data.table::copy(data)} to preserve the original.
#'
#' @param data (data.frame or data.table) UKB data.
#' @param col (character) Name of the source numeric column.
#' @param n (integer) Number of groups. Supported values: \code{2}, \code{3},
#'   \code{4}, \code{5}.
#' @param breaks (numeric vector or NULL) Interior cut points; length must
#'   equal \code{n - 1}. When \code{NULL} (default), quantile-based equal-
#'   frequency boundaries are computed automatically.
#' @param labels (character vector or NULL) Group labels of length \code{n}.
#'   Defaults to \code{"Q1"}, \code{"Q2"}, \ldots, \code{"Qn"}.
#' @param name (character or NULL) Name for the new column. Defaults to
#'   \code{"{col}_bi"} / \code{"{col}_tri"} / \code{"{col}_quad"} /
#'   \code{"{col}_quin"} for \code{n} = 2 / 3 / 4 / 5.
#'
#' @return The input \code{data} with one new factor column appended. Always
#'   returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- derive_cut(df, col = "age_at_recruitment", n = 3)
#' # → adds age_at_recruitment_tri with groups Q1 / Q2 / Q3
#'
#' df <- derive_cut(df, col = "age_at_recruitment", n = 3,
#'                  breaks = c(50, 60),
#'                  labels = c("<50", "50-59", "60+"),
#'                  name   = "age_group")
#' }
derive_cut <- function(data,
                       col,
                       n,
                       breaks = NULL,
                       labels = NULL,
                       name   = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!col %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
  }
  if (!is.numeric(n) || length(n) != 1L || n < 2L) {
    stop("n must be a single integer >= 2.", call. = FALSE)
  }
  n <- as.integer(n)

  if (!is.null(breaks)) {
    if (!is.numeric(breaks) || length(breaks) != n - 1L) {
      stop(sprintf("breaks must be a numeric vector of length n - 1 (%d).", n - 1L),
           call. = FALSE)
    }
  }
  if (!is.null(labels) && length(labels) != n) {
    stop(sprintf("labels must be a character vector of length n (%d).", n), call. = FALSE)
  }

  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  n_rows <- nrow(data)
  x      <- data[[col]]

  if (!is.numeric(x)) {
    stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
  }

  # Default name based on n
  if (is.null(name)) {
    suffix_map <- c("2" = "_bi", "3" = "_tri", "4" = "_quad", "5" = "_quin")
    suffix <- suffix_map[as.character(n)]
    name   <- if (!is.na(suffix)) paste0(col, suffix) else paste0(col, "_g", n)
  }

  # Default labels: Q1, Q2, ..., Qn
  if (is.null(labels)) labels <- paste0("Q", seq_len(n))

  # ── Print source column numeric summary ────────────────────────────────────
  cli::cli_rule(left = sprintf("Source: %s", col))
  .cli_summarise_numeric(x, col, n_rows)

  # ── Compute cut points ─────────────────────────────────────────────────────
  if (is.null(breaks)) {
    # Reason: quantile-based equal-frequency binning; include.lowest ensures
    # the minimum value falls into the first group
    cut_breaks <- stats::quantile(x, probs = seq(0, 1, length.out = n + 1L),
                                  na.rm = TRUE)
    cut_breaks <- unique(cut_breaks)   # collapse duplicate boundaries from ties
    if (length(cut_breaks) < n + 1L) {
      cli::cli_alert_warning(
        "Ties at quantile boundaries reduced the number of distinct groups \\
         (requested {n}, got {length(cut_breaks) - 1L})."
      )
    }
  } else {
    cut_breaks <- c(-Inf, breaks, Inf)
  }

  f_val <- base::cut(x, breaks = cut_breaks, labels = labels,
                     include.lowest = TRUE, right = TRUE)

  # ── Add new column and print factor summary ─────────────────────────────────
  data.table::set(data, j = name, value = f_val)

  cli::cli_rule(left = sprintf("New column: %s", name))
  .cli_summarise_factor(data[[name]], name, n_rows, max_levels = n)

  data
}
