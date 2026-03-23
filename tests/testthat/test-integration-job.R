# =============================================================================
# test-integration-job.R — Integration tests for job_ series
# Requires real dx-toolkit, token, and network connection
# Run manually before release: devtools::test(filter = "integration-job")
# =============================================================================


# Known job IDs from this project (used as stable test fixtures)
# State is immutable once terminal — safe to hardcode
JOB_DONE   <- "job-J6YBJ7QJ0QQ82Kz0J52x2jGp"   # done, ukb_pheno_20260303_171503
JOB_FAILED <- "job-J6YB4jjJ0QQ3fVJ0yPqG3b1K"   # failed, CRLF error


# ===========================================================================
# job_ls()
# ===========================================================================

test_that("job_ls() returns a data.frame with correct columns", {
  .skip_if_no_dx_token()
  result <- job_ls(n = 5)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("job_id", "name", "state", "created", "runtime"))
})

test_that("job_ls() returns at least one job", {
  .skip_if_no_dx_token()
  result <- job_ls(n = 5)
  expect_gt(nrow(result), 0)
})

test_that("job_ls() job_id values follow job-XXXX format", {
  .skip_if_no_dx_token()
  result <- job_ls(n = 5)
  expect_true(all(grepl("^job-", result$job_id)))
})

test_that("job_ls() state column contains only valid states", {
  .skip_if_no_dx_token()
  valid_states <- c("idle", "runnable", "running", "done", "failed", "terminated")
  result <- job_ls(n = 20)
  expect_true(all(result$state %in% valid_states))
})

test_that("job_ls() created column is POSIXct", {
  .skip_if_no_dx_token()
  result <- job_ls(n = 5)
  expect_s3_class(result$created, "POSIXct")
})

test_that("job_ls() state filter returns only matching rows", {
  .skip_if_no_dx_token()
  result <- job_ls(n = 20, state = "done")
  if (nrow(result) > 0) {
    expect_true(all(result$state == "done"))
  } else {
    skip("No done jobs found to test filter.")
  }
})


# ===========================================================================
# job_status()
# ===========================================================================

test_that("job_status() returns 'done' for known done job", {
  .skip_if_no_dx_token()
  result <- job_status(JOB_DONE)
  expect_equal(result[[1]], "done")
})

test_that("job_status() returns named character with job_id as name", {
  .skip_if_no_dx_token()
  result <- job_status(JOB_DONE)
  expect_type(result, "character")
  expect_equal(names(result), JOB_DONE)
})

test_that("job_status() returns 'failed' for known failed job", {
  .skip_if_no_dx_token()
  result <- job_status(JOB_FAILED)
  expect_equal(result[[1]], "failed")
})

test_that("job_status() attaches failure_message for failed job", {
  .skip_if_no_dx_token()
  result <- job_status(JOB_FAILED)
  expect_false(is.null(attr(result, "failure_message")))
  expect_true(nzchar(attr(result, "failure_message")))
})


# ===========================================================================
# job_wait()
# ===========================================================================

test_that("job_wait() returns 'done' immediately for already-done job", {
  .skip_if_no_dx_token()
  result <- suppressMessages(job_wait(JOB_DONE, verbose = FALSE))
  expect_equal(result, "done")
})

test_that("job_wait() stops with error message for known failed job", {
  .skip_if_no_dx_token()
  expect_error(
    suppressMessages(job_wait(JOB_FAILED, verbose = FALSE)),
    "failed"
  )
})


# ===========================================================================
# job_path()
# ===========================================================================

test_that("job_path() returns a /mnt/project/ path for known done job", {
  skip("job_path() requires real RAP environment with valid job ID")
  .skip_if_no_dx_token()
  result <- job_path(JOB_DONE)
  expect_type(result, "character")
  expect_true(startsWith(result, "/mnt/project/"))
  expect_true(endsWith(result, ".csv"))
})

test_that("job_path() stops for known failed job", {
  .skip_if_no_dx_token()
  expect_error(suppressMessages(job_path(JOB_FAILED)), "not 'done'")
})


# ===========================================================================
# job_result()
# ===========================================================================

# Note: job_result() requires RAP environment and a job whose output file
# still exists on the project. Use an active job for full integration testing:
#
#   job_id <- extract_batch(c(31, 21022), file = "integration_test")
#   job_wait(job_id)
#   df <- job_result(job_id)
#   # clean up: dx rm <output_file_id>
