# =============================================================================
# helper-integration.R — Shared helpers for integration tests
# Loaded automatically by testthat before running tests
# =============================================================================


#' Skip integration test if prerequisites are not met
#'
#' Skips on CI, CRAN, and when DX_API_TOKEN is not set.
#' Returns the token invisibly so tests can reuse it without a second Sys.getenv().
#'
#' @keywords internal
.skip_if_no_dx_token <- function() {
  testthat::skip_on_ci()
  testthat::skip_on_cran()

  token <- Sys.getenv("DX_API_TOKEN")
  if (!nzchar(token)) {
    testthat::skip("DX_API_TOKEN not set. Set it to run integration tests.")
  }

  invisible(token)
}


#' Skip integration test if not running on RAP with a valid token
#'
#' Extends \code{.skip_if_no_dx_token()} with an additional RAP environment
#' check. Use for tests that require \code{fetch_file()} or other RAP-only
#' operations.
#'
#' @keywords internal
.skip_if_no_rap <- function() {
  .skip_if_no_dx_token()
  if (!ukbflow:::.is_on_rap()) {
    testthat::skip("Not running on RAP — requires the RAP environment.")
  }
}
