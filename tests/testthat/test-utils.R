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


# ===========================================================================
# %||%  (null-coalescing operator)
# ===========================================================================

test_that("%||% returns lhs when lhs is not NULL", {
  expect_equal("hello" %||% "fallback", "hello")
})

test_that("%||% returns rhs when lhs is NULL", {
  expect_equal(NULL %||% "fallback", "fallback")
})

test_that("%||% returns rhs when lhs is NULL, rhs is numeric", {
  expect_equal(NULL %||% 42L, 42L)
})

test_that("%||% returns lhs FALSE (not NULL) unchanged", {
  expect_equal(FALSE %||% TRUE, FALSE)
})

test_that("%||% returns lhs NA (not NULL) unchanged", {
  expect_equal(NA %||% "fallback", NA)
})


# ===========================================================================
# .assert_count_min()
# ===========================================================================

test_that(".assert_count_min() accepts integer equal to min", {
  expect_invisible(ukbflow:::.assert_count_min(2L, min = 2L))
})

test_that(".assert_count_min() returns as.integer invisibly", {
  result <- ukbflow:::.assert_count_min(3, min = 2L)
  expect_equal(result, 3L)
  expect_type(result, "integer")
})

test_that(".assert_count_min() accepts integer greater than min", {
  expect_invisible(ukbflow:::.assert_count_min(5L, min = 2L))
})

test_that(".assert_count_min() rejects value below min", {
  expect_error(ukbflow:::.assert_count_min(1L, min = 2L), ">= 2")
})

test_that(".assert_count_min() rejects decimal value", {
  expect_error(ukbflow:::.assert_count_min(2.5, min = 2L), ">= 2")
})

test_that(".assert_count_min() rejects NA", {
  expect_error(ukbflow:::.assert_count_min(NA_real_, min = 1L), ">= 1")
})

test_that(".assert_count_min() rejects Inf", {
  expect_error(ukbflow:::.assert_count_min(Inf, min = 1L), ">= 1")
})

test_that(".assert_count_min() rejects length > 1 vector", {
  expect_error(ukbflow:::.assert_count_min(c(2L, 3L), min = 2L), ">= 2")
})

test_that(".assert_count_min() error message includes the argument name", {
  bad_n <- 1L
  expect_error(ukbflow:::.assert_count_min(bad_n, min = 2L), "bad_n")
})


# ===========================================================================
# .assert_character()
# ===========================================================================

test_that(".assert_character() accepts a character scalar", {
  expect_invisible(ukbflow:::.assert_character("hello"))
})

test_that(".assert_character() accepts a character vector", {
  expect_invisible(ukbflow:::.assert_character(c("a", "b", "c")))
})

test_that(".assert_character() accepts character(0)", {
  expect_invisible(ukbflow:::.assert_character(character(0)))
})

test_that(".assert_character() rejects numeric input", {
  expect_error(ukbflow:::.assert_character(1L), "character vector")
})

test_that(".assert_character() rejects logical input", {
  expect_error(ukbflow:::.assert_character(TRUE), "character vector")
})

test_that(".assert_character() rejects NULL", {
  expect_error(ukbflow:::.assert_character(NULL), "character vector")
})

test_that(".assert_character() error message includes the argument name", {
  bad_labels <- 123L
  expect_error(ukbflow:::.assert_character(bad_labels), "bad_labels")
})


# ===========================================================================
# .assert_data_frame()
# ===========================================================================

test_that(".assert_data_frame() accepts a data.frame", {
  expect_invisible(ukbflow:::.assert_data_frame(data.frame(x = 1)))
})

test_that(".assert_data_frame() accepts a data.table (is also a data.frame)", {
  expect_invisible(
    ukbflow:::.assert_data_frame(data.table::data.table(x = 1))
  )
})

test_that(".assert_data_frame() rejects a plain list", {
  expect_error(ukbflow:::.assert_data_frame(list(x = 1)), "data.frame")
})

test_that(".assert_data_frame() rejects a character string", {
  expect_error(ukbflow:::.assert_data_frame("not a df"), "data.frame")
})

test_that(".assert_data_frame() rejects NULL", {
  expect_error(ukbflow:::.assert_data_frame(NULL), "data.frame")
})

test_that(".assert_data_frame() error message includes the argument name", {
  bad_data <- "oops"
  expect_error(ukbflow:::.assert_data_frame(bad_data), "bad_data")
})


# ===========================================================================
# .assert_data_table()
# ===========================================================================

test_that(".assert_data_table() accepts a data.table", {
  expect_invisible(
    ukbflow:::.assert_data_table(data.table::data.table(x = 1))
  )
})

test_that(".assert_data_table() rejects a plain data.frame", {
  expect_error(
    ukbflow:::.assert_data_table(data.frame(x = 1)), "data.table"
  )
})

test_that(".assert_data_table() rejects a list", {
  expect_error(ukbflow:::.assert_data_table(list(x = 1)), "data.table")
})

test_that(".assert_data_table() rejects NULL", {
  expect_error(ukbflow:::.assert_data_table(NULL), "data.table")
})

test_that(".assert_data_table() error message includes the argument name", {
  bad_dt <- data.frame(x = 1)
  expect_error(ukbflow:::.assert_data_table(bad_dt), "bad_dt")
})


# ===========================================================================
# .assert_has_cols()
# ===========================================================================

test_that(".assert_has_cols() passes when all columns present", {
  dt <- data.table::data.table(a = 1, b = 2, c = 3)
  expect_invisible(ukbflow:::.assert_has_cols(dt, c("a", "b")))
})

test_that(".assert_has_cols() returns data invisibly on success", {
  dt     <- data.table::data.table(a = 1, b = 2)
  result <- ukbflow:::.assert_has_cols(dt, "a")
  expect_identical(result, dt)
})

test_that(".assert_has_cols() aborts with single missing column name", {
  dt <- data.table::data.table(a = 1, b = 2)
  expect_error(ukbflow:::.assert_has_cols(dt, "missing_col"), "missing_col")
})

test_that(".assert_has_cols() reports all missing columns in one error", {
  dt  <- data.table::data.table(a = 1)
  err <- tryCatch(
    ukbflow:::.assert_has_cols(dt, c("b", "c")),
    error = function(e) conditionMessage(e)
  )
  expect_true(grepl("b", err))
  expect_true(grepl("c", err))
})

test_that(".assert_has_cols() passes with zero columns to check", {
  dt <- data.table::data.table(a = 1)
  expect_invisible(ukbflow:::.assert_has_cols(dt, character(0)))
})

test_that(".assert_has_cols() error message includes the data argument name", {
  my_data <- data.frame(x = 1)
  expect_error(ukbflow:::.assert_has_cols(my_data, "missing"), "my_data")
})
