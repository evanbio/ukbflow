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
