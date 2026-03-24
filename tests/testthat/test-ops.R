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
  expect_error(suppressMessages(ops_toy(n = 0)), "integer")
})

test_that("ops_toy() stops when n is negative", {
  expect_error(suppressMessages(ops_toy(n = -5)), "integer")
})

test_that("ops_toy() rejects non-integer numeric n", {
  expect_error(suppressMessages(ops_toy(n = 10.9, seed = 1)), "integer")
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

test_that("ops_toy() cohort has self-report cancer columns (p20001_i0_a0~a4 and p20006_i0_a0~a4)", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(paste0("p20001_i0_a", 0:4) %in% names(dt)))
  expect_true(all(paste0("p20006_i0_a", 0:4) %in% names(dt)))
})

test_that("ops_toy() cohort has cancer registry columns (3 instances, icd/hist/behv/date)", {
  dt   <- suppressMessages(ops_toy(n = 50, seed = 1))
  cols <- c(paste0("p40006_i", 0:2), paste0("p40011_i", 0:2),
            paste0("p40012_i", 0:2), paste0("p40005_i", 0:2))
  expect_true(all(cols %in% names(dt)))
})

test_that("ops_toy() cohort has death registry columns (primary + 3 secondary + date)", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_true(all(c("p40001_i0", "p40000_i0",
                    "p40002_i0_a0", "p40002_i0_a1", "p40002_i0_a2") %in% names(dt)))
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
# ops_setup() — branch behaviour via stubbed internal helpers
# ===========================================================================

test_that("ops_setup() dx not found → summary$fail >= 1", {
  local_mocked_bindings(
    .ops_check_dx   = function() list(ok = FALSE, path = NA_character_, version = NA_character_),
    .ops_check_auth = function() list(ok = FALSE, logged_in = FALSE,
                                      user = NA_character_, project = NA_character_),
    .package = "ukbflow"
  )
  result <- suppressMessages(ops_setup(check_deps = FALSE, verbose = FALSE))
  expect_gte(result$summary$fail, 1L)
})

test_that("ops_setup() dx found + auth ok → summary$pass >= 2, fail == 0", {
  local_mocked_bindings(
    .ops_check_dx   = function() list(ok = TRUE, path = "/usr/bin/dx", version = "0.350.0"),
    .ops_check_auth = function() list(ok = TRUE, logged_in = TRUE,
                                      user = "testuser", project = "project-abc123"),
    .package = "ukbflow"
  )
  result <- suppressMessages(ops_setup(check_deps = FALSE, verbose = FALSE))
  expect_gte(result$summary$pass, 2L)
  expect_equal(result$summary$fail, 0L)
})

test_that("ops_setup() dx found but not logged in → summary$warn >= 1, fail == 0", {
  local_mocked_bindings(
    .ops_check_dx   = function() list(ok = TRUE, path = "/usr/bin/dx", version = "0.350.0"),
    .ops_check_auth = function() list(ok = FALSE, logged_in = FALSE,
                                      user = NA_character_, project = NA_character_),
    .package = "ukbflow"
  )
  result <- suppressMessages(ops_setup(check_deps = FALSE, verbose = FALSE))
  expect_gte(result$summary$warn, 1L)
  expect_equal(result$summary$fail, 0L)   # auth failure is warn, not fail
})

test_that("ops_setup() auth ok but no project selected → summary$pass for auth, warning message", {
  local_mocked_bindings(
    .ops_check_dx   = function() list(ok = TRUE, path = "/usr/bin/dx", version = "0.350.0"),
    .ops_check_auth = function() list(ok = TRUE, logged_in = TRUE,
                                      user = "testuser", project = NA_character_),
    .package = "ukbflow"
  )
  result <- suppressMessages(ops_setup(check_deps = FALSE, verbose = FALSE))
  expect_gte(result$summary$pass, 2L)   # dx + auth both pass
})

test_that("ops_setup() summary pass + warn + fail sum matches checked items", {
  local_mocked_bindings(
    .ops_check_dx   = function() list(ok = TRUE, path = "/usr/bin/dx", version = "0.350.0"),
    .ops_check_auth = function() list(ok = TRUE, logged_in = TRUE,
                                      user = "testuser", project = "project-abc123"),
    .package = "ukbflow"
  )
  result <- suppressMessages(ops_setup(check_deps = FALSE, verbose = FALSE))
  s <- result$summary
  # With check_deps=FALSE: dx (pass) + auth (pass) = 2 items checked
  expect_equal(s$pass + s$warn + s$fail, 2L)
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


# ===========================================================================
# ops_withdraw() — input validation
# ===========================================================================

test_that("ops_withdraw() aborts on non-data.frame input", {
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("1234567", wfile)
  expect_error(ops_withdraw("not a df", file = wfile), "data.frame")
})

test_that("ops_withdraw() aborts when file does not exist", {
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  expect_error(ops_withdraw(dt, file = "nonexistent.csv"), "not found")
})

test_that("ops_withdraw() aborts when eid_col not in data", {
  dt    <- suppressMessages(ops_toy(n = 50, seed = 1))
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("1234567", wfile)
  expect_error(
    suppressMessages(ops_withdraw(dt, file = wfile, eid_col = "wrong_col")),
    "wrong_col"
  )
})

test_that("ops_withdraw() aborts on invalid verbose", {
  dt    <- suppressMessages(ops_toy(n = 50, seed = 1))
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("1234567", wfile)
  expect_error(
    suppressMessages(ops_withdraw(dt, file = wfile, verbose = "yes")),
    "verbose"
  )
})


# ===========================================================================
# ops_withdraw() — expected use
# ===========================================================================

test_that("ops_withdraw() returns a data.table", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt    <- suppressMessages(ops_toy(n = 100, seed = 1))
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("9999999", wfile)  # eid not in toy data
  result <- suppressMessages(ops_withdraw(dt, file = wfile, verbose = FALSE))
  expect_true(data.table::is.data.table(result))
})

test_that("ops_withdraw() removes 0 rows when no eid matches", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt    <- suppressMessages(ops_toy(n = 100, seed = 1))
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("9999999", wfile)
  result <- suppressMessages(ops_withdraw(dt, file = wfile, verbose = FALSE))
  expect_equal(nrow(result), 100L)
})

test_that("ops_withdraw() removes matched eids correctly", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt         <- suppressMessages(ops_toy(n = 100, seed = 1))
  inject_ids <- dt$eid[1:3]
  wfile      <- withr::local_tempfile(fileext = ".csv")
  writeLines(as.character(inject_ids), wfile)
  result <- suppressMessages(ops_withdraw(dt, file = wfile, verbose = FALSE))
  expect_equal(nrow(result), 97L)
  expect_false(any(result$eid %in% inject_ids))
})

test_that("ops_withdraw() works with custom eid_col", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 100, seed = 1))
  data.table::setnames(dt, "eid", "participant_id")
  inject_ids <- dt$participant_id[1:2]
  wfile      <- withr::local_tempfile(fileext = ".csv")
  writeLines(as.character(inject_ids), wfile)
  result <- suppressMessages(
    ops_withdraw(dt, file = wfile, eid_col = "participant_id", verbose = FALSE)
  )
  expect_equal(nrow(result), 98L)
  expect_false(any(result$participant_id %in% inject_ids))
})

test_that("ops_withdraw() records two snapshots in session history", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt    <- suppressMessages(ops_toy(n = 100, seed = 1))
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("9999999", wfile)
  suppressMessages(ops_withdraw(dt, file = wfile, verbose = FALSE))
  history <- suppressMessages(ops_snapshot(verbose = FALSE))
  expect_equal(nrow(history), 2L)
  expect_equal(history$label, c("before_withdraw", "after_withdraw"))
})

test_that("ops_withdraw() verbose=FALSE produces no messages", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt    <- suppressMessages(ops_toy(n = 50, seed = 1))
  wfile <- withr::local_tempfile(fileext = ".csv")
  writeLines("9999999", wfile)
  expect_no_message(ops_withdraw(dt, file = wfile, verbose = FALSE))
})


# ===========================================================================
# ops_snapshot() — check_na = FALSE
# ===========================================================================

test_that("ops_snapshot() check_na=FALSE sets n_na_cols to NA", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt  <- suppressMessages(ops_toy(n = 50, seed = 1))
  row <- suppressMessages(
    ops_snapshot(dt, label = "nochk", verbose = FALSE, check_na = FALSE)
  )
  expect_true(is.na(row$n_na_cols))
})


# ===========================================================================
# ops_snapshot_cols() — input validation and expected use
# ===========================================================================

test_that("ops_snapshot_cols() aborts on non-string label", {
  expect_error(ops_snapshot_cols(123), "label")
})

test_that("ops_snapshot_cols() aborts when label not found in cache", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  expect_error(ops_snapshot_cols("nonexistent"), "nonexistent")
})

test_that("ops_snapshot_cols() returns a character vector", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  cols <- ops_snapshot_cols("raw")
  expect_type(cols, "character")
  expect_gt(length(cols), 0L)
})

test_that("ops_snapshot_cols() always excludes built-in safe col eid", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  expect_false("eid" %in% ops_snapshot_cols("raw"))
})

test_that("ops_snapshot_cols() keep excludes additional columns", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  cols <- ops_snapshot_cols("raw", keep = "p31")
  expect_false("p31" %in% cols)
})

test_that("ops_snapshot_cols() keep=NULL returns all non-protected columns", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  cols_no_keep   <- ops_snapshot_cols("raw")
  cols_with_keep <- ops_snapshot_cols("raw", keep = "p31")
  expect_gt(length(cols_no_keep), length(cols_with_keep))
})


# ===========================================================================
# ops_snapshot_diff() — input validation and expected use
# ===========================================================================

test_that("ops_snapshot_diff() aborts on non-string label1", {
  expect_error(suppressMessages(ops_snapshot_diff(123, "b")), "label1")
})

test_that("ops_snapshot_diff() aborts on non-string label2", {
  expect_error(suppressMessages(ops_snapshot_diff("a", 123)), "label2")
})

test_that("ops_snapshot_diff() aborts when label not found in cache", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  expect_error(suppressMessages(ops_snapshot_diff("raw", "derived")), "raw")
})

test_that("ops_snapshot_diff() returns list with added and removed", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt1 <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt1, label = "before", verbose = FALSE))
  dt2 <- data.table::copy(dt1)
  dt2[, derived_col := 1L]
  dt2[, p31 := NULL]
  suppressMessages(ops_snapshot(dt2, label = "after", verbose = FALSE))
  result <- suppressMessages(ops_snapshot_diff("before", "after"))
  expect_true("derived_col" %in% result$added)
  expect_true("p31" %in% result$removed)
})

test_that("ops_snapshot_diff() reports empty vectors when snapshots are identical", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "s1", verbose = FALSE))
  suppressMessages(ops_snapshot(dt, label = "s2", verbose = FALSE))
  result <- suppressMessages(ops_snapshot_diff("s1", "s2"))
  expect_equal(length(result$added),   0L)
  expect_equal(length(result$removed), 0L)
})


# ===========================================================================
# ops_snapshot_remove() — input validation and expected use
# ===========================================================================

test_that("ops_snapshot_remove() aborts on non-data.frame input", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  expect_error(ops_snapshot_remove("not a df", from = "raw"), "data.frame")
})

test_that("ops_snapshot_remove() aborts on non-string from", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  expect_error(ops_snapshot_remove(dt, from = 123), "from")
})

test_that("ops_snapshot_remove() returns a data.table", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  dt2 <- data.table::copy(dt)
  dt2[, derived_col := 1L]
  result <- suppressMessages(ops_snapshot_remove(dt2, from = "raw", verbose = FALSE))
  expect_true(data.table::is.data.table(result))
})

test_that("ops_snapshot_remove() drops raw columns and retains derived columns", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  dt2 <- data.table::copy(dt)
  dt2[, derived_col := 1L]
  result <- suppressMessages(ops_snapshot_remove(dt2, from = "raw", verbose = FALSE))
  expect_true("derived_col" %in% names(result))
  expect_false("p31" %in% names(result))
})

test_that("ops_snapshot_remove() always protects eid", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  result <- suppressMessages(ops_snapshot_remove(
    data.table::copy(dt), from = "raw", verbose = FALSE
  ))
  expect_true("eid" %in% names(result))
})

test_that("ops_snapshot_remove() keep protects additional columns", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- suppressMessages(ops_toy(n = 50, seed = 1))
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  result <- suppressMessages(ops_snapshot_remove(
    data.table::copy(dt), from = "raw", keep = "p31", verbose = FALSE
  ))
  expect_true("p31" %in% names(result))
})

test_that("ops_snapshot_remove() accepts data.frame input and returns data.table without modifying original", {
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  df <- as.data.frame(suppressMessages(ops_toy(n = 50, seed = 1)))
  suppressMessages(ops_snapshot(df, label = "raw", verbose = FALSE))
  result <- suppressMessages(ops_snapshot_remove(df, from = "raw", verbose = FALSE))
  expect_true(data.table::is.data.table(result))
  expect_false(data.table::is.data.table(df))
})


# ===========================================================================
# ops_set_safe_cols() — input validation and expected use
# ===========================================================================

test_that("ops_set_safe_cols() aborts on non-character cols", {
  expect_error(ops_set_safe_cols(cols = 123), "cols")
})

test_that("ops_set_safe_cols() aborts on invalid reset", {
  expect_error(ops_set_safe_cols(reset = "yes"), "reset")
})

test_that("ops_set_safe_cols() registered cols are protected in ops_snapshot_cols()", {
  suppressMessages(ops_set_safe_cols(reset = TRUE))
  suppressMessages(ops_set_safe_cols(cols = "my_safe_col"))
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- data.table::data.table(eid = 1L, my_safe_col = 1L, other_col = 1L)
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  cols <- ops_snapshot_cols("raw")
  expect_false("my_safe_col" %in% cols)
  expect_true("other_col"  %in% cols)
  suppressMessages(ops_set_safe_cols(reset = TRUE))
})

test_that("ops_set_safe_cols() reset clears registered cols", {
  suppressMessages(ops_set_safe_cols(cols = "tmp_col"))
  suppressMessages(ops_set_safe_cols(reset = TRUE))
  suppressMessages(ops_snapshot(reset = TRUE, verbose = FALSE))
  dt <- data.table::data.table(eid = 1L, tmp_col = 1L)
  suppressMessages(ops_snapshot(dt, label = "raw", verbose = FALSE))
  cols <- ops_snapshot_cols("raw")
  expect_true("tmp_col" %in% cols)
})
