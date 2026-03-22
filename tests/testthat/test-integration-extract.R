# =============================================================================
# test-integration-extract.R — Integration tests for extract_ series
# Requires real dx-toolkit, token, and network connection
# Run manually before release: devtools::test(filter = "integration-extract")
# =============================================================================


# ===========================================================================
# extract_ls()
# ===========================================================================

test_that("extract_ls() returns a data.frame with correct columns", {
  .skip_if_no_dx_token()
  result <- suppressMessages(extract_ls())
  expect_s3_class(result, "data.frame")
  expect_named(result, c("field_name", "title"))
})

test_that("extract_ls() returns at least one field", {
  .skip_if_no_dx_token()
  result <- suppressMessages(extract_ls())
  expect_gt(nrow(result), 0)
})

test_that("extract_ls() field_name values follow participant. format", {
  .skip_if_no_dx_token()
  result <- suppressMessages(extract_ls())
  expect_true(all(grepl("^participant\\.", result$field_name)))
})

test_that("extract_ls() title column has no fully-missing values", {
  .skip_if_no_dx_token()
  result <- suppressMessages(extract_ls())
  expect_lt(sum(is.na(result$title)), nrow(result))
})

test_that("extract_ls() populates per-dataset session cache after first call", {
  .skip_if_no_dx_token()
  .ukbflow_cache$fields <- NULL
  suppressMessages(extract_ls())
  expect_gt(length(.ukbflow_cache$fields), 0L)
})

test_that("extract_ls() returns from cache on second call (no re-fetch)", {
  .skip_if_no_dx_token()
  suppressMessages(extract_ls(refresh = TRUE))          # warm cache with real data
  dataset_key <- names(.ukbflow_cache$fields)[1]

  # Replace slot with sentinel — a re-fetch would overwrite it
  .ukbflow_cache$fields[[dataset_key]] <- data.frame(
    field_name = "sentinel", title = "sentinel", stringsAsFactors = FALSE
  )
  result <- suppressMessages(extract_ls())
  expect_equal(nrow(result), 1L)                        # served from (sentinel) cache

  .ukbflow_cache$fields <- NULL
  suppressMessages(extract_ls())                        # restore real cache
})

test_that("extract_ls() refresh = TRUE re-fetches and overwrites cache", {
  .skip_if_no_dx_token()
  suppressMessages(extract_ls(refresh = TRUE))
  dataset_key <- names(.ukbflow_cache$fields)[1]
  expect_gt(nrow(.ukbflow_cache$fields[[dataset_key]]), 1L)
})

test_that("extract_ls() pattern filtering returns a non-empty subset", {
  .skip_if_no_dx_token()
  result_all      <- suppressMessages(extract_ls())
  result_filtered <- extract_ls(pattern = "^participant\\.p31(_|$)")
  expect_lt(nrow(result_filtered), nrow(result_all))
  expect_gt(nrow(result_filtered), 0L)
  expect_true(all(grepl("participant\\.p31", result_filtered$field_name)))
})

test_that("extract_ls() pattern search is case-insensitive on title", {
  .skip_if_no_dx_token()
  result <- extract_ls(pattern = "SEX")
  expect_gt(nrow(result), 0L)
})

test_that("extract_ls() returns empty data.frame for unmatched pattern", {
  .skip_if_no_dx_token()
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
#   df <- extract_pheno(c(31, 21022))   # RAP only
#   job_id <- extract_batch(c(31, 21022), priority = "low")
# ===========================================================================
