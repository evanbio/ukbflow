# =============================================================================
# test-decode.R — Unit tests for decode_ series (no network, no real files)
# =============================================================================

# ===========================================================================
# Shared helpers
# ===========================================================================

.fake_fields_decode <- function() {
  data.frame(
    field_name = c(
      "participant.eid",
      "participant.p31",
      "participant.p53_i0", "participant.p53_i1",
      "participant.p22189",
      "participant.p20002_i0_a0",
      "participant.p22009_a1"
    ),
    title = c(
      "Participant ID",
      "Sex",
      "Date of attending assessment centre | Instance 0",
      "Date of attending assessment centre | Instance 1",
      "Townsend deprivation index at recruitment",
      "Non-cancer illness code, self-reported | Instance 0 | Array 0",
      "Genetic principal components | Array 1"
    ),
    stringsAsFactors = FALSE
  )
}

.fake_field_meta <- function() {
  data.frame(
    field_id    = c(31L, 21000L, 20116L, 21022L, 22189L, 53L),
    value_type  = c(21L, 21L,    21L,    31L,    31L,    51L),
    encoding_id = c(9L,  1001L,  90L,    0L,     0L,     0L),
    stringsAsFactors = FALSE
  )
}

.fake_esimpint <- function() {
  data.frame(
    encoding_id = c(9L,  9L,    90L,     90L,        90L),
    value       = c(0L,  1L,    0L,      1L,          2L),
    meaning     = c("Female", "Male", "Never", "Previous", "Current"),
    stringsAsFactors = FALSE
  )
}

.set_decode_cache <- function() {
  .ukbflow_cache$fields     <- .fake_fields_decode()
  .ukbflow_cache$field_meta <- .fake_field_meta()
  .ukbflow_cache$esimpint   <- .fake_esimpint()
}

.clear_decode_cache <- function() {
  .ukbflow_cache$fields     <- NULL
  .ukbflow_cache$field_meta <- NULL
  .ukbflow_cache$esimpint   <- NULL
}


# ===========================================================================
# .title_to_snake() — pure function
# ===========================================================================

test_that(".title_to_snake() handles simple title", {
  expect_equal(ukbflow:::.title_to_snake("Sex"), "sex")
})

test_that(".title_to_snake() converts spaces and special chars to underscores", {
  expect_equal(
    ukbflow:::.title_to_snake("Townsend deprivation index at recruitment"),
    "townsend_deprivation_index_at_recruitment"
  )
})

test_that(".title_to_snake() appends instance suffix", {
  result <- ukbflow:::.title_to_snake(
    "Date of attending assessment centre | Instance 0"
  )
  expect_true(endsWith(result, "_i0"))
  expect_true(startsWith(result, "date_of_attending"))
})

test_that(".title_to_snake() appends array suffix", {
  result <- ukbflow:::.title_to_snake("Genetic principal components | Array 1")
  expect_true(endsWith(result, "_a1"))
  expect_true(startsWith(result, "genetic_principal"))
})

test_that(".title_to_snake() handles both instance and array suffixes", {
  result <- ukbflow:::.title_to_snake(
    "Non-cancer illness code, self-reported | Instance 0 | Array 1"
  )
  expect_true(grepl("_i0_a1$", result))
})

test_that(".title_to_snake() strips leading and trailing underscores from base", {
  # Titles starting with special chars should not produce leading underscores
  result <- ukbflow:::.title_to_snake("Age at recruitment")
  expect_false(startsWith(result, "_"))
  expect_false(endsWith(result, "_"))
})


# ===========================================================================
# .extract_field_id() — pure function
# ===========================================================================

test_that(".extract_field_id() extracts field_id from participant.pXXXX", {
  expect_equal(ukbflow:::.extract_field_id("participant.p31"), 31L)
})

test_that(".extract_field_id() extracts field_id from pXXXX", {
  expect_equal(ukbflow:::.extract_field_id("p31"), 31L)
})

test_that(".extract_field_id() extracts field_id from pXXXX_iX_aX", {
  expect_equal(ukbflow:::.extract_field_id("p20002_i0_a1"), 20002L)
})

test_that(".extract_field_id() returns NA for eid column", {
  expect_true(is.na(ukbflow:::.extract_field_id("eid")))
})

test_that(".extract_field_id() returns NA for non-UKB column name", {
  expect_true(is.na(ukbflow:::.extract_field_id("my_column")))
})


# ===========================================================================
# .build_name_map() — pure function
# ===========================================================================

test_that(".build_name_map() maps participant.eid to eid", {
  result <- ukbflow:::.build_name_map("participant.eid", .fake_fields_decode())
  expect_equal(result, "eid")
})

test_that(".build_name_map() maps participant.p31 to sex", {
  result <- ukbflow:::.build_name_map("participant.p31", .fake_fields_decode())
  expect_equal(result, "sex")
})

test_that(".build_name_map() maps p31 (no prefix) to sex", {
  result <- ukbflow:::.build_name_map("p31", .fake_fields_decode())
  expect_equal(result, "sex")
})

test_that(".build_name_map() appends _i0 suffix for instance fields", {
  result <- ukbflow:::.build_name_map("participant.p53_i0", .fake_fields_decode())
  expect_true(endsWith(result, "_i0"))
})

test_that(".build_name_map() appends _a1 suffix for array fields", {
  result <- ukbflow:::.build_name_map("participant.p22009_a1", .fake_fields_decode())
  expect_true(endsWith(result, "_a1"))
})

test_that(".build_name_map() appends _i0_a0 for instance+array fields", {
  result <- ukbflow:::.build_name_map("participant.p20002_i0_a0", .fake_fields_decode())
  expect_true(grepl("_i0_a0$", result))
})

test_that(".build_name_map() falls back to stripped name for unknown column", {
  result <- ukbflow:::.build_name_map("participant.p99999", .fake_fields_decode())
  expect_equal(result, "p99999")
})


# ===========================================================================
# decode_names() — user-facing function
# ===========================================================================

test_that("decode_names() stops on non-data.frame input", {
  expect_error(decode_names("not a df"), "data.frame")
})

test_that("decode_names() stops on invalid max_nchar", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(participant.p31 = 1L)
  expect_error(decode_names(df, max_nchar = 0), "positive integer")
})

test_that("decode_names() renames participant.eid to eid", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(`participant.eid` = 1L, check.names = FALSE)
  result <- suppressMessages(decode_names(df))
  expect_true("eid" %in% names(result))
})

test_that("decode_names() renames p31 to sex", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(`participant.eid` = 1L, `participant.p31` = 1L,
                   check.names = FALSE)
  result <- suppressMessages(decode_names(df))
  expect_true("sex" %in% names(result))
  expect_false("participant.p31" %in% names(result))
})

test_that("decode_names() works with extract_batch format (no prefix)", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(eid = 1L, p31 = 1L)
  result <- suppressMessages(decode_names(df))
  expect_true("eid"  %in% names(result))
  expect_true("sex"  %in% names(result))
})

test_that("decode_names() preserves data.table class", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  dt <- data.table::data.table(`participant.eid` = 1L, `participant.p31` = 1L)
  result <- suppressMessages(decode_names(dt))
  expect_true(data.table::is.data.table(result))
})

test_that("decode_names() warns when a renamed column exceeds max_nchar", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  # p53_i0 → "date_of_attending_assessment_centre_i0" (>30 chars)
  df <- data.frame(`participant.p53_i0` = "2008-01-01", check.names = FALSE)
  expect_message(
    decode_names(df, max_nchar = 30),
    "longer than 30"
  )
})

test_that("decode_names() does not warn within max_nchar limit", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(`participant.p31` = 1L, check.names = FALSE)
  # "sex" is 3 chars — no warning expected
  expect_no_warning(suppressMessages(decode_names(df, max_nchar = 60)))
})

test_that("decode_names() uses cache without calling extract_ls()", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())

  called <- FALSE
  mockery::stub(decode_names, "extract_ls", function(...) {
    called <<- TRUE
    .fake_fields_decode()
  })

  df <- data.frame(`participant.p31` = 1L, check.names = FALSE)
  suppressMessages(decode_names(df))
  expect_false(called)
})

test_that("decode_names() handles duplicate snake_case names with make.unique()", {
  # Two columns that would produce the same snake_case name
  fields_dup <- data.frame(
    field_name = c("participant.p99_i0", "participant.p99_i0_dup"),
    title      = c("Some field | Instance 0", "Some field | Instance 0"),
    stringsAsFactors = FALSE
  )
  .ukbflow_cache$fields <- fields_dup
  on.exit(.clear_decode_cache())

  df <- data.frame(p99_i0 = 1L, p99_i0_dup = 2L)
  result <- suppressMessages(decode_names(df))
  expect_equal(length(unique(names(result))), 2L)
})


# ===========================================================================
# decode_values() — user-facing function
# ===========================================================================

test_that("decode_values() stops on non-data.frame input", {
  expect_error(decode_values("not a df"), "data.frame")
})

test_that("decode_values() warns when no UKB field columns found", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(sex = c("Male", "Female"))
  expect_message(decode_values(df), "no UKB field ID columns detected",
                 ignore.case = TRUE)
})

test_that("decode_values() decodes p31: 0 → Female, 1 → Male", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p31 = c(0L, 1L, 1L, 0L))
  result <- suppressMessages(decode_values(df))
  expect_equal(result$p31, c("Female", "Male", "Male", "Female"))
})

test_that("decode_values() decodes p20116 (smoking): 0/1/2 → labels", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p20116_i0 = c(0L, 1L, 2L))
  result <- suppressMessages(decode_values(df))
  expect_equal(result$p20116_i0, c("Never", "Previous", "Current"))
})

test_that("decode_values() leaves continuous column unchanged", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p31 = 1L, p22189 = -3.94)
  result <- suppressMessages(decode_values(df))
  expect_equal(result$p22189, -3.94)
  expect_true(is.numeric(result$p22189))
})

test_that("decode_values() leaves already-decoded character column unchanged", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p31 = c("Female", "Male"), stringsAsFactors = FALSE)
  result <- suppressMessages(decode_values(df))
  # Should remain unchanged — already character
  expect_equal(result$p31, c("Female", "Male"))
})

test_that("decode_values() returns NA for codes absent from encoding table", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p31 = c(0L, 1L, 99L))   # 99 is not in encoding 9
  result <- suppressMessages(decode_values(df))
  expect_true(is.na(result$p31[3]))
})

test_that("decode_values() preserves data.table class", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  dt <- data.table::data.table(p31 = c(0L, 1L))
  result <- suppressMessages(decode_values(dt))
  expect_true(data.table::is.data.table(result))
})

test_that("decode_values() leaves non-categorical field (p53 date) unchanged", {
  .set_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p31 = 1L, p53_i0 = 13956L)
  result <- suppressMessages(decode_values(df))
  expect_equal(result$p53_i0, 13956L)
})

test_that("decode_values() errors with clear message when field.tsv missing", {
  .clear_decode_cache()
  on.exit(.clear_decode_cache())
  df <- data.frame(p31 = 1L)
  expect_error(
    suppressMessages(decode_values(df, metadata_dir = tempdir())),
    "field.tsv"
  )
})

test_that("decode_values() errors with clear message when esimpint.tsv missing", {
  .clear_decode_cache()
  on.exit(.clear_decode_cache())

  # Provide field.tsv in a temp dir but not esimpint.tsv
  tmp <- tempdir()
  field_path <- file.path(tmp, "field.tsv")
  data.table::fwrite(.fake_field_meta(), field_path, sep = "\t")
  on.exit(unlink(field_path), add = TRUE)

  df <- data.frame(p31 = 1L)
  expect_error(
    suppressMessages(decode_values(df, metadata_dir = tmp)),
    "esimpint.tsv"
  )
})
