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


#' Assert that an argument is a valid vector of integer-like field IDs
#'
#' Rejects non-numeric input, empty vectors, and values that are NA, Inf, or
#' NaN. Returns deduplicated integer values ready for use.
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
