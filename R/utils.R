# =============================================================================
# utils.R — Package-wide internal helpers
# =============================================================================


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
