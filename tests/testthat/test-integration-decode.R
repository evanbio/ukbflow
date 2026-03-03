# =============================================================================
# test-integration-decode.R — Integration tests for decode_ series
# Requires real dx-toolkit, token, and network connection (decode_names),
# and local metadata files (decode_values).
# Run manually before release: devtools::test(filter = "integration-decode")
# =============================================================================

skip_on_ci()
skip_on_cran()

token <- Sys.getenv("DX_API_TOKEN")
if (!nzchar(token)) {
  skip("DX_API_TOKEN not set. Set it to run integration tests.")
}

# Metadata directory for decode_values() tests
# Populated by: fetch_file("Showcase metadata/field.tsv", dest_dir = META_DIR)
#               fetch_file("Showcase metadata/esimpint.tsv", dest_dir = META_DIR)
META_DIR <- "dev/temp/downloads/metadata"

# ===========================================================================
# decode_names() — requires live extract_ls() to populate cache
# ===========================================================================

test_that("decode_names() renames participant.p31 to sex via live cache", {
  .ukbflow_cache$fields <- NULL

  df <- data.frame(`participant.eid` = 1L, `participant.p31` = 1L,
                   check.names = FALSE)
  result <- suppressMessages(decode_names(df))

  expect_true("eid" %in% names(result))
  expect_true("sex" %in% names(result))
  expect_false("participant.p31" %in% names(result))
})

test_that("decode_names() renames all columns from extract_pheno() format", {
  .ukbflow_cache$fields <- NULL

  df <- data.frame(
    `participant.eid`    = 1L,
    `participant.p31`    = 1L,
    `participant.p21022` = 65L,
    `participant.p22189` = -3.94,
    check.names = FALSE
  )
  result <- suppressMessages(decode_names(df))

  expect_true("eid"    %in% names(result))
  expect_true("sex"    %in% names(result))
  expect_true("age_at_recruitment" %in% names(result))
  expect_true("townsend_deprivation_index_at_recruitment" %in% names(result))
})

test_that("decode_names() renames p53 instance columns with _i0.._i3 suffixes", {
  .ukbflow_cache$fields <- NULL

  df <- data.frame(
    `participant.eid`    = 1L,
    `participant.p53_i0` = "2008-01-01",
    `participant.p53_i1` = NA_character_,
    check.names = FALSE
  )
  result <- suppressMessages(decode_names(df))

  new_names <- names(result)
  expect_true(any(grepl("_i0$", new_names)))
  expect_true(any(grepl("_i1$", new_names)))
})

test_that("decode_names() warms session cache as side effect", {
  .ukbflow_cache$fields <- NULL
  df <- data.frame(`participant.p31` = 1L, check.names = FALSE)
  suppressMessages(decode_names(df))
  expect_false(is.null(.ukbflow_cache$fields))
  expect_gt(nrow(.ukbflow_cache$fields), 0L)
})

# ===========================================================================
# decode_values() — requires local metadata files (no network after download)
# ===========================================================================

if (!file.exists(file.path(META_DIR, "field.tsv")) ||
    !file.exists(file.path(META_DIR, "esimpint.tsv"))) {
  skip(paste0(
    "Metadata files not found in '", META_DIR, "'. ",
    "Run fetch_file(\"Showcase metadata/field.tsv\", dest_dir = \"", META_DIR, "\") ",
    "and fetch_file(\"Showcase metadata/esimpint.tsv\", dest_dir = \"", META_DIR, "\") first."
  ))
}

# Clear metadata cache before each test to ensure fresh reads
.clear_meta_cache <- function() {
  .ukbflow_cache$field_meta <- NULL
  .ukbflow_cache$esimpint   <- NULL
}

test_that("decode_values() decodes p31: 0 → Female, 1 → Male", {
  .clear_meta_cache()
  df <- data.frame(p31 = c(0L, 1L))
  result <- suppressMessages(decode_values(df, metadata_dir = META_DIR))
  expect_equal(result$p31, c("Female", "Male"))
})

test_that("decode_values() caches field_meta and esimpint after first call", {
  .clear_meta_cache()
  df <- data.frame(p31 = 1L)
  suppressMessages(decode_values(df, metadata_dir = META_DIR))
  expect_false(is.null(.ukbflow_cache$field_meta))
  expect_false(is.null(.ukbflow_cache$esimpint))
})

test_that("decode_values() leaves continuous field p22189 (Townsend) unchanged", {
  .clear_meta_cache()
  df <- data.frame(p31 = 1L, p22189 = -3.94)
  result <- suppressMessages(decode_values(df, metadata_dir = META_DIR))
  expect_equal(result$p22189, -3.94)
  expect_true(is.numeric(result$p22189))
})

test_that("decode_values() decodes smoking status p20116: 0/1/2 → labels", {
  .clear_meta_cache()
  df <- data.frame(p20116_i0 = c(0L, 1L, 2L))
  result <- suppressMessages(decode_values(df, metadata_dir = META_DIR))
  expect_true(all(result$p20116_i0 %in% c("Never", "Previous", "Current")))
})

test_that("decode_values() returns NA for code absent from encoding table", {
  .clear_meta_cache()
  df <- data.frame(p31 = c(0L, 1L, 99L))
  result <- suppressMessages(decode_values(df, metadata_dir = META_DIR))
  expect_true(is.na(result$p31[3]))
  expect_equal(result$p31[1], "Female")
})

test_that("decode_values() then decode_names() produces clean final output", {
  .clear_meta_cache()
  .ukbflow_cache$fields <- NULL

  df <- data.frame(
    `participant.eid`    = c(1L, 2L),
    `participant.p31`    = c(1L, 0L),
    `participant.p21022` = c(65L, 52L),
    check.names = FALSE
  )

  result <- df |>
    decode_values(metadata_dir = META_DIR) |>
    suppressMessages() |>
    decode_names() |>
    suppressMessages()

  expect_true("eid"  %in% names(result))
  expect_true("sex"  %in% names(result))
  expect_true("age_at_recruitment" %in% names(result))
  expect_equal(result$sex, c("Male", "Female"))
})
