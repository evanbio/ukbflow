# =============================================================================
# test-audit.R — Unit tests for audit_* series
# =============================================================================


# ===========================================================================
# audit_start()
# ===========================================================================

test_that("audit_start() returns a ukbflow_audit object", {
  aud <- audit_start("example_analysis")
  expect_s3_class(aud, "ukbflow_audit")
  expect_type(aud, "list")
})

test_that("audit_start() records root metadata", {
  aud <- audit_start("example_analysis")
  expect_equal(aud$name, "example_analysis")
  expect_type(aud$start_time, "character")
  expect_type(aud$ukbflow_version, "character")
  expect_s3_class(aud$session_info, "sessionInfo")
  expect_type(aud$dx_user, "character")
  expect_type(aud$dx_project, "character")
})

test_that("audit_start() start_time uses ISO-like timestamp", {
  aud <- audit_start("example_analysis")
  expect_match(aud$start_time, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")
})

test_that("audit_start() validates name", {
  expect_error(audit_start(1), "name")
  expect_error(audit_start(""), "name")
})

test_that("audit_start() records DNAnexus context when available", {
  local_mocked_bindings(
    .dx_run = function(args, ...) {
      expect_equal(args, c("whoami"))
      list(success = TRUE, stdout = "test_user")
    },
    .dx_get_project_id = function() "project-abc123",
    .package = "ukbflow"
  )

  aud <- audit_start("example_analysis")
  expect_equal(aud$dx_user, "test_user")
  expect_equal(aud$dx_project, "project-abc123")
})

test_that("audit_start() records NA for unavailable DNAnexus context", {
  local_mocked_bindings(
    .dx_run = function(...) stop("dx not available"),
    .dx_get_project_id = function() NA_character_,
    .package = "ukbflow"
  )

  aud <- audit_start("example_analysis")
  expect_true(is.na(aud$dx_user))
  expect_true(is.na(aud$dx_project))
})


# ===========================================================================
# audit_fields()
# ===========================================================================

test_that("audit_fields() appends an extraction record", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(
    aud,
    field_id = c(31, 53, 21022),
    dataset = "app123.dataset",
    note = "Core fields"
  )

  expect_length(aud$extraction, 1L)
  rec <- aud$extraction[[1L]]
  expect_equal(rec$field_id, c(31L, 53L, 21022L))
  expect_equal(rec$dataset, "app123.dataset")
  expect_equal(rec$note, "Core fields")
  expect_equal(rec$n_fields, 3L)
  expect_match(rec$recorded_at, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")
})

test_that("audit_fields() appends multiple extraction records", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53), note = "first")
  aud <- audit_fields(aud, c(41270, 41280), note = "second")

  expect_length(aud$extraction, 2L)
  expect_equal(aud$extraction[[1L]]$field_id, c(31L, 53L))
  expect_equal(aud$extraction[[2L]]$field_id, c(41270L, 41280L))
})

test_that("audit_fields() records NA for missing optional values", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53))
  rec <- aud$extraction[[1L]]

  expect_true(is.na(rec$dataset))
  expect_true(is.na(rec$note))
})

test_that("audit_fields() deduplicates field_id within a record", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 31, 53))

  expect_equal(aud$extraction[[1L]]$field_id, c(31L, 53L))
  expect_equal(aud$extraction[[1L]]$n_fields, 2L)
})

test_that("audit_fields() validates inputs", {
  aud <- audit_start("example_analysis")
  expect_error(audit_fields(list(), 31), "ukbflow_audit")
  expect_error(audit_fields(aud, character(0)), "field_id")
  expect_error(audit_fields(aud, c(31, NA)), "NA")
  expect_error(audit_fields(aud, 31, dataset = 1), "dataset")
  expect_error(audit_fields(aud, 31, note = 1), "note")
})


# ===========================================================================
# audit_snapshot()
# ===========================================================================

test_that("audit_snapshot() appends a snapshot record", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:3, x = c(1, NA, 3), y = c("", "a", "b"))

  aud <- suppressMessages(audit_snapshot(aud, dt, "raw"))

  expect_length(aud$snapshots, 1L)
  rec <- aud$snapshots[[1L]]
  expect_equal(rec$label, "raw")
  expect_equal(rec$nrow, 3L)
  expect_equal(rec$ncol, 3L)
  expect_equal(rec$n_na_cols, 2L)
  expect_equal(rec$columns, names(dt))
  expect_type(rec$object_size_mb, "double")
  expect_match(rec$recorded_at, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")
})

test_that("audit_snapshot() appends multiple snapshot records", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2, x = 1:2)

  aud <- suppressMessages(audit_snapshot(aud, dt, "raw"))
  aud <- suppressMessages(audit_snapshot(aud, dt, "analysis_ready"))

  expect_length(aud$snapshots, 2L)
  expect_equal(vapply(aud$snapshots, `[[`, "", "label"),
               c("raw", "analysis_ready"))
})

test_that("audit_snapshot() rejects duplicate labels", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2)
  aud <- suppressMessages(audit_snapshot(aud, dt, "raw"))

  expect_error(
    suppressMessages(audit_snapshot(aud, dt, "raw")),
    "already exists"
  )
})

test_that("audit_snapshot() check_na=FALSE skips missingness scan", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:3, x = c(1, NA, 3))

  aud <- suppressMessages(audit_snapshot(aud, dt, "raw", check_na = FALSE))

  expect_true(is.na(aud$snapshots[[1L]]$n_na_cols))
})

test_that("audit_snapshot() reset clears only snapshots layer", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53))
  dt <- data.frame(eid = 1:2)
  aud <- suppressMessages(audit_snapshot(aud, dt, "raw"))

  aud <- suppressMessages(audit_snapshot(aud, reset = TRUE))

  expect_null(aud$snapshots)
  expect_length(aud$extraction, 1L)
  expect_equal(aud$name, "example_analysis")
})

test_that("audit_snapshot() validates inputs", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2)

  expect_error(audit_snapshot(list(), dt, "raw"), "ukbflow_audit")
  expect_error(audit_snapshot(aud, reset = NA), "reset")
  expect_error(audit_snapshot(aud, check_na = NA), "check_na")
  expect_error(audit_snapshot(aud, verbose = NA), "verbose")
  expect_error(audit_snapshot(aud, label = "raw"), "data")
  expect_error(audit_snapshot(aud, dt), "label")
  expect_error(audit_snapshot(aud, "not data", "raw"), "data.frame")
  expect_error(audit_snapshot(aud, dt, ""), "label")
})

test_that("audit_snapshot() verbose=FALSE produces no messages", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2)

  expect_no_message(audit_snapshot(aud, dt, "raw", verbose = FALSE))
})


# ===========================================================================
# print.ukbflow_audit()
# ===========================================================================

test_that("print.ukbflow_audit() returns audit object invisibly", {
  aud <- audit_start("example_analysis")
  visible <- NULL
  capture.output(
    visible <- withVisible(print(aud)),
    type = "message"
  )
  expect_false(visible$visible)
  expect_identical(visible$value, aud)
})
