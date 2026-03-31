# =============================================================================
# utils.R — Package-wide internal helpers
# =============================================================================


# Null-coalescing operator: return lhs unless it is NULL, then return rhs.
`%||%` <- function(lhs, rhs) if (!is.null(lhs)) lhs else rhs


#' Assert that an argument is a single non-empty string
#'
#' @keywords internal
#' @noRd
.assert_scalar_string <- function(x, arg = deparse(substitute(x))) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    cli::cli_abort("`{arg}` must be a single non-empty string.", call = NULL)
  }
  invisible(x)
}


#' Assert that an argument is a valid vector of integer-valued field IDs
#'
#' Rejects non-numeric input, non-whole numbers, empty vectors, and values
#' that are NA, Inf, or NaN. Returns deduplicated integer values ready for use.
#'
#' @param x The argument to check.
#' @param arg Name of the argument (for error messages).
#' @return Integer vector of unique values.
#'
#' @keywords internal
#' @noRd
.assert_integer_ids <- function(x, arg = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) == 0L) {
    cli::cli_abort("`{arg}` must be a non-empty numeric vector.", call = NULL)
  }
  if (anyNA(x) || any(is.infinite(x)) || any(is.nan(x))) {
    cli::cli_abort(
      "`{arg}` must not contain NA, Inf, or NaN values.",
      call = NULL
    )
  }
  if (any(x != floor(x))) {
    cli::cli_abort(
      "`{arg}` must contain whole numbers only (e.g. 31, not 31.7).",
      call = NULL
    )
  }
  as.integer(unique(x))
}


#' Assert that an argument is a valid DNAnexus job ID
#'
#' @param job_id The argument to check.
#' @param arg Name of the argument (for error messages).
#' @return Invisibly returns \code{job_id}.
#'
#' @keywords internal
#' @noRd
.assert_job_id <- function(job_id, arg = deparse(substitute(job_id))) {
  .assert_scalar_string(job_id, arg)
  if (!grepl("^job-", job_id)) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.code job-XXXX} string, got {.val {job_id}}.",
      call = NULL
    )
  }
  invisible(job_id)
}


#' Assert that an argument is a single positive integer (count parameter)
#'
#' @param x The argument to check.
#' @param arg Name of the argument (for error messages).
#' @return Invisibly returns \code{as.integer(x)}.
#'
#' @keywords internal
#' @noRd
.assert_count <- function(x, arg = deparse(substitute(x))) {
  # Reason: is.finite() required because floor(Inf) == Inf, so without it
  # Inf would silently pass the floor check
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x < 1L || x != floor(x)) {
    cli::cli_abort("{.arg {arg}} must be a single positive integer.", call = NULL)
  }
  invisible(as.integer(x))
}


#' Assert that an argument is a single integer >= a specified minimum
#'
#' @param x The argument to check.
#' @param min Minimum allowed value (inclusive).
#' @param arg Name of the argument (for error messages).
#' @return Invisibly returns \code{as.integer(x)}.
#'
#' @keywords internal
#' @noRd
.assert_count_min <- function(x, min, arg = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x < min || x != floor(x)) {
    cli::cli_abort("{.arg {arg}} must be a single integer >= {min}.", call = NULL)
  }
  invisible(as.integer(x))
}


#' Assert that an argument is NULL or a character vector of allowed values
#'
#' @param x The argument to check. \code{NULL} is always allowed.
#' @param choices Character vector of valid values.
#' @param arg Name of the argument (for error messages).
#' @return Invisibly returns \code{x}.
#'
#' @keywords internal
#' @noRd
.assert_choices <- function(x, choices, arg = deparse(substitute(x))) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.character(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be NULL or a character vector.", call = NULL
    )
  }
  # Reason: character(0) is allowed — downstream %in% returns all FALSE,
  # giving an empty result, which is predictable and not harmful
  bad <- setdiff(x, choices)
  if (length(bad) > 0) {
    cli::cli_abort(
      c("Invalid {.arg {arg}} value{?s}: {.val {bad}}.",
        "i" = "Valid values: {.val {choices}}."),
      call = NULL
    )
  }
  invisible(x)
}


#' Assert that an argument is a character vector
#'
#' @keywords internal
#' @noRd
.assert_character <- function(x, arg = deparse(substitute(x))) {
  if (!is.character(x)) {
    cli::cli_abort("{.arg {arg}} must be a character vector.", call = NULL)
  }
  invisible(x)
}


#' Assert that an argument is a data.frame
#'
#' @keywords internal
#' @noRd
.assert_data_frame <- function(x, arg = deparse(substitute(x))) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg {arg}} must be a data.frame.", call = NULL)
  }
  invisible(x)
}


#' Assert that an argument is a data.table
#'
#' @keywords internal
#' @noRd
.assert_data_table <- function(x, arg = deparse(substitute(x))) {
  if (!data.table::is.data.table(x)) {
    cli::cli_abort("{.arg {arg}} must be a data.table.", call = NULL)
  }
  invisible(x)
}


#' Assert that an argument is a logical vector
#'
#' @keywords internal
#' @noRd
.assert_logical <- function(x, arg = deparse(substitute(x))) {
  if (!is.logical(x)) {
    cli::cli_abort("{.arg {arg}} must be a logical vector.", call = NULL)
  }
  invisible(x)
}


#' Assert that an argument is a single non-NA logical (flag)
#'
#' @keywords internal
#' @noRd
.assert_flag <- function(x, arg = deparse(substitute(x))) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be a single TRUE or FALSE.", call = NULL)
  }
  invisible(x)
}


#' Assert that a file path exists
#'
#' @keywords internal
#' @noRd
.assert_file_exists <- function(x, arg = deparse(substitute(x))) {
  if (!file.exists(x)) {
    cli::cli_abort("File not found: {.path {x}}", call = NULL)
  }
  invisible(x)
}


#' Assert that a value is non-NULL when a flag is FALSE
#'
#' Commonly used to enforce "when \code{base = FALSE}, \code{covariates} must
#' be supplied" contracts.
#'
#' @keywords internal
#' @noRd
.assert_not_null_if_false <- function(flag, value,
                                      flag_name  = deparse(substitute(flag)),
                                      value_name = deparse(substitute(value))) {
  if (!isTRUE(flag) && is.null(value)) {
    cli::cli_abort(
      "When {.arg {flag_name}} = FALSE, {.arg {value_name}} must be supplied.",
      call = NULL
    )
  }
  invisible(value)
}


#' Assert that a value is non-NULL when a flag is TRUE
#'
#' Commonly used to enforce "when \code{save = TRUE}, \code{dest} must
#' be supplied" contracts.
#'
#' @keywords internal
#' @noRd
.assert_not_null_if_true <- function(flag, value,
                                     flag_name  = deparse(substitute(flag)),
                                     value_name = deparse(substitute(value))) {
  if (isTRUE(flag) && is.null(value)) {
    cli::cli_abort(
      "When {.arg {flag_name}} = TRUE, {.arg {value_name}} must be supplied.",
      call = NULL
    )
  }
  invisible(value)
}


#' Assert that an argument is a numeric scalar strictly between 0 and 1
#'
#' @keywords internal
#' @noRd
.assert_proportion <- function(x, arg = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x <= 0 || x >= 1) {
    cli::cli_abort("{.arg {arg}} must be a single number strictly between 0 and 1.", call = NULL)
  }
  invisible(x)
}


#' Assert that a vector has the expected length
#'
#' @keywords internal
#' @noRd
.assert_length_n <- function(x, n, arg = deparse(substitute(x))) {
  if (length(x) != n) {
    cli::cli_abort("{.arg {arg}} must have length {n}.", call = NULL)
  }
  invisible(x)
}


#' Assert that required columns are present in a data.frame
#'
#' Reports all missing columns in a single error rather than stopping at the
#' first, so the user can fix everything in one pass.
#'
#' @keywords internal
#' @noRd
.assert_has_cols <- function(data, cols, arg = deparse(substitute(data))) {
  missing <- setdiff(cols, names(data))
  if (length(missing) > 0L) {
    cli::cli_abort(
      "{.arg {arg}} is missing column{?s}: {.val {missing}}.",
      call = NULL
    )
  }
  invisible(data)
}


#' @keywords internal
#' @noRd
.assert_on_rap <- function() {
  if (!.is_on_rap())
    cli::cli_abort("This function must be run inside the RAP environment.", call = NULL)
  invisible(TRUE)
}
