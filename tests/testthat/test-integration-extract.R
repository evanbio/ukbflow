# =============================================================================
# test-integration-extract.R — Integration tests for extract_ series
# Requires real dx-toolkit, token, and network connection
# Run manually before release: devtools::test(filter = "integration-extract")
# =============================================================================

skip_on_ci()
skip_on_cran()

token <- Sys.getenv("DX_API_TOKEN")
if (!nzchar(token)) {
  skip("DX_API_TOKEN not set. Set it to run integration tests.")
}

# ===========================================================================
# extract_ls()
# ===========================================================================

test_that("extract_ls() returns a data.frame with correct columns", {
  result <- suppressMessages(extract_ls())
  expect_s3_class(result, "data.frame")
  expect_named(result, c("field_name", "title"))
})

test_that("extract_ls() returns at least one field", {
  result <- suppressMessages(extract_ls())
  expect_gt(nrow(result), 0)
})

test_that("extract_ls() field_name values follow participant.p<id> format", {
  result <- suppressMessages(extract_ls())
  expect_true(all(grepl("^participant\\.p", result$field_name)))
})

test_that("extract_ls() title column has no fully-missing values", {
  result <- suppressMessages(extract_ls())
  expect_lt(sum(is.na(result$title)), nrow(result))
})

test_that("extract_ls() populates session cache after first call", {
  .ukbflow_cache$fields <- NULL
  suppressMessages(extract_ls())
  expect_false(is.null(.ukbflow_cache$fields))
  expect_gt(nrow(.ukbflow_cache$fields), 0)
})

test_that("extract_ls() returns from cache on second call (no re-fetch)", {
  suppressMessages(extract_ls())                     # ensure cache is warm
  n_cached <- nrow(.ukbflow_cache$fields)

  # Corrupt cache to a sentinel — if re-fetch happens sentinel is overwritten;
  # if served from cache, nrow stays at 1
  .ukbflow_cache$fields <- data.frame(
    field_name = "sentinel", title = "sentinel", stringsAsFactors = FALSE
  )
  result <- suppressMessages(extract_ls())
  expect_equal(nrow(result), 1L)                     # served from (corrupted) cache

  # Restore a clean cache for subsequent tests
  .ukbflow_cache$fields <- NULL
  suppressMessages(extract_ls())
})

test_that("extract_ls() refresh = TRUE re-fetches and overwrites cache", {
  # Seed stale data
  .ukbflow_cache$fields <- data.frame(
    field_name = "stale.field", title = "stale", stringsAsFactors = FALSE
  )
  suppressMessages(extract_ls(refresh = TRUE))
  expect_gt(nrow(.ukbflow_cache$fields), 1L)
  .ukbflow_cache$fields <- NULL
})

test_that("extract_ls() pattern filtering returns a non-empty subset", {
  result_all      <- suppressMessages(extract_ls())
  result_filtered <- extract_ls(pattern = "^participant\\.p31(_|$)")
  expect_lt(nrow(result_filtered), nrow(result_all))
  expect_gt(nrow(result_filtered), 0L)
  expect_true(all(grepl("participant\\.p31", result_filtered$field_name)))
})

test_that("extract_ls() pattern search is case-insensitive on title", {
  result <- extract_ls(pattern = "SEX")
  expect_gt(nrow(result), 0L)
})

test_that("extract_ls() returns empty data.frame for unmatched pattern", {
  result <- extract_ls(pattern = "xyzzy_no_such_field_12345")
  expect_equal(nrow(result), 0L)
})

# ===========================================================================
# extract_pheno() and extract_batch() — not integration-tested
#
# Both functions trigger actual cloud computation (extract_dataset / table-
# exporter jobs) that incur cost and take several minutes to complete.
# They are covered exhaustively by mock-based unit tests in test-extract.R.
# If a real smoke-test is needed, run the following interactively:
#
#   df <- extract_pheno(c(31, 21022), dest = tempfile(fileext = ".csv"))
#   job_id <- extract_batch(c(31, 21022), priority = "low")
# ===========================================================================
