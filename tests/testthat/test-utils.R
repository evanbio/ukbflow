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


# ===========================================================================
# .assert_job_id()
# ===========================================================================

test_that(".assert_job_id() accepts a valid job-XXXX string", {
  expect_invisible(ukbflow:::.assert_job_id("job-XXXX"))
})

test_that(".assert_job_id() returns the job_id invisibly", {
  result <- ukbflow:::.assert_job_id("job-ABC123")
  expect_equal(result, "job-ABC123")
})

test_that(".assert_job_id() rejects wrong prefix", {
  expect_error(ukbflow:::.assert_job_id("notajob"), "job-XXXX")
})

test_that(".assert_job_id() rejects NA_character_", {
  expect_error(ukbflow:::.assert_job_id(NA_character_))
})

test_that(".assert_job_id() rejects length > 1 vector", {
  expect_error(ukbflow:::.assert_job_id(c("job-AAA", "job-BBB")))
})

test_that(".assert_job_id() rejects non-character input", {
  expect_error(ukbflow:::.assert_job_id(123))
})

test_that(".assert_job_id() rejects empty string", {
  expect_error(ukbflow:::.assert_job_id(""))
})

test_that(".assert_job_id() error message includes the argument name", {
  bad_id <- "notajob"
  expect_error(ukbflow:::.assert_job_id(bad_id), "bad_id")
})


# ===========================================================================
# .assert_count()
# ===========================================================================

test_that(".assert_count() accepts a valid positive integer", {
  expect_invisible(ukbflow:::.assert_count(20))
})

test_that(".assert_count() returns as.integer invisibly", {
  result <- ukbflow:::.assert_count(5)
  expect_equal(result, 5L)
  expect_type(result, "integer")
})

test_that(".assert_count() accepts 1", {
  expect_invisible(ukbflow:::.assert_count(1))
})

test_that(".assert_count() rejects 0", {
  expect_error(ukbflow:::.assert_count(0), "positive integer")
})

test_that(".assert_count() rejects negative value", {
  expect_error(ukbflow:::.assert_count(-5), "positive integer")
})

test_that(".assert_count() rejects Inf", {
  expect_error(ukbflow:::.assert_count(Inf), "positive integer")
})

test_that(".assert_count() rejects NA", {
  expect_error(ukbflow:::.assert_count(NA_real_), "positive integer")
})

test_that(".assert_count() rejects decimal value", {
  expect_error(ukbflow:::.assert_count(1.5), "positive integer")
})

test_that(".assert_count() rejects character input", {
  expect_error(ukbflow:::.assert_count("five"), "positive integer")
})

test_that(".assert_count() rejects length > 1 vector", {
  expect_error(ukbflow:::.assert_count(c(5, 10)), "positive integer")
})

test_that(".assert_count() error message includes the argument name", {
  bad_n <- -1
  expect_error(ukbflow:::.assert_count(bad_n), "bad_n")
})


# ===========================================================================
# .assert_choices()
# ===========================================================================

test_that(".assert_choices() accepts NULL and returns NULL invisibly", {
  result <- ukbflow:::.assert_choices(NULL, c("a", "b"))
  expect_null(result)
})

test_that(".assert_choices() accepts a valid single choice", {
  expect_invisible(ukbflow:::.assert_choices("a", c("a", "b", "c")))
})

test_that(".assert_choices() accepts valid multiple choices", {
  expect_invisible(ukbflow:::.assert_choices(c("a", "b"), c("a", "b", "c")))
})

test_that(".assert_choices() accepts character(0)", {
  expect_invisible(ukbflow:::.assert_choices(character(0), c("a", "b")))
})

test_that(".assert_choices() rejects non-character input", {
  expect_error(ukbflow:::.assert_choices(TRUE, c("a", "b")), "character vector")
})

test_that(".assert_choices() rejects invalid value", {
  expect_error(ukbflow:::.assert_choices("oops", c("a", "b")), "oops")
})

test_that(".assert_choices() error message lists valid values", {
  expect_error(ukbflow:::.assert_choices("oops", c("a", "b")), "a")
})

test_that(".assert_choices() rejects mix of valid and invalid values", {
  expect_error(ukbflow:::.assert_choices(c("a", "oops"), c("a", "b")), "oops")
})

test_that(".assert_choices() error message includes the argument name", {
  bad_state <- "oops"
  expect_error(ukbflow:::.assert_choices(bad_state, c("a", "b")), "bad_state")
})
