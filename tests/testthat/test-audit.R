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
  expect_equal(aud$project_id, "example_analysis")
  expect_type(aud$start_time, "character")
  expect_type(aud$ukbflow_version, "character")
  expect_s3_class(aud$session_info, "sessionInfo")
})

test_that("audit_start() start_time uses ISO-like timestamp", {
  aud <- audit_start("example_analysis")
  expect_match(aud$start_time, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")
})

test_that("audit_start() validates project_id", {
  expect_error(audit_start(1), "project_id")
  expect_error(audit_start(""), "project_id")
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
