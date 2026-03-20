# =============================================================================
# utils.R — Package-wide internal helpers
# =============================================================================


#' Assert that an argument is a single non-empty string
#'
#' @keywords internal
#' @noRd
.assert_scalar_string <- function(x, arg = deparse(substitute(x))) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop("`", arg, "` must be a single non-empty string.", call. = FALSE)
  }
  invisible(x)
}
