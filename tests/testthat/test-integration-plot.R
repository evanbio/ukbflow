# =============================================================================
# test-integration-plot.R — Integration tests for plot_forest() and plot_tableone()
#   These tests call the full function pipeline end-to-end.
#   plot_forest() requires an open graphics device (grid layout computation).
# =============================================================================


# ===========================================================================
# Shared helpers
# ===========================================================================

.fake_forest_df <- function() {
  data.frame(
    item    = c("AD vs control", "Crude", "Adjusted"),
    cases_n = c("", "89/4521", "89/4521"),
    stringsAsFactors = FALSE
  )
}

.fake_t1_df <- function(n = 120, seed = 42) {
  set.seed(seed)
  data.frame(
    age = round(rnorm(n, 57, 8), 1),
    sex = factor(sample(c("Male", "Female"), n, TRUE)),
    bmi = round(rnorm(n, 27, 5), 1),
    trt = factor(sample(c("Drug A", "Drug B"), n, TRUE)),
    stringsAsFactors = FALSE
  )
}

# Open a temporary PDF device and close it on exit.
# Returns the temp file path (for cleanup).
.open_pdf_device <- function() {
  tmp <- tempfile(fileext = ".pdf")
  grDevices::pdf(tmp, width = 12, height = 8)
  tmp
}

.close_pdf_device <- function(tmp) {
  try(grDevices::dev.off(), silent = TRUE)
  unlink(tmp)
}


# ===========================================================================
# plot_forest() — end-to-end
# ===========================================================================

test_that("plot_forest() returns an invisible gtable-like object", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  p <- suppressMessages(
    plot_forest(
      data  = df,
      est   = c(NA, 1.52, 1.43),
      lower = c(NA, 1.18, 1.11),
      upper = c(NA, 1.96, 1.85)
    )
  )
  # forestploter::forest() returns a gtable (list-based S3)
  expect_true(is.list(p))
  expect_true(!is.null(p$grobs) || !is.null(p$heights))
})

test_that("plot_forest() accepts ci_column = 3 with extra column", {
  df <- data.frame(
    item    = c("Group", "Crude", "Adjusted"),
    cases_n = c("", "45/800", "45/800"),
    p_value = c(NA_real_, 0.031, 0.004),
    stringsAsFactors = FALSE
  )
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data      = df,
        est       = c(NA, 1.30, 1.25),
        lower     = c(NA, 1.05, 1.01),
        upper     = c(NA, 1.60, 1.55),
        ci_column = 3L,
        p_cols    = "p_value"
      )
    )
  )
})

test_that("plot_forest() works with indent and bold_label", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data       = df,
        est        = c(NA, 1.52, 1.43),
        lower      = c(NA, 1.18, 1.11),
        upper      = c(NA, 1.96, 1.85),
        indent     = c(0L, 1L, 1L),
        bold_label = c(TRUE, FALSE, FALSE)
      )
    )
  )
})

test_that("plot_forest() works with xlim and ticks_at", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data     = df,
        est      = c(NA, 1.52, 1.43),
        lower    = c(NA, 1.18, 1.11),
        upper    = c(NA, 1.96, 1.85),
        xlim     = c(0.5, 3.0),
        ticks_at = c(0.5, 1.0, 2.0, 3.0)
      )
    )
  )
})

test_that("plot_forest() works with ref_line = 0 (beta coefficients)", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data     = df,
        est      = c(NA, 0.42, 0.38),
        lower    = c(NA, 0.15, 0.10),
        upper    = c(NA, 0.69, 0.66),
        ref_line = 0
      )
    )
  )
})

test_that("plot_forest() works with background = 'bold_label'", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data       = df,
        est        = c(NA, 1.52, 1.43),
        lower      = c(NA, 1.18, 1.11),
        upper      = c(NA, 1.96, 1.85),
        indent     = c(0L, 1L, 1L),
        background = "bold_label"
      )
    )
  )
})

test_that("plot_forest() works with background = 'none' and border = 'none'", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data       = df,
        est        = c(NA, 1.52, 1.43),
        lower      = c(NA, 1.18, 1.11),
        upper      = c(NA, 1.96, 1.85),
        background = "none",
        border     = "none"
      )
    )
  )
})

test_that("plot_forest() works with per-row ci_col vector", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data   = df,
        est    = c(NA, 1.52, 1.43),
        lower  = c(NA, 1.18, 1.11),
        upper  = c(NA, 1.96, 1.85),
        ci_col = c(NA, "steelblue", "tomato")
      )
    )
  )
})

test_that("plot_forest() works with custom row_height scalar", {
  df  <- .fake_forest_df()
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data       = df,
        est        = c(NA, 1.52, 1.43),
        lower      = c(NA, 1.18, 1.11),
        upper      = c(NA, 1.96, 1.85),
        row_height = 10
      )
    )
  )
})

test_that("plot_forest() with p_cols bold_p = FALSE skips bolding", {
  df <- data.frame(
    item    = c("Group", "Crude", "Adjusted"),
    p_value = c(NA_real_, 0.001, 0.220),
    stringsAsFactors = FALSE
  )
  tmp <- .open_pdf_device()
  on.exit(.close_pdf_device(tmp), add = TRUE)

  expect_no_error(
    suppressMessages(
      plot_forest(
        data   = df,
        est    = c(NA, 1.52, 1.43),
        lower  = c(NA, 1.18, 1.11),
        upper  = c(NA, 1.96, 1.85),
        p_cols = "p_value",
        bold_p = FALSE
      )
    )
  )
})


# ===========================================================================
# plot_tableone() — end-to-end
# ===========================================================================

test_that("plot_tableone() returns a gt table object", {
  df  <- .fake_t1_df()
  res <- suppressMessages(suppressWarnings(
    plot_tableone(df, vars = c("age", "sex", "bmi"), save = FALSE)
  ))
  expect_true(inherits(res, "gt_tbl"))
})

test_that("plot_tableone() works with strata and add_p = TRUE", {
  df  <- .fake_t1_df()
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars   = c("age", "bmi"),
        strata = "trt",
        add_p  = TRUE,
        save   = FALSE
      )
    ))
  )
})

test_that("plot_tableone() works with add_smd = TRUE", {
  df  <- .fake_t1_df()
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars    = c("age", "sex", "bmi"),
        strata  = "trt",
        add_smd = TRUE,
        save    = FALSE
      )
    ))
  )
})

test_that("plot_tableone() works with overall = TRUE", {
  df  <- .fake_t1_df()
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars    = c("age", "bmi"),
        strata  = "trt",
        overall = TRUE,
        save    = FALSE
      )
    ))
  )
})

test_that("plot_tableone() works without strata (unstratified)", {
  df  <- .fake_t1_df()
  res <- suppressMessages(suppressWarnings(
    plot_tableone(df, vars = c("age", "bmi"), strata = NULL, save = FALSE)
  ))
  expect_true(inherits(res, "gt_tbl"))
})

test_that("plot_tableone() works with custom label list", {
  df  <- .fake_t1_df()
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars   = c("age", "sex"),
        strata = "trt",
        label  = list(age ~ "Age (years)", sex ~ "Sex"),
        save   = FALSE
      )
    ))
  )
})

test_that("plot_tableone() works with exclude_labels", {
  df  <- .fake_t1_df()
  # sex has levels Male / Female; exclude "Female" level row
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars           = c("age", "sex"),
        strata         = "trt",
        exclude_labels = "Female",
        save           = FALSE
      )
    ))
  )
})

test_that("plot_tableone() works with missing = 'ifany'", {
  df      <- .fake_t1_df()
  df$age[sample(nrow(df), 10)] <- NA
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars    = c("age", "bmi"),
        strata  = "trt",
        missing = "ifany",
        save    = FALSE
      )
    ))
  )
})

test_that("plot_tableone() with all options combined does not error", {
  df  <- .fake_t1_df()
  expect_no_error(
    suppressMessages(suppressWarnings(
      plot_tableone(
        df,
        vars    = c("age", "sex", "bmi"),
        strata  = "trt",
        add_p   = TRUE,
        add_smd = TRUE,
        overall = TRUE,
        label   = list(age ~ "Age (years)", bmi ~ "BMI (kg/m\u00b2)"),
        save    = FALSE
      )
    ))
  )
})
