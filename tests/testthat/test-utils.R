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


# ===========================================================================
# .assert_integer_ids()
# ===========================================================================

test_that(".assert_integer_ids() accepts a valid integer vector and returns integers", {
  result <- ukbflow:::.assert_integer_ids(c(31, 53, 22189))
  expect_equal(result, c(31L, 53L, 22189L))
})

test_that(".assert_integer_ids() deduplicates values", {
  result <- ukbflow:::.assert_integer_ids(c(31, 31, 53))
  expect_equal(result, c(31L, 53L))
})

test_that(".assert_integer_ids() rejects empty vector", {
  expect_error(ukbflow:::.assert_integer_ids(integer(0)), "non-empty numeric")
})

test_that(".assert_integer_ids() rejects non-numeric input", {
  expect_error(ukbflow:::.assert_integer_ids("p31"), "non-empty numeric")
})

test_that(".assert_integer_ids() rejects NA values", {
  expect_error(ukbflow:::.assert_integer_ids(c(31, NA)), "NA")
})

test_that(".assert_integer_ids() rejects Inf values", {
  expect_error(ukbflow:::.assert_integer_ids(c(31, Inf)), "Inf")
})

test_that(".assert_integer_ids() rejects NaN values", {
  expect_error(ukbflow:::.assert_integer_ids(c(31, NaN)), "NaN")
})

test_that(".assert_integer_ids() rejects decimal values", {
  expect_error(ukbflow:::.assert_integer_ids(31.7), "whole numbers")
})

test_that(".assert_integer_ids() error message includes the argument name", {
  bad_ids <- c(31, NA)
  expect_error(ukbflow:::.assert_integer_ids(bad_ids), "bad_ids")
})
