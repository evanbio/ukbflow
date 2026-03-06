# =============================================================================
# test-extract.R — Unit tests for extract_ series (mock-based, no network)
# =============================================================================

# Helper: build a fake .dx_run() result
.fake_dx <- function(stdout = "", stderr = "", status = 0) {
  list(stdout = stdout, stderr = stderr, status = status, success = status == 0)
}

# Fake fields data.frame (representative sample of all field types)
.fake_fields_df <- function() {
  data.frame(
    field_name = c(
      "participant.eid",
      "participant.p31",
      "participant.p53_i0", "participant.p53_i1",
      "participant.p53_i2", "participant.p53_i3",
      "participant.p22189",
      "participant.p20002_i0_a0", "participant.p20002_i0_a1",
      "participant.p22009_a1",    "participant.p22009_a2",
      "participant.p41202"
    ),
    title = c(
      "Participant ID",
      "Sex",
      "Date of attending assessment centre | Instance 0",
      "Date of attending assessment centre | Instance 1",
      "Date of attending assessment centre | Instance 2",
      "Date of attending assessment centre | Instance 3",
      "Townsend deprivation index at recruitment",
      "Non-cancer illness code, self-reported | Instance 0 | Array 0",
      "Non-cancer illness code, self-reported | Instance 0 | Array 1",
      "Genetic principal components | Array 1",
      "Genetic principal components | Array 2",
      "Diagnoses - main ICD10"
    ),
    stringsAsFactors = FALSE
  )
}

# Helper: populate session cache with fake fields
.set_fake_cache <- function() {
  .ukbflow_cache$fields <- .fake_fields_df()
}

# Helper: clear session cache
.clear_cache <- function() {
  .ukbflow_cache$fields <- NULL
}

# ===========================================================================
# .dx_parse_fields() — pure function, no mocking needed
# ===========================================================================

test_that(".dx_parse_fields() returns empty df for empty stdout", {
  result <- ukbflow:::.dx_parse_fields("")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_named(result, c("field_name", "title"))
})

test_that(".dx_parse_fields() parses tab-separated output correctly", {
  stdout <- "participant.p31\tSex\nparticipant.p53_i0\tDate of attending | Instance 0\n"
  result <- ukbflow:::.dx_parse_fields(stdout)
  expect_equal(nrow(result), 2)
  expect_equal(result$field_name[1], "participant.p31")
  expect_equal(result$title[1], "Sex")
})

test_that(".dx_parse_fields() handles missing title gracefully", {
  stdout <- "participant.p31\n"
  result <- ukbflow:::.dx_parse_fields(stdout)
  expect_equal(nrow(result), 1)
  expect_true(is.na(result$title[1]))
})

# ===========================================================================
# .dx_match_fields() — pure function, no mocking needed
# ===========================================================================

test_that(".dx_match_fields() matches simple field exactly", {
  result <- ukbflow:::.dx_match_fields(31L, .fake_fields_df())
  expect_length(result$matched, 1)
  expect_equal(result$matched[[1]]$field_id, 31L)
  expect_equal(result$matched[[1]]$n_cols, 1L)
  expect_length(result$unmatched, 0)
})

test_that(".dx_match_fields() expands all instances for p53", {
  result <- ukbflow:::.dx_match_fields(53L, .fake_fields_df())
  expect_equal(result$matched[[1]]$n_cols, 4L)
  expect_length(result$matched[[1]]$field_names, 4L)
})

test_that(".dx_match_fields() does NOT match p31 to p310xx fields", {
  # Add a decoy field to the fake df
  df <- .fake_fields_df()
  df <- rbind(df, data.frame(
    field_name = "participant.p31000_i0",
    title = "Some other field",
    stringsAsFactors = FALSE
  ))
  result <- ukbflow:::.dx_match_fields(31L, df)
  matched_names <- result$matched[[1]]$field_names
  expect_false(any(grepl("p31000", matched_names)))
  expect_equal(result$matched[[1]]$n_cols, 1L)
})

test_that(".dx_match_fields() returns unmatched for missing field", {
  result <- ukbflow:::.dx_match_fields(c(31L, 189L), .fake_fields_df())
  expect_length(result$matched, 1)
  expect_equal(result$unmatched, 189L)
})

test_that(".dx_match_fields() strips title instance suffix correctly", {
  result <- ukbflow:::.dx_match_fields(53L, .fake_fields_df())
  expect_equal(result$matched[[1]]$title, "Date of attending assessment centre")
})

# ===========================================================================
# extract_ls()
# ===========================================================================

test_that("extract_ls() fetches fields and caches on first call", {
  .clear_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_ls, ".dx_find_dataset",
                function() "app12345.dataset")
  mockery::stub(extract_ls, ".dx_list_fields_raw",
                function(dataset, ...) .fake_dx(
                  stdout = "participant.p31\tSex\nparticipant.p22189\tTownsend\n"
                ))

  result <- suppressMessages(extract_ls())
  expect_false(is.null(.ukbflow_cache$fields))
  expect_equal(nrow(.ukbflow_cache$fields), 2)
})

test_that("extract_ls() returns from cache on second call", {
  .set_fake_cache()
  on.exit(.clear_cache())

  call_count <- 0L
  mockery::stub(extract_ls, ".dx_list_fields_raw", function(...) {
    call_count <<- call_count + 1L
    .fake_dx(stdout = "participant.p31\tSex\n")
  })

  suppressMessages(extract_ls())
  suppressMessages(extract_ls())
  expect_equal(call_count, 0L)
})

test_that("extract_ls() refresh = TRUE re-fetches from network", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_ls, ".dx_list_fields_raw",
                function(...) .fake_dx(
                  stdout = "participant.p31\tSex\n"
                ))
  mockery::stub(extract_ls, ".dx_find_dataset", function() "app12345.dataset")

  suppressMessages(extract_ls(refresh = TRUE))
  expect_equal(nrow(.ukbflow_cache$fields), 1)
})

test_that("extract_ls() pattern filters results", {
  .set_fake_cache()
  on.exit(.clear_cache())

  result <- extract_ls(pattern = "p31")
  expect_true(all(grepl("p31", result$field_name) |
                    grepl("p31", result$title, ignore.case = TRUE)))
})

test_that("extract_ls() pattern search is case-insensitive on title", {
  .set_fake_cache()
  on.exit(.clear_cache())

  result <- extract_ls(pattern = "SEX")
  expect_gt(nrow(result), 0)
})

test_that("extract_ls() returns invisible and message when no pattern", {
  .set_fake_cache()
  on.exit(.clear_cache())

  expect_message(res <- extract_ls(), "fields available")
  expect_s3_class(res, "data.frame")
})

test_that("extract_ls() throws error when .dx_list_fields_raw fails", {
  .clear_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_ls, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_ls, ".dx_list_fields_raw",
                function(...) .fake_dx(stderr = "Not logged in", status = 1))

  expect_error(suppressMessages(extract_ls()), "Failed to list fields")
})

# ===========================================================================
# extract_pheno()
# ===========================================================================

test_that("extract_pheno() stops when not on RAP", {
  mockery::stub(extract_pheno, ".is_on_rap", function() FALSE)
  expect_error(extract_pheno(31), "RAP environment")
})

test_that("extract_pheno() throws error on empty field_id", {
  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  expect_error(extract_pheno(integer(0)), "non-empty numeric")
})

test_that("extract_pheno() throws error on non-numeric field_id", {
  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  expect_error(extract_pheno("p31"), "non-empty numeric")
})

test_that("extract_pheno() throws error when no fields match", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  mockery::stub(extract_pheno, ".dx_find_dataset", function() "app12345.dataset")
  expect_error(
    suppressMessages(extract_pheno(999999)),
    "No matching fields found"
  )
})

test_that("extract_pheno() warns on unmatched field_id", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  mockery::stub(extract_pheno, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_pheno, ".dx_extract_run", function(dataset, fields, dest, ...) {
    write.csv(data.frame(`participant.eid` = 1L, `participant.p31` = 1L,
                          check.names = FALSE), dest, row.names = FALSE)
    .fake_dx()
  })

  expect_warning(
    suppressMessages(extract_pheno(c(31, 189))),
    "not found"
  )
})

test_that("extract_pheno() always includes eid as first field", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_fields <- NULL
  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  mockery::stub(extract_pheno, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_pheno, ".dx_extract_run",
                function(dataset, fields, dest, ...) {
                  received_fields <<- fields
                  write.csv(data.frame(`participant.eid` = 1L,
                                        check.names = FALSE), dest, row.names = FALSE)
                  .fake_dx()
                })

  suppressMessages(suppressWarnings(extract_pheno(31)))
  expect_equal(received_fields[1], "participant.eid")
})

test_that("extract_pheno() returns a data.table", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  mockery::stub(extract_pheno, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_pheno, ".dx_extract_run", function(dataset, fields, dest, ...) {
    write.csv(data.frame(`participant.eid` = c(1L, 2L), `participant.p31` = c(1L, 0L),
                          check.names = FALSE), dest, row.names = FALSE)
    .fake_dx()
  })

  result <- suppressMessages(extract_pheno(31))
  expect_true(data.table::is.data.table(result))
})

# ===========================================================================
# extract_batch()
# ===========================================================================

test_that("extract_batch() throws error on invalid field_id", {
  expect_error(extract_batch(character(0)), "non-empty numeric")
})

test_that("extract_batch() strips participant. prefix for table-exporter", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_fields <- NULL
  captured_path   <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  # Reason: capture local_path here so .dx_run_table_exporter stub can read
  # the fields file before on.exit() deletes it
  mockery::stub(extract_batch, ".dx_upload_file", function(local_path) {
    captured_path <<- local_path
    "file-XXXX"
  })
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_fields <<- readLines(captured_path)
                  "job-XXXX"
                })

  suppressMessages(extract_batch(31))
  expect_true(any(grepl("^eid$", received_fields)))
  expect_true(any(grepl("^p31$", received_fields)))
  expect_false(any(grepl("^participant\\.", received_fields)))
})

test_that("extract_batch() auto-selects x8 for small extractions", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_instance <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_instance <<- instance_type
                  "job-XXXX"
                })

  suppressMessages(extract_batch(c(31, 22189)))   # 2 cols → x4
  expect_equal(received_instance, "mem1_ssd1_v2_x4")
})

test_that("extract_batch() passes priority to table-exporter", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_priority <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_priority <<- priority
                  "job-XXXX"
                })

  suppressMessages(extract_batch(31, priority = "high"))
  expect_equal(received_priority, "high")
})

test_that("extract_batch() uses custom file name when provided", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_output <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_output <<- output
                  "job-XXXX"
                })

  suppressMessages(extract_batch(31, file = "my_cohort"))
  expect_equal(received_output, "my_cohort")
})

test_that("extract_batch() returns job_id invisibly", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(...) "job-XXXX")

  expect_invisible(suppressMessages(extract_batch(31)))
  result <- suppressMessages(extract_batch(31))
  expect_equal(result, "job-XXXX")
})

test_that("extract_batch() throws error when no fields match", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  expect_error(
    suppressMessages(extract_batch(999999)),
    "No matching fields found"
  )
})

test_that("extract_batch() warns on unmatched field_ids", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter", function(...) "job-XXXX")

  expect_warning(
    suppressMessages(extract_batch(c(31, 189))),
    "not found"
  )
})

test_that("extract_batch() auto-selects x8 for 21-100 cols", {
  # p53 with 25 instances → 25 cols, which falls in the x8 tier (21-100)
  big_df <- data.frame(
    field_name = paste0("participant.p53_i", 0:24),
    title      = paste0("Field 53 | Instance ", 0:24),
    stringsAsFactors = FALSE
  )
  .ukbflow_cache$fields <- big_df
  on.exit(.clear_cache())

  received_instance <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_instance <<- instance_type
                  "job-XXXX"
                })

  suppressMessages(extract_batch(53))
  expect_equal(received_instance, "mem1_ssd1_v2_x8")
})

test_that("extract_batch() auto-selects x16 for 101-500 cols", {
  # p53 with 110 instances → 110 cols, which falls in the x16 tier (101-500)
  huge_df <- data.frame(
    field_name = paste0("participant.p53_i", 0:109),
    title      = paste0("Field 53 | Instance ", 0:109),
    stringsAsFactors = FALSE
  )
  .ukbflow_cache$fields <- huge_df
  on.exit(.clear_cache())

  received_instance <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_instance <<- instance_type
                  "job-XXXX"
                })

  suppressMessages(extract_batch(53))
  expect_equal(received_instance, "mem1_ssd1_v2_x16")
})

test_that("extract_batch() auto-selects x36 for >500 cols", {
  # p53 with 510 instances → 510 cols, which falls in the x36 tier (>500)
  giant_df <- data.frame(
    field_name = paste0("participant.p53_i", 0:509),
    title      = paste0("Field 53 | Instance ", 0:509),
    stringsAsFactors = FALSE
  )
  .ukbflow_cache$fields <- giant_df
  on.exit(.clear_cache())

  received_instance <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_instance <<- instance_type
                  "job-XXXX"
                })

  suppressMessages(extract_batch(53))
  expect_equal(received_instance, "mem1_ssd1_v2_x36")
})

test_that("extract_batch() respects custom instance_type", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_instance <- NULL
  mockery::stub(extract_batch, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_batch, ".dx_upload_file", function(...) "file-XXXX")
  mockery::stub(extract_batch, ".dx_run_table_exporter",
                function(dataset, file_id, output, instance_type, priority) {
                  received_instance <<- instance_type
                  "job-XXXX"
                })

  suppressMessages(extract_batch(31, instance_type = "mem2_ssd1_v2_x4"))
  expect_equal(received_instance, "mem2_ssd1_v2_x4")
})

# ===========================================================================
# extract_pheno() — additional edge cases
# ===========================================================================

test_that("extract_pheno() stops when extraction command fails", {
  .set_fake_cache()
  on.exit(.clear_cache())

  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  mockery::stub(extract_pheno, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_pheno, ".dx_extract_run",
                function(...) .fake_dx(stderr = "connection timeout", status = 1))

  expect_error(
    suppressMessages(extract_pheno(31)),
    "Extraction failed"
  )
})

test_that("extract_pheno() deduplicates repeated field_ids", {
  .set_fake_cache()
  on.exit(.clear_cache())

  received_fields <- NULL
  mockery::stub(extract_pheno, ".is_on_rap", function() TRUE)
  mockery::stub(extract_pheno, ".dx_find_dataset", function() "app12345.dataset")
  mockery::stub(extract_pheno, ".dx_extract_run",
                function(dataset, fields, dest, ...) {
                  received_fields <<- fields
                  write.csv(data.frame(`participant.eid` = 1L,
                                        check.names = FALSE), dest, row.names = FALSE)
                  .fake_dx()
                })

  suppressMessages(extract_pheno(c(31, 31, 31)))
  # participant.eid + participant.p31 — p31 must appear exactly once
  expect_equal(sum(received_fields == "participant.p31"), 1L)
})
