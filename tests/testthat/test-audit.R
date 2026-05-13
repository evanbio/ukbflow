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
    label = "core_fields"
  )

  expect_length(aud$extraction, 1L)
  rec <- aud$extraction[[1L]]
  expect_equal(rec$field_id, c(31L, 53L, 21022L))
  expect_equal(rec$dataset, "app123.dataset")
  expect_equal(rec$label, "core_fields")
  expect_equal(rec$n_fields, 3L)
  expect_match(rec$recorded_at, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")
})

test_that("audit_fields() appends multiple extraction records", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53), label = "first")
  aud <- audit_fields(aud, c(41270, 41280), label = "second")

  expect_length(aud$extraction, 2L)
  expect_equal(aud$extraction[[1L]]$field_id, c(31L, 53L))
  expect_equal(aud$extraction[[2L]]$field_id, c(41270L, 41280L))
})

test_that("audit_fields() records NA for missing optional values", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53))
  rec <- aud$extraction[[1L]]

  expect_true(is.na(rec$dataset))
  expect_true(is.na(rec$label))
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
  expect_error(audit_fields(aud, 31, label = 1), "label")
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
# audit_cols()
# ===========================================================================

test_that("audit_cols() returns complete columns for a snapshot label", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2, sex = c("F", "M"), x = 1:2)
  aud <- audit_snapshot(aud, dt, "raw", verbose = FALSE)

  expect_equal(audit_cols(aud, "raw"), names(dt))
})

test_that("audit_cols() validates inputs", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2)
  aud <- audit_snapshot(aud, dt, "raw", verbose = FALSE)

  expect_error(audit_cols(list(), "raw"), "ukbflow_audit")
  expect_error(audit_cols(aud, 1), "label")
  expect_error(audit_cols(audit_start("empty"), "raw"), "No snapshots")
  expect_error(audit_cols(aud, "missing"), "missing")
})


# ===========================================================================
# audit_pheno()
# ===========================================================================

test_that("audit_pheno() records available phenotype components", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(
    eid = 1:5,
    lung_selfreport = c(TRUE, FALSE, TRUE, FALSE, FALSE),
    lung_selfreport_date = as.Date(c("2020-01-01", NA, "2020-02-01", NA, NA)),
    lung_icd10 = c(FALSE, TRUE, FALSE, FALSE, FALSE),
    lung_icd10_date = as.Date(c(NA, "2021-01-01", NA, NA, NA)),
    lung_hes = c(FALSE, TRUE, FALSE, FALSE, FALSE),
    lung_hes_date = as.Date(c(NA, "2021-01-01", NA, NA, NA)),
    lung_status = c(TRUE, TRUE, TRUE, FALSE, FALSE),
    lung_date = as.Date(c("2020-01-01", "2021-01-01", "2020-02-01", NA, NA)),
    lung_timing = c(2L, 2L, 1L, 0L, 0L),
    lung_followup_end = as.Date(rep("2022-10-31", 5L)),
    lung_followup_years = c(1, 2, NA, 4, 5)
  )

  aud <- audit_pheno(aud, dt, "lung")

  expect_length(aud$phenotypes, 1L)
  rec <- aud$phenotypes[[1L]]
  expect_equal(rec$name, "lung")
  expect_equal(rec$n, 5L)
  expect_true(rec$selfreport$present)
  expect_equal(rec$selfreport$n_cases, 2L)
  expect_equal(rec$icd10$n_cases, 1L)
  expect_equal(rec$sources$hes$n_cases, 1L)
  expect_false(rec$sources$death$present)
  expect_equal(rec$combined$n_cases, 3L)
  expect_equal(rec$timing$prevalent, 1L)
  expect_equal(rec$timing$incident, 2L)
  expect_equal(rec$followup$n_non_missing, 4L)
})

test_that("audit_pheno() records fixed framework for missing components", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(
    eid = 1:3,
    asthma_selfreport = c(TRUE, FALSE, FALSE)
  )

  aud <- audit_pheno(aud, dt, "asthma")
  rec <- aud$phenotypes[[1L]]

  expect_true(rec$selfreport$present)
  expect_true(is.na(rec$selfreport$date_col))
  expect_false(rec$icd10$present)
  expect_false(rec$combined$present)
  expect_false(rec$timing$present)
  expect_false(rec$followup$present)
})

test_that("audit_pheno() validates inputs", {
  aud <- audit_start("example_analysis")
  dt <- data.frame(eid = 1:2)

  expect_error(audit_pheno(list(), dt, "lung"), "ukbflow_audit")
  expect_error(audit_pheno(aud, "not data", "lung"), "data.frame")
  expect_error(audit_pheno(aud, dt, 1), "name")
  expect_error(audit_pheno(aud, dt, "lung"), "No phenotype columns")
})


# ===========================================================================
# audit_write()
# ===========================================================================

test_that("audit_write() writes a JSON manifest", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53), label = "core_fields")
  aud <- audit_snapshot(
    aud,
    data.frame(eid = 1:2, x = c(1, NA)),
    "raw",
    verbose = FALSE
  )
  aud <- audit_pheno(
    aud,
    data.frame(eid = 1:2, lung_status = c(TRUE, FALSE)),
    "lung"
  )
  file <- withr::local_tempfile(fileext = ".json")

  out <- suppressMessages(audit_write(aud, file))
  manifest <- jsonlite::read_json(file, simplifyVector = TRUE)

  expect_equal(out, normalizePath(file, winslash = "/", mustWork = TRUE))
  expect_equal(manifest$name, "example_analysis")
  expect_equal(manifest$extraction$n_fields, 2L)
  expect_equal(manifest$snapshots$label, "raw")
  expect_equal(manifest$phenotypes$name, "lung")
  expect_equal(manifest$phenotypes$combined$n_cases, 1L)
  expect_type(manifest$session_info, "character")
})

test_that("audit_write() preserves single field_id as a JSON array", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, 31)
  file <- withr::local_tempfile(fileext = ".json")

  suppressMessages(audit_write(aud, file))
  raw <- paste(readLines(file), collapse = "\n")

  expect_match(raw, '"field_id":\\s*\\[\\s*31\\s*\\]')
})

test_that("audit_write() preserves single snapshot column as a JSON array", {
  aud <- audit_start("example_analysis")
  aud <- audit_snapshot(
    aud,
    data.frame(eid = 1:3),
    "raw",
    verbose = FALSE
  )
  file <- withr::local_tempfile(fileext = ".json")

  suppressMessages(audit_write(aud, file))
  raw <- paste(readLines(file), collapse = "\n")

  expect_match(raw, '"columns":\\s*\\[\\s*"eid"\\s*\\]')
})

test_that("audit_write() refuses to overwrite by default", {
  aud <- audit_start("example_analysis")
  file <- withr::local_tempfile(fileext = ".json")
  writeLines("{}", file)

  expect_error(
    suppressMessages(audit_write(aud, file)),
    "already exists"
  )
})

test_that("audit_write() can overwrite existing file", {
  aud <- audit_start("example_analysis")
  file <- withr::local_tempfile(fileext = ".json")
  writeLines("{}", file)

  expect_no_error(suppressMessages(audit_write(aud, file, overwrite = TRUE)))
  manifest <- jsonlite::read_json(file, simplifyVector = TRUE)
  expect_equal(manifest$name, "example_analysis")
})

test_that("audit_write() validates inputs", {
  aud <- audit_start("example_analysis")
  missing_dir_file <- file.path(tempdir(), "missing_dir_for_audit", "audit.json")

  expect_error(audit_write(list(), tempfile(fileext = ".json")), "ukbflow_audit")
  expect_error(audit_write(aud, file = 1), "file")
  expect_error(audit_write(aud, overwrite = NA), "overwrite")
  expect_error(audit_write(aud, file = missing_dir_file), "directory")
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


# ===========================================================================
# summary.ukbflow_audit()
# ===========================================================================

test_that("summary.ukbflow_audit() prints a short audit summary", {
  aud <- audit_start("example_analysis")
  aud <- audit_fields(aud, c(31, 53), label = "core_fields")
  aud <- audit_snapshot(
    aud,
    data.frame(eid = 1:3, x = c(1, NA, 3)),
    "analysis_ready",
    verbose = FALSE
  )
  aud <- audit_pheno(
    aud,
    data.frame(
      eid = 1:3,
      lung_status = c(TRUE, FALSE, TRUE),
      lung_timing = c(2L, 0L, 1L)
    ),
    "lung"
  )

  visible <- NULL
  out <- capture.output(
    visible <- withVisible(summary(aud)),
    type = "message"
  )

  expect_false(visible$visible)
  expect_identical(visible$value, aud)
  expect_true(any(grepl("field records: 1", out, fixed = TRUE)))
  expect_true(any(grepl("core_fields: 2 fields", out, fixed = TRUE)))
  expect_true(any(grepl("snapshots: 1", out, fixed = TRUE)))
  expect_true(any(grepl("analysis_ready: 3 rows x 2 cols", out, fixed = TRUE)))
  expect_true(any(grepl("phenotypes: 1", out, fixed = TRUE)))
  expect_true(any(grepl("lung: 3 rows, 2 cases, timing 0/1/2 = 1/1/1", out, fixed = TRUE)))
})
