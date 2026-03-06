# =============================================================================
# test-job.R — Unit tests for job_ series (mock-based, no network required)
# =============================================================================

# Helper: build a fake .dx_run() result
.fake_dx <- function(stdout = "", stderr = "", status = 0) {
  list(stdout = stdout, stderr = stderr, status = status, success = status == 0)
}

# Fake describe list — done job
.fake_desc_done <- function() {
  list(
    state          = "done",
    runInput       = list(output = "ad_pheno"),
    output         = list(csv = list(list(`$dnanexus_link` = "file-XXXX"))),
    failureMessage = NULL,
    failureReason  = NULL
  )
}

# Fake describe list — failed job
.fake_desc_failed <- function() {
  list(
    state          = "failed",
    runInput       = list(output = "ad_pheno"),
    output         = NULL,
    failureMessage = "AppError: invalid field names",
    failureReason  = "AppError"
  )
}

# Fake describe list — running job
.fake_desc_running <- function() {
  list(
    state          = "running",
    runInput       = list(output = "ad_pheno"),
    output         = list(),
    failureMessage = NULL,
    failureReason  = NULL
  )
}

# Fake dx find jobs stdout (3 real jobs + trailing "More results" line)
.fake_find_jobs_stdout <- function() {
  paste(
    "* Table exporter (table-exporter:main) (done) job-AAAAAAAAAAAA",
    "  user001 2026-03-03 17:15:21 (runtime 0:04:36)",
    "* Table exporter (table-exporter:main) (failed) job-BBBBBBBBBBBB",
    "  user001 2026-03-03 16:57:07 (runtime 0:03:25)",
    "* Table exporter (table-exporter:main) (running) job-CCCCCCCCCCCC",
    "  user001 2026-03-03 18:27:02",
    "* More results not shown; use -n to increase number of results or",
    "  --created-before to show older results",
    sep = "\n"
  )
}

# ===========================================================================
# .dx_job_output_id() — pure function, no mocking needed
# ===========================================================================

test_that(".dx_job_output_id() returns file ID from done describe", {
  id <- ukbflow:::.dx_job_output_id(.fake_desc_done())
  expect_equal(id, "file-XXXX")
})

test_that(".dx_job_output_id() stops when output is NULL (failed job)", {
  expect_error(
    ukbflow:::.dx_job_output_id(.fake_desc_failed()),
    "no output CSV"
  )
})

test_that(".dx_job_output_id() stops when output$csv is empty list", {
  desc <- .fake_desc_done()
  desc$output$csv <- list()
  expect_error(ukbflow:::.dx_job_output_id(desc), "no output CSV")
})

# ===========================================================================
# .dx_job_output_name() — pure function, no mocking needed
# ===========================================================================

test_that(".dx_job_output_name() returns output name from runInput", {
  expect_equal(ukbflow:::.dx_job_output_name(.fake_desc_done()), "ad_pheno")
})

# ===========================================================================
# .dx_parse_jobs() — pure function, no mocking needed
# ===========================================================================

test_that(".dx_parse_jobs() returns empty data.frame for empty stdout", {
  result <- ukbflow:::.dx_parse_jobs("")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_named(result, c("job_id", "name", "state", "created", "runtime"))
})

test_that(".dx_parse_jobs() parses done/failed/running jobs correctly", {
  result <- ukbflow:::.dx_parse_jobs(.fake_find_jobs_stdout())
  expect_equal(nrow(result), 3)
  expect_equal(result$job_id,  c("job-AAAAAAAAAAAA", "job-BBBBBBBBBBBB", "job-CCCCCCCCCCCC"))
  expect_equal(result$state,   c("done", "failed", "running"))
})

test_that(".dx_parse_jobs() skips 'More results not shown' line", {
  result <- ukbflow:::.dx_parse_jobs(.fake_find_jobs_stdout())
  expect_equal(nrow(result), 3)
  expect_false(any(grepl("More results", result$job_id)))
})

test_that(".dx_parse_jobs() sets NA runtime for running job", {
  result <- ukbflow:::.dx_parse_jobs(.fake_find_jobs_stdout())
  expect_true(is.na(result$runtime[result$state == "running"]))
  expect_equal(result$runtime[result$state == "done"], "0:04:36")
})

test_that(".dx_parse_jobs() returns POSIXct created column", {
  result <- ukbflow:::.dx_parse_jobs(.fake_find_jobs_stdout())
  expect_s3_class(result$created, "POSIXct")
})

test_that(".dx_parse_jobs() returns correct column names", {
  result <- ukbflow:::.dx_parse_jobs(.fake_find_jobs_stdout())
  expect_named(result, c("job_id", "name", "state", "created", "runtime"))
})

# ===========================================================================
# job_status()
# ===========================================================================

test_that("job_status() returns named character for done job", {
  mockery::stub(job_status, ".dx_job_describe", function(...) .fake_desc_done())
  result <- job_status("job-XXXX")
  expect_type(result, "character")
  expect_equal(result[[1]], "done")
  expect_equal(names(result), "job-XXXX")
})

test_that("job_status() returns 'failed' with failure_message attr", {
  mockery::stub(job_status, ".dx_job_describe", function(...) .fake_desc_failed())
  result <- job_status("job-XXXX")
  expect_equal(result[[1]], "failed")
  expect_equal(attr(result, "failure_message"), "AppError: invalid field names")
})

test_that("job_status() failure_message falls back to failureReason", {
  desc <- .fake_desc_failed()
  desc$failureMessage <- NULL
  mockery::stub(job_status, ".dx_job_describe", function(...) desc)
  result <- job_status("job-XXXX")
  expect_equal(attr(result, "failure_message"), "AppError")
})

test_that("job_status() returns NULL failure_message for done job", {
  mockery::stub(job_status, ".dx_job_describe", function(...) .fake_desc_done())
  result <- job_status("job-XXXX")
  expect_null(attr(result, "failure_message"))
})

test_that("job_status() stops on invalid job_id format", {
  expect_error(job_status("notajob"), "job-XXXX")
})

# ===========================================================================
# job_wait()
# ===========================================================================

test_that("job_wait() returns invisibly when job is already done", {
  mockery::stub(job_wait, ".dx_job_describe", function(...) .fake_desc_done())
  expect_invisible(suppressMessages(job_wait("job-XXXX", verbose = FALSE)))
  result <- suppressMessages(job_wait("job-XXXX", verbose = FALSE))
  expect_equal(result, "done")
})

test_that("job_wait() stops with message when job failed", {
  mockery::stub(job_wait, ".dx_job_describe", function(...) .fake_desc_failed())
  expect_error(
    suppressMessages(job_wait("job-XXXX", verbose = FALSE)),
    "AppError: invalid field names"
  )
})

test_that("job_wait() stops when job is terminated", {
  desc_terminated <- .fake_desc_done()
  desc_terminated$state <- "terminated"
  mockery::stub(job_wait, ".dx_job_describe", function(...) desc_terminated)
  expect_error(
    suppressMessages(job_wait("job-XXXX", verbose = FALSE)),
    "terminated"
  )
})

test_that("job_wait() stops on timeout", {
  mockery::stub(job_wait, ".dx_job_describe", function(...) .fake_desc_running())
  expect_error(
    suppressMessages(job_wait("job-XXXX", timeout = 0, verbose = FALSE)),
    "Timed out"
  )
})

test_that("job_wait() stops on invalid job_id format", {
  expect_error(job_wait("notajob"), "job-XXXX")
})

test_that("job_wait() prints done symbol when verbose = TRUE", {
  mockery::stub(job_wait, ".dx_job_describe", function(...) .fake_desc_done())
  expect_message(job_wait("job-XXXX", verbose = TRUE), "\u2714")
})

test_that("job_wait() prints fail symbol when verbose = TRUE and job failed", {
  mockery::stub(job_wait, ".dx_job_describe", function(...) .fake_desc_failed())
  expect_error(
    expect_message(job_wait("job-XXXX", verbose = TRUE), "\u2716"),
    "AppError"
  )
})

# ===========================================================================
# job_path()
# ===========================================================================

test_that("job_path() stops on invalid job_id format", {
  expect_error(job_path("notajob"), "job-XXXX")
})

test_that("job_path() stops when job is not done", {
  mockery::stub(job_path, ".dx_job_describe", function(...) .fake_desc_running())
  expect_error(suppressMessages(job_path("job-XXXX")), "not 'done'")
})

test_that("job_path() stops when job failed", {
  mockery::stub(job_path, ".dx_job_describe", function(...) .fake_desc_failed())
  expect_error(suppressMessages(job_path("job-XXXX")), "not 'done'")
})

test_that("job_path() returns /mnt/project/ path for done job", {
  mockery::stub(job_path, ".dx_job_describe", function(...) .fake_desc_done())
  mockery::stub(job_path, ".dx_file_path",
                function(...) "/mnt/project/ad_pheno.csv")
  result <- job_path("job-XXXX")
  expect_equal(result, "/mnt/project/ad_pheno.csv")
})

# ===========================================================================
# job_result()
# ===========================================================================

test_that("job_result() stops when not on RAP", {
  mockery::stub(job_result, ".is_on_rap", function() FALSE)
  expect_error(job_result("job-XXXX"), "RAP environment")
})

test_that("job_result() stops on invalid job_id format", {
  mockery::stub(job_result, ".is_on_rap", function() TRUE)
  expect_error(job_result("notajob"), "job-XXXX")
})

test_that("job_result() stops when job is not done", {
  mockery::stub(job_result, ".is_on_rap", function() TRUE)
  mockery::stub(job_result, "job_path", function(...) {
    stop("Job job-XXXX is 'running', not 'done'.")
  })
  expect_error(suppressMessages(job_result("job-XXXX")), "not 'done'")
})

test_that("job_result() returns a data.table when on RAP", {
  tmp <- tempfile(fileext = ".csv")
  write.csv(data.frame(eid = c(1L, 2L), p31 = c(0L, 1L)), tmp, row.names = FALSE)

  mockery::stub(job_result, ".is_on_rap", function() TRUE)
  mockery::stub(job_result, "job_path", function(...) tmp)

  result <- suppressMessages(job_result("job-XXXX"))
  expect_true(data.table::is.data.table(result))
  expect_equal(nrow(result), 2L)
})

# ===========================================================================
# job_ls()
# ===========================================================================

test_that("job_ls() returns a data.frame with correct columns", {
  mockery::stub(job_ls, ".dx_find_jobs_raw",
                function(...) .fake_dx(stdout = .fake_find_jobs_stdout()))
  result <- job_ls()
  expect_s3_class(result, "data.frame")
  expect_named(result, c("job_id", "name", "state", "created", "runtime"))
})

test_that("job_ls() returns all jobs when state = NULL", {
  mockery::stub(job_ls, ".dx_find_jobs_raw",
                function(...) .fake_dx(stdout = .fake_find_jobs_stdout()))
  result <- job_ls()
  expect_equal(nrow(result), 3L)
})

test_that("job_ls() filters by state correctly", {
  mockery::stub(job_ls, ".dx_find_jobs_raw",
                function(...) .fake_dx(stdout = .fake_find_jobs_stdout()))
  result <- job_ls(state = "done")
  expect_equal(nrow(result), 1L)
  expect_true(all(result$state == "done"))
})

test_that("job_ls() filters by multiple states", {
  mockery::stub(job_ls, ".dx_find_jobs_raw",
                function(...) .fake_dx(stdout = .fake_find_jobs_stdout()))
  result <- job_ls(state = c("done", "failed"))
  expect_equal(nrow(result), 2L)
  expect_true(all(result$state %in% c("done", "failed")))
})

test_that("job_ls() returns empty data.frame when no jobs match state filter", {
  mockery::stub(job_ls, ".dx_find_jobs_raw",
                function(...) .fake_dx(stdout = .fake_find_jobs_stdout()))
  result <- job_ls(state = "terminated")
  expect_equal(nrow(result), 0L)
})

test_that("job_ls() stops when dx find jobs fails", {
  mockery::stub(job_ls, ".dx_find_jobs_raw",
                function(...) .fake_dx(stderr = "Not logged in", status = 1))
  expect_error(job_ls(), "Failed to list jobs")
})
