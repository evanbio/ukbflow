# =============================================================================
# test-utils.R — Unit tests for package-wide internal helpers (R/utils.R)
# =============================================================================


# ===========================================================================
# .assert_scalar_string()
# ===========================================================================

test_that(".assert_scalar_string() accepts a valid scalar string", {
  expect_invisible(ukbflow:::.assert_scalar_string("abc"))
})

test_that(".assert_scalar_string() rejects an empty string", {
  expect_error(ukbflow:::.assert_scalar_string(""), "single non-empty string")
})

test_that(".assert_scalar_string() rejects NA_character_", {
  expect_error(ukbflow:::.assert_scalar_string(NA_character_), "single non-empty string")
})

test_that(".assert_scalar_string() rejects non-character input", {
  expect_error(ukbflow:::.assert_scalar_string(1), "single non-empty string")
})

test_that(".assert_scalar_string() rejects length > 1 vector", {
  expect_error(ukbflow:::.assert_scalar_string(c("a", "b")), "single non-empty string")
})

test_that(".assert_scalar_string() error message includes the argument name", {
  my_token <- NA_character_
  expect_error(ukbflow:::.assert_scalar_string(my_token), "`my_token`")
})
