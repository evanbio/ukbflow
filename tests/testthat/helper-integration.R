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
