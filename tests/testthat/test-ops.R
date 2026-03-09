# =============================================================================
# test-ops.R — Unit tests for ops_setup() and ops_toy()
#   Focus: input validation, output structure, reproducibility
#   No network, no dx-toolkit required
# =============================================================================


# ===========================================================================
# ops_toy() — input validation
# ===========================================================================

test_that("ops_toy() stops when scenario is invalid", {
  expect_error(ops_toy(scenario = "invalid"), "arg")
})

test_that("ops_toy() stops when n < 1", {
  expect_error(suppressMessages(ops_toy(n = 0)), "positive integer")
})

test_that("ops_toy() stops when n is negative", {
  expect_error(suppressMessages(ops_toy(n = -5)), "positive integer")
})

test_that("ops_toy() accepts n as non-integer numeric (coerced)", {
  expect_no_error(suppressMessages(ops_toy(n = 10.9, seed = 1)))
})


# ===========================================================================
# ops_toy(scenario = "cohort") — output structure
# ===========================================================================

test_that("ops_toy() cohort returns a data.table", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(data.table::is.data.table(dt))
})

test_that("ops_toy() cohort returns correct number of rows", {
  dt <- suppressMessages(ops_toy(n = 200, seed = 1))
  expect_equal(nrow(dt), 200L)
})

test_that("ops_toy() cohort has eid column", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true("eid" %in% names(dt))
})

test_that("ops_toy() cohort has demographics columns", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("p31", "p34", "p53_i0", "p21022") %in% names(dt)))
})

test_that("ops_toy() cohort has covariate columns", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("p21001_i0", "p20116_i0", "p1558_i0",
                     "p21000_i0", "p22189", "p54_i0") %in% names(dt)))
})

test_that("ops_toy() cohort has 10 genetic PC columns", {
  dt   <- suppressMessages(ops_toy(n = 50, seed = 1))
  pcs  <- grep("^p22009_a", names(dt), value = TRUE)
  expect_equal(length(pcs), 10L)
})

test_that("ops_toy() cohort has self-report disease columns (p20002_i0_a0~a4)", {
  dt   <- suppressMessages(ops_toy(n = 50, seed = 1))
  cols <- paste0("p20002_i0_a", 0:4)
  expect_true(all(cols %in% names(dt)))
})

test_that("ops_toy() cohort has self-report date columns (p20008_i0_a0~a4)", {
  dt   <- suppressMessages(ops_toy(n = 50, seed = 1))
  cols <- paste0("p20008_i0_a", 0:4)
  expect_true(all(cols %in% names(dt)))
})

test_that("ops_toy() cohort has HES JSON column p41270", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true("p41270" %in% names(dt))
})

test_that("ops_toy() cohort has HES date columns (p41280_a0~a8)", {
  dt   <- suppressMessages(ops_toy(n = 50, seed = 1))
  cols <- paste0("p41280_a", 0:8)
  expect_true(all(cols %in% names(dt)))
})

test_that("ops_toy() cohort has cancer registry columns", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("p40006_i0", "p40005_i0") %in% names(dt)))
})

test_that("ops_toy() cohort has death registry columns", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("p40001_i0", "p40000_i0",
                     "p40002_i0_a0", "p40002_i0_a1") %in% names(dt)))
})

test_that("ops_toy() cohort has first occurrence column p131742", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true("p131742" %in% names(dt))
})

test_that("ops_toy() cohort has GRS columns", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("grs_bmi", "grs_raw", "grs_finngen") %in% names(dt)))
})

test_that("ops_toy() cohort has messy quality-testing columns", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("messy_allna", "messy_empty", "messy_label") %in% names(dt)))
})

test_that("ops_toy() cohort messy_allna is entirely NA", {
  dt <- suppressMessages(ops_toy(n = 100, seed = 1))
  expect_true(all(is.na(dt$messy_allna)))
})

test_that("ops_toy() cohort p41270 non-NA values are valid JSON arrays", {
  dt   <- suppressMessages(ops_toy(n = 100, seed = 1))
  vals <- dt$p41270[!is.na(dt$p41270)]
  if (length(vals) > 0L) {
    expect_true(all(grepl('^\\[".+\\"]$', vals)))
  }
})

test_that("ops_toy() cohort eid values are unique", {
  dt <- suppressMessages(ops_toy(n = 200, seed = 1))
  expect_equal(length(unique(dt$eid)), 200L)
})

test_that("ops_toy() cohort BMI values are within plausible range", {
  dt <- suppressMessages(ops_toy(n = 500, seed = 1))
  expect_true(all(dt$p21001_i0 >= 12 & dt$p21001_i0 <= 65))
})


# ===========================================================================
# ops_toy(scenario = "forest") — output structure
# ===========================================================================

test_that("ops_toy() forest returns a data.table", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_true(data.table::is.data.table(dt))
})

test_that("ops_toy() forest has required assoc_coxph-style columns", {
  dt   <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  cols <- c("exposure", "term", "model", "n", "n_events",
            "person_years", "HR", "CI_lower", "CI_upper",
            "p_value", "HR_label")
  expect_true(all(cols %in% names(dt)))
})

test_that("ops_toy() forest model column is an ordered factor", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_true(is.factor(dt$model))
  expect_true(is.ordered(dt$model))
})

test_that("ops_toy() forest model factor has 3 levels", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_equal(nlevels(dt$model), 3L)
})

test_that("ops_toy() forest default n=8 produces 8 exposures × 3 models = 24 rows", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_equal(nrow(dt), 24L)
})

test_that("ops_toy() forest n=3 produces 3 exposures × 3 models = 9 rows", {
  dt <- suppressMessages(ops_toy(scenario = "forest", n = 3, seed = 1))
  expect_equal(nrow(dt), 9L)
})

test_that("ops_toy() forest HR values are positive", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_true(all(dt$HR > 0))
  expect_true(all(dt$CI_lower > 0))
  expect_true(all(dt$CI_upper > 0))
})

test_that("ops_toy() forest CI_lower < HR < CI_upper for all rows", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_true(all(dt$CI_lower < dt$HR))
  expect_true(all(dt$HR < dt$CI_upper))
})

test_that("ops_toy() forest p_value is in [0, 1]", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_true(all(dt$p_value >= 0 & dt$p_value <= 1))
})

test_that("ops_toy() forest HR_label matches 'x.xx (x.xx-x.xx)' pattern", {
  dt <- suppressMessages(ops_toy(scenario = "forest", seed = 1))
  expect_true(all(grepl("^[0-9.]+\\s\\([0-9.]+-[0-9.]+\\)$", dt$HR_label)))
})


# ===========================================================================
# ops_toy() — reproducibility and seed handling
# ===========================================================================

test_that("ops_toy() produces identical output with same seed", {
  dt1 <- suppressMessages(ops_toy(n = 100, seed = 42))
  dt2 <- suppressMessages(ops_toy(n = 100, seed = 42))
  expect_identical(dt1, dt2)
})

test_that("ops_toy() produces different output with different seeds", {
  dt1 <- suppressMessages(ops_toy(n = 100, seed = 1))
  dt2 <- suppressMessages(ops_toy(n = 100, seed = 2))
  expect_false(identical(dt1$p21001_i0, dt2$p21001_i0))
})

test_that("ops_toy() with seed=NULL does not error", {
  expect_no_error(suppressMessages(ops_toy(n = 50, seed = NULL)))
})


# ===========================================================================
# ops_setup() — output structure (no dx / no RAP required)
# ===========================================================================

test_that("ops_setup() returns an invisible list", {
  result <- suppressMessages(ops_setup(verbose = FALSE))
  expect_true(is.list(result))
})

test_that("ops_setup() result has a summary element", {
  result <- suppressMessages(ops_setup(verbose = FALSE))
  expect_true("summary" %in% names(result))
})

test_that("ops_setup() summary has pass / warn / fail fields", {
  result  <- suppressMessages(ops_setup(verbose = FALSE))
  summary <- result$summary
  expect_true(all(c("pass", "warn", "fail") %in% names(summary)))
})

test_that("ops_setup() summary counts are non-negative integers", {
  result  <- suppressMessages(ops_setup(verbose = FALSE))
  summary <- result$summary
  expect_true(summary$pass >= 0L)
  expect_true(summary$warn >= 0L)
  expect_true(summary$fail >= 0L)
})

test_that("ops_setup() check_deps=FALSE omits deps from result", {
  result <- suppressMessages(ops_setup(check_deps = FALSE, verbose = FALSE))
  expect_null(result$deps)
})

test_that("ops_setup() check_dx=FALSE omits dx from result", {
  result <- suppressMessages(ops_setup(check_dx = FALSE, verbose = FALSE))
  expect_null(result$dx)
})

test_that("ops_setup() check_auth=FALSE omits auth from result", {
  result <- suppressMessages(ops_setup(check_auth = FALSE, verbose = FALSE))
  expect_null(result$auth)
})

test_that("ops_setup() deps result is a list of named lists", {
  result <- suppressMessages(
    ops_setup(check_dx = FALSE, check_auth = FALSE, verbose = FALSE)
  )
  deps <- result$deps
  expect_true(is.list(deps))
  expect_true(all(vapply(deps, function(d) "package" %in% names(d), logical(1))))
  expect_true(all(vapply(deps, function(d) "installed" %in% names(d), logical(1))))
})

test_that("ops_setup() known installed packages (cli, data.table) show installed=TRUE", {
  result <- suppressMessages(
    ops_setup(check_dx = FALSE, check_auth = FALSE, verbose = FALSE)
  )
  pkgs <- vapply(result$deps, `[[`, "", "package")
  installed <- vapply(result$deps, `[[`, TRUE, "installed")

  cli_ok        <- installed[pkgs == "cli"]
  datatable_ok  <- installed[pkgs == "data.table"]

  expect_true(length(cli_ok) > 0L && isTRUE(cli_ok))
  expect_true(length(datatable_ok) > 0L && isTRUE(datatable_ok))
})

test_that("ops_setup() verbose=FALSE produces no messages", {
  expect_no_message(
    ops_setup(check_dx = FALSE, check_auth = FALSE, verbose = FALSE)
  )
})


# ===========================================================================
# .ops_check_deps() — internal helper
# ===========================================================================

test_that(".ops_check_deps() returns a list", {
  result <- ukbflow:::.ops_check_deps()
  expect_true(is.list(result))
})

test_that(".ops_check_deps() each entry has required fields", {
  result <- ukbflow:::.ops_check_deps()
  for (d in result) {
    expect_true(all(c("package", "required", "group", "installed", "version") %in% names(d)))
  }
})

test_that(".ops_check_deps() installed is logical for each entry", {
  result <- ukbflow:::.ops_check_deps()
  for (d in result) {
    expect_true(is.logical(d$installed))
  }
})

test_that(".ops_check_deps() version is character or NA for each entry", {
  result <- ukbflow:::.ops_check_deps()
  for (d in result) {
    expect_true(is.na(d$version) || is.character(d$version))
  }
})


# ===========================================================================
# ops_na() — input validation
# ===========================================================================

test_that("ops_na() aborts on non-data.frame input", {
  expect_error(ops_na("not a df"), "data.frame")
})

test_that("ops_na() aborts on 0-row data", {
  expect_error(ops_na(data.frame(x = integer(0))), "0 rows")
})

test_that("ops_na() aborts when threshold < 0", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(suppressMessages(ops_na(dt, threshold = -1)), "threshold")
})

test_that("ops_na() aborts when threshold >= 100", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(suppressMessages(ops_na(dt, threshold = 100)), "threshold")
})

test_that("ops_na() aborts on invalid verbose", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(suppressMessages(ops_na(dt, verbose = "yes")), "verbose")
})


# ===========================================================================
# ops_na() — output structure
# ===========================================================================

test_that("ops_na() returns a data.table invisibly", {
  dt     <- suppressMessages(ops_toy(n = 50, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_true(data.table::is.data.table(result))
})

test_that("ops_na() result has columns: column, n_na, pct_na", {
  dt     <- suppressMessages(ops_toy(n = 50, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_true(all(c("column", "n_na", "pct_na") %in% names(result)))
})

test_that("ops_na() returns one row per column in data", {
  dt     <- suppressMessages(ops_toy(n = 50, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_equal(nrow(result), ncol(dt))
})

test_that("ops_na() result is sorted by pct_na descending", {
  dt     <- suppressMessages(ops_toy(n = 50, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_true(all(diff(result$pct_na) <= 0))
})

test_that("ops_na() pct_na values are in [0, 100]", {
  dt     <- suppressMessages(ops_toy(n = 50, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_true(all(result$pct_na >= 0 & result$pct_na <= 100))
})

test_that("ops_na() n_na is non-negative integer", {
  dt     <- suppressMessages(ops_toy(n = 50, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_true(all(result$n_na >= 0L))
  expect_true(is.integer(result$n_na))
})

test_that("ops_na() messy_allna column shows 100% missing", {
  dt     <- suppressMessages(ops_toy(n = 100, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_equal(result[column == "messy_allna", pct_na], 100)
})

test_that("ops_na() complete numeric column shows 0% missing", {
  dt     <- suppressMessages(ops_toy(n = 100, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  expect_equal(result[column == "p21001_i0", pct_na], 0)
})

test_that("ops_na() counts empty strings as missing", {
  dt     <- suppressMessages(ops_toy(n = 200, seed = 1))
  result <- suppressMessages(ops_na(dt, verbose = FALSE))
  # messy_empty contains "" and NA — both counted as missing
  expect_gt(result[column == "messy_empty", n_na], 0L)
})

test_that("ops_na() threshold does not affect returned data.table", {
  dt      <- suppressMessages(ops_toy(n = 100, seed = 1))
  res0    <- suppressMessages(ops_na(dt, threshold = 0,  verbose = FALSE))
  res50   <- suppressMessages(ops_na(dt, threshold = 50, verbose = FALSE))
  expect_equal(nrow(res0), nrow(res50))
  expect_identical(res0, res50)
})

test_that("ops_na() verbose=FALSE produces no messages", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_no_message(ops_na(dt, verbose = FALSE))
})


# ===========================================================================
# ops_snapshot() — input validation
# ===========================================================================

test_that("ops_snapshot() aborts on non-data.frame data", {
  expect_error(ops_snapshot("not a df"), "data.frame")
})

test_that("ops_snapshot() aborts on invalid label", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(suppressMessages(ops_snapshot(dt, label = 123)), "label")
})

test_that("ops_snapshot() aborts on empty string label", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(suppressMessages(ops_snapshot(dt, label = "")), "label")
})

test_that("ops_snapshot() aborts on invalid verbose", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(suppressMessages(ops_snapshot(dt, verbose = "yes")), "verbose")
})


# ===========================================================================
# ops_snapshot() — record and history
# ===========================================================================

test_that("ops_snapshot() reset clears history", {
  suppressMessages(ops_snapshot(reset = TRUE))
  suppressMessages(ops_snapshot(suppressMessages(ops_toy(n = 50, seed = 1)),
                                label = "x", verbose = FALSE))
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  history <- suppressMessages(ops_snapshot(verbose = FALSE))
  expect_null(history)
})

test_that("ops_snapshot() records a new row each call", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "s1", verbose = FALSE))
  suppressMessages(ops_snapshot(dt, label = "s2", verbose = FALSE))
  history <- suppressMessages(ops_snapshot(verbose = FALSE))
  expect_equal(nrow(history), 2L)
})

test_that("ops_snapshot() result has expected columns", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  row <- suppressMessages(ops_snapshot(dt, label = "test", verbose = FALSE))
  expect_true(all(c("idx", "label", "timestamp",
                    "nrow", "ncol", "n_na_cols", "size_mb") %in% names(row)))
})

test_that("ops_snapshot() auto-labels as snapshot_N when label omitted", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt  <- suppressMessages(ops_toy(n = 50, seed = 1))
  row <- suppressMessages(ops_snapshot(dt, verbose = FALSE))
  expect_equal(row$label, "snapshot_1")
})

test_that("ops_snapshot() nrow and ncol match input data", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt  <- suppressMessages(ops_toy(n = 200, seed = 1))
  row <- suppressMessages(ops_snapshot(dt, label = "chk", verbose = FALSE))
  expect_equal(row$nrow, 200L)
  expect_equal(row$ncol, ncol(dt))
})

test_that("ops_snapshot() idx increments sequentially", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "a", verbose = FALSE))
  suppressMessages(ops_snapshot(dt, label = "b", verbose = FALSE))
  suppressMessages(ops_snapshot(dt, label = "c", verbose = FALSE))
  history <- suppressMessages(ops_snapshot(verbose = FALSE))
  expect_equal(history$idx, 1:3)
})

test_that("ops_snapshot() verbose=FALSE produces no messages when recording", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_no_message(ops_snapshot(dt, label = "quiet", verbose = FALSE))
})

test_that("ops_snapshot() warns when no history and no data supplied", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  expect_message(ops_snapshot(verbose = TRUE), "No snapshots")
})
