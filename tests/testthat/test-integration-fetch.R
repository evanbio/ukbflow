# =============================================================================
# test-integration-fetch.R — Integration tests for fetch_ series
# Requires real dx-toolkit, token, and network connection
# Run manually before release: devtools::test(filter = "integration-fetch")
# =============================================================================


# ===========================================================================
# fetch_ls()
# ===========================================================================

test_that("fetch_ls() returns a data.frame with correct columns", {
  .skip_if_no_dx_token()
  result <- fetch_ls()
  expect_s3_class(result, "data.frame")
  expect_named(result, c("name", "type", "size", "modified"))
})

test_that("fetch_ls() returns at least one entry at project root", {
  .skip_if_no_dx_token()
  result <- fetch_ls()
  expect_gt(nrow(result), 0)
})

test_that("fetch_ls() type column contains only 'file' or 'folder'", {
  .skip_if_no_dx_token()
  result <- fetch_ls()
  expect_true(all(result$type %in% c("file", "folder")))
})

test_that("fetch_ls() filter by type = 'folder' returns only folders", {
  .skip_if_no_dx_token()
  result <- fetch_ls(type = "folder")
  expect_true(all(result$type == "folder"))
})

# ===========================================================================
# fetch_tree()
# ===========================================================================

test_that("fetch_tree() returns a character vector invisibly", {
  .skip_if_no_dx_token()
  result <- suppressMessages(fetch_tree(max_depth = 1, verbose = FALSE))
  expect_type(result, "character")
})

test_that("fetch_tree() output lines contain entry names", {
  .skip_if_no_dx_token()
  result <- suppressMessages(fetch_tree(max_depth = 1, verbose = FALSE))
  expect_true(length(result) > 0)
  expect_true(any(grepl("\\+--", result)))
})

# ===========================================================================
# fetch_url()
# ===========================================================================

test_that("fetch_url() returns a named character vector for a single file", {
  .skip_if_no_dx_token()
  result <- fetch_url("Showcase metadata/field.tsv")
  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(startsWith(result[[1]], "https://"))
  expect_equal(names(result), "field.tsv")
})

test_that("fetch_url() URL is accessible (HTTP 200)", {
  .skip_if_no_dx_token()
  url <- fetch_url("Showcase metadata/field.tsv")[[1]]
  response <- tryCatch(
    suppressWarnings(readLines(url, n = 1, warn = FALSE)),
    error = function(e) NULL
  )
  expect_false(is.null(response))
})
