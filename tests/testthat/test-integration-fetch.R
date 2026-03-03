# =============================================================================
# test-integration-fetch.R — Integration tests for fetch_ series
# Requires real dx-toolkit, token, and network connection
# Run manually before release: devtools::test(filter = "integration-fetch")
# =============================================================================

skip_on_ci()
skip_on_cran()

token <- Sys.getenv("DX_API_TOKEN")
if (!nzchar(token)) {
  skip("DX_API_TOKEN not set. Set it to run integration tests.")
}

# ===========================================================================
# fetch_ls()
# ===========================================================================

test_that("fetch_ls() returns a data.frame with correct columns", {
  result <- fetch_ls()
  expect_s3_class(result, "data.frame")
  expect_named(result, c("name", "type", "size", "modified"))
})

test_that("fetch_ls() returns at least one entry at project root", {
  result <- fetch_ls()
  expect_gt(nrow(result), 0)
})

test_that("fetch_ls() type column contains only 'file' or 'folder'", {
  result <- fetch_ls()
  expect_true(all(result$type %in% c("file", "folder")))
})

test_that("fetch_ls() filter by type = 'folder' returns only folders", {
  result <- fetch_ls(type = "folder")
  expect_true(all(result$type == "folder"))
})

# ===========================================================================
# fetch_tree()
# ===========================================================================

test_that("fetch_tree() returns a character vector invisibly", {
  result <- suppressMessages(fetch_tree(max_depth = 1, verbose = FALSE))
  expect_type(result, "character")
})

test_that("fetch_tree() output lines contain entry names", {
  result <- suppressMessages(fetch_tree(max_depth = 1, verbose = FALSE))
  expect_true(length(result) > 0)
  expect_true(any(grepl("\\+--", result)))
})

# ===========================================================================
# fetch_url()
# ===========================================================================

test_that("fetch_url() returns a named character vector for a single file", {
  result <- fetch_url("Showcase metadata/field.tsv")
  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(startsWith(result[[1]], "https://"))
  expect_equal(names(result), "field.tsv")
})

test_that("fetch_url() URL is accessible (HTTP 200)", {
  url <- fetch_url("Showcase metadata/field.tsv")[[1]]
  response <- tryCatch(
    suppressWarnings(readLines(url, n = 1, warn = FALSE)),
    error = function(e) NULL
  )
  expect_false(is.null(response))
})
