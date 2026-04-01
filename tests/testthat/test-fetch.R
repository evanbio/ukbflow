# =============================================================================
# test-fetch.R — Unit tests for fetch_ series (mock-based, no network required)
# =============================================================================
.skip_if_no_mockery()

# Helper: build a fake .dx_run() result
.fake_dx <- function(stdout = "", stderr = "", status = 0) {
  list(
    stdout  = stdout,
    stderr  = stderr,
    status  = status,
    success = status == 0
  )
}

# Fake dx ls -l output with folders and files
.fake_ls_stdout <- function() {
  paste(
    "Project: project-XXXXXXXXXXXX",
    "Folder : /",
    "",
    "Bulk/",
    "Showcase metadata/",
    "",
    "State   Last modified             Size          Name",
    "closed  2024-01-15 10:30:00    120.94 GB  ukb23158_c1_b0_v1.bed (file-AAAAAAAAAA)",
    "closed  2024-01-15 10:31:00      1.23 MB  field.tsv (file-BBBBBBBBBB)",
    sep = "\n"
  )
}

# Fake dx ls -l output with files only (no folders)
.fake_ls_files_only <- function() {
  paste(
    "Project: project-XXXXXXXXXXXX",
    "Folder : /Showcase metadata/",
    "",
    "State   Last modified             Size      Name",
    "closed  2024-01-15 10:30:00    1.23 MB  field.tsv (file-AAAAAAAAAA)",
    "closed  2024-01-15 10:31:00  800.00 KB  encoding.tsv (file-BBBBBBBBBB)",
    sep = "\n"
  )
}

# ===========================================================================
# .dx_ls_parse() — internal parser (pure function, no mocking needed)
# ===========================================================================

test_that(".dx_ls_parse() returns empty data.frame for empty stdout", {
  result <- ukbflow:::.dx_ls_parse("")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_named(result, c("name", "type", "size", "modified"))
})

test_that(".dx_ls_parse() parses folders correctly", {
  result <- ukbflow:::.dx_ls_parse(.fake_ls_stdout())
  folders <- result[result$type == "folder", ]
  expect_equal(nrow(folders), 2)
  expect_equal(folders$name, c("Bulk", "Showcase metadata"))
  expect_true(all(is.na(folders$size)))
})

test_that(".dx_ls_parse() parses files with size and modified time", {
  result <- ukbflow:::.dx_ls_parse(.fake_ls_stdout())
  files <- result[result$type == "file", ]
  expect_equal(nrow(files), 2)
  expect_equal(files$name, c("ukb23158_c1_b0_v1.bed", "field.tsv"))
  expect_false(any(is.na(files$size)))
  expect_s3_class(files$modified, "POSIXct")
})

test_that(".dx_ls_parse() returns correct columns", {
  result <- ukbflow:::.dx_ls_parse(.fake_ls_stdout())
  expect_named(result, c("name", "type", "size", "modified"))
})

test_that(".dx_ls_parse() handles files-only output (no folders)", {
  result <- ukbflow:::.dx_ls_parse(.fake_ls_files_only())
  expect_equal(nrow(result), 2)
  expect_true(all(result$type == "file"))
})

test_that(".dx_ls_parse() returns empty data.frame when dx reports 'No data objects found'", {
  stdout <- paste(
    "Project: project-XXXXXXXXXXXX",
    "Folder : /empty/",
    "",
    "No data objects found.",
    sep = "\n"
  )
  result <- ukbflow:::.dx_ls_parse(stdout)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_named(result, c("name", "type", "size", "modified"))
})

# ===========================================================================
# fetch_ls()
# ===========================================================================

test_that("fetch_ls() returns a data.frame with correct columns", {
  mockery::stub(fetch_ls, ".dx_ls_raw",
                function(path, ...) .fake_dx(stdout = .fake_ls_stdout()))
  result <- fetch_ls()
  expect_s3_class(result, "data.frame")
  expect_named(result, c("name", "type", "size", "modified"))
})

test_that("fetch_ls() throws error when dx fails", {
  mockery::stub(fetch_ls, ".dx_ls_raw",
                function(path, ...) .fake_dx(stderr = "Not logged in", status = 1))
  expect_error(fetch_ls(), "Failed to list")
})

test_that("fetch_ls() filters by type = 'file'", {
  mockery::stub(fetch_ls, ".dx_ls_raw",
                function(path, ...) .fake_dx(stdout = .fake_ls_stdout()))
  result <- fetch_ls(type = "file")
  expect_true(all(result$type == "file"))
})

test_that("fetch_ls() filters by type = 'folder'", {
  mockery::stub(fetch_ls, ".dx_ls_raw",
                function(path, ...) .fake_dx(stdout = .fake_ls_stdout()))
  result <- fetch_ls(type = "folder")
  expect_true(all(result$type == "folder"))
})

test_that("fetch_ls() filters by pattern", {
  mockery::stub(fetch_ls, ".dx_ls_raw",
                function(path, ...) .fake_dx(stdout = .fake_ls_stdout()))
  result <- fetch_ls(pattern = "\\.bed$")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "ukb23158_c1_b0_v1.bed")
})

test_that("fetch_ls() returns empty data.frame when pattern matches nothing", {
  mockery::stub(fetch_ls, ".dx_ls_raw",
                function(path, ...) .fake_dx(stdout = .fake_ls_stdout()))
  result <- fetch_ls(pattern = "\\.bgen$")
  expect_equal(nrow(result), 0)
})

# ===========================================================================
# fetch_url()
# ===========================================================================

test_that("fetch_url() returns a named character vector for a single file", {
  mockery::stub(fetch_url, ".dx_probe_path",
                function(...) list(is_folder = FALSE, is_file = TRUE, exists = TRUE, stdout = ""))
  mockery::stub(fetch_url, ".dx_make_url",
                function(path, ...) "https://dl.dnanex.us/fake/field.tsv")
  result <- fetch_url("Showcase metadata/field.tsv")
  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(startsWith(result, "https://"))
  expect_equal(names(result), "field.tsv")
})

test_that("fetch_url() returns named vector for a folder", {
  fake_files <- data.frame(
    name = c("field.tsv", "encoding.tsv"),
    type = "file", size = NA, modified = as.POSIXct(NA),
    stringsAsFactors = FALSE
  )
  mockery::stub(fetch_url, "fetch_ls", function(...) fake_files)
  mockery::stub(fetch_url, ".dx_make_url",
                function(path, ...) paste0("https://dl.dnanex.us/fake/", basename(path)))
  result <- fetch_url("Showcase metadata/")
  expect_length(result, 2)
  expect_equal(names(result), c("field.tsv", "encoding.tsv"))
})

test_that("fetch_url() returns character(0) for empty folder", {
  mockery::stub(fetch_url, "fetch_ls",
                function(...) data.frame(name = character(0), type = character(0),
                                         size = character(0),
                                         modified = as.POSIXct(character(0)),
                                         stringsAsFactors = FALSE))
  result <- suppressMessages(fetch_url("empty/"))
  expect_equal(result, character(0))
})

# ===========================================================================
# fetch_file()
# ===========================================================================

test_that("fetch_file() calls .dx_download_file for a single file", {
  downloaded <- character(0)
  local_mocked_bindings(.is_on_rap = function() TRUE, .package = "ukbflow")
  mockery::stub(fetch_file, ".dx_probe_path",
                function(...) list(is_folder = FALSE, is_file = TRUE, exists = TRUE, stdout = ""))
  mockery::stub(fetch_file, ".dx_make_url",
                function(path, ...) "https://dl.dnanex.us/fake/field.tsv")
  mockery::stub(fetch_file, ".dx_download_file",
                function(url, destfile, ...) { downloaded <<- destfile; invisible(destfile) })
  withr::with_tempdir({
    fetch_file("Showcase metadata/field.tsv", dest_dir = ".")
    expect_true(grepl("field.tsv", downloaded))
  })
})

test_that("fetch_file() returns character(0) for empty folder", {
  local_mocked_bindings(.is_on_rap = function() TRUE, .package = "ukbflow")
  mockery::stub(fetch_file, ".dx_probe_path",
                function(...) list(is_folder = TRUE, is_file = FALSE, exists = TRUE, stdout = ""))
  mockery::stub(fetch_file, "fetch_ls",
                function(...) data.frame(name = character(0), type = character(0),
                                         size = character(0),
                                         modified = as.POSIXct(character(0)),
                                         stringsAsFactors = FALSE))
  withr::with_tempdir({
    result <- suppressMessages(fetch_file("empty/", dest_dir = "."))
    expect_equal(result, character(0))
  })
})

test_that("fetch_file() creates dest_dir if it does not exist", {
  local_mocked_bindings(.is_on_rap = function() TRUE, .package = "ukbflow")
  mockery::stub(fetch_file, ".dx_probe_path",
                function(...) list(is_folder = FALSE, is_file = TRUE, exists = TRUE, stdout = ""))
  mockery::stub(fetch_file, ".dx_make_url",
                function(path, ...) "https://dl.dnanex.us/fake/field.tsv")
  mockery::stub(fetch_file, ".dx_download_file",
                function(url, destfile, ...) invisible(destfile))
  withr::with_tempdir({
    new_dir <- file.path(getwd(), "new_subdir")
    expect_false(dir.exists(new_dir))
    fetch_file("Showcase metadata/field.tsv", dest_dir = new_dir)
    expect_true(dir.exists(new_dir))
  })
})

# ===========================================================================
# fetch_metadata()
# ===========================================================================

test_that("fetch_metadata() calls fetch_file with 'Showcase metadata/' path", {
  called_with <- NULL
  mockery::stub(fetch_metadata, "fetch_file",
                function(path, ...) { called_with <<- path; invisible(path) })
  fetch_metadata()
  expect_equal(called_with, "Showcase metadata/")
})

test_that("fetch_metadata() passes dest_dir through to fetch_file", {
  args_received <- NULL
  mockery::stub(fetch_metadata, "fetch_file",
                function(path, dest_dir, ...) { args_received <<- dest_dir; invisible(path) })
  fetch_metadata(dest_dir = "custom/dir/")
  expect_equal(args_received, "custom/dir/")
})

# ===========================================================================
# fetch_field()
# ===========================================================================

test_that("fetch_field() calls fetch_file with 'Showcase metadata/field.tsv' path", {
  called_with <- NULL
  mockery::stub(fetch_field, "fetch_file",
                function(path, ...) { called_with <<- path; invisible(path) })
  fetch_field()
  expect_equal(called_with, "Showcase metadata/field.tsv")
})

test_that("fetch_field() passes dest_dir through to fetch_file", {
  args_received <- NULL
  mockery::stub(fetch_field, "fetch_file",
                function(path, dest_dir, ...) { args_received <<- dest_dir; invisible(path) })
  fetch_field(dest_dir = "custom/dir/")
  expect_equal(args_received, "custom/dir/")
})

# ===========================================================================
# fetch_tree()
# ===========================================================================

test_that("fetch_tree() returns invisible character vector", {
  mockery::stub(fetch_tree, ".dx_ls_names",
                function(path, ...) .fake_dx(stdout = "Bulk/\nShowcase metadata/\n"))
  result <- suppressMessages(fetch_tree(verbose = FALSE))
  expect_type(result, "character")
})

test_that("fetch_tree() respects max_depth = 0 (no traversal)", {
  call_count <- 0L
  mockery::stub(fetch_tree, ".dx_ls_names", function(path, ...) {
    call_count <<- call_count + 1L
    .fake_dx(stdout = "Bulk/\n")
  })
  suppressMessages(fetch_tree(max_depth = 0, verbose = FALSE))
  expect_equal(call_count, 0L)
})

test_that("fetch_tree() produces no output when verbose = FALSE", {
  mockery::stub(fetch_tree, ".dx_ls_names",
                function(path, ...) .fake_dx(stdout = "Bulk/\n"))
  expect_silent(fetch_tree(verbose = FALSE))
})


# ===========================================================================
# .dx_probe_path() — internal folder/file detector
# ===========================================================================

test_that(".dx_probe_path() detects folder by trailing slash without a network call", {
  # Reason: trailing slash is a client-side signal — no dx ls should fire
  result <- ukbflow:::.dx_probe_path("Bulk/")
  expect_true(result$is_folder)
  expect_false(result$is_file)
  expect_true(result$exists)
  expect_equal(result$stdout, "")
})

test_that(".dx_probe_path() returns is_folder = TRUE when dx reports Folder header", {
  local_mocked_bindings(
    .dx_ls_raw = function(...) .fake_dx(stdout = "Project: p\nFolder : /Bulk/\n"),
    .package = "ukbflow"
  )
  result <- ukbflow:::.dx_probe_path("Bulk")
  expect_true(result$is_folder)
  expect_false(result$is_file)
  expect_true(result$exists)
})

test_that(".dx_probe_path() returns is_file = TRUE for a file path", {
  # Reason: dx ls -l on a single file has no "Folder :" header line
  single_file_stdout <- paste(
    "Project: project-XXXXXXXXXXXX",
    "",
    "State   Last modified             Size      Name",
    "closed  2024-01-15 10:30:00    1.23 MB  field.tsv (file-AAAAAAAAAA)",
    sep = "\n"
  )
  local_mocked_bindings(
    .dx_ls_raw = function(...) .fake_dx(stdout = single_file_stdout),
    .package = "ukbflow"
  )
  result <- ukbflow:::.dx_probe_path("Showcase metadata/field.tsv")
  expect_false(result$is_folder)
  expect_true(result$is_file)
  expect_true(result$exists)
})

test_that(".dx_probe_path() returns exists = FALSE when dx fails", {
  local_mocked_bindings(
    .dx_ls_raw = function(...) .fake_dx(status = 1, stderr = "Not found"),
    .package = "ukbflow"
  )
  result <- ukbflow:::.dx_probe_path("nonexistent/path")
  expect_false(result$exists)
  expect_false(result$is_folder)
  expect_false(result$is_file)
})


# ===========================================================================
# .dx_ls_parse() — edge cases
# ===========================================================================

test_that(".dx_ls_parse() handles file name with spaces", {
  stdout <- paste(
    "Project: project-XXXXXXXXXXXX",
    "Folder : /",
    "",
    "State   Last modified             Size      Name",
    "closed  2024-01-15 10:30:00    1.23 MB  my report file.tsv (file-AAAAAAAAAA)",
    sep = "\n"
  )
  result <- ukbflow:::.dx_ls_parse(stdout)
  expect_equal(nrow(result), 1L)
  expect_equal(result$name, "my report file.tsv")
})

test_that(".dx_ls_parse() handles size reported in bytes", {
  stdout <- paste(
    "Project: project-XXXXXXXXXXXX",
    "Folder : /",
    "",
    "State   Last modified             Size      Name",
    "closed  2024-01-15 10:30:00    512 bytes  tiny.txt (file-AAAAAAAAAA)",
    sep = "\n"
  )
  result <- ukbflow:::.dx_ls_parse(stdout)
  expect_equal(nrow(result), 1L)
  expect_equal(result$size, "512 bytes")
})

test_that(".dx_ls_parse() handles missing size field (NA)", {
  stdout <- paste(
    "Project: project-XXXXXXXXXXXX",
    "Folder : /",
    "",
    "State   Last modified   Name",
    "closed  2024-01-15 10:30:00  nosize.txt (file-AAAAAAAAAA)",
    sep = "\n"
  )
  result <- ukbflow:::.dx_ls_parse(stdout)
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$size))
})


# ===========================================================================
# fetch_file() — RAP guard and return values
# ===========================================================================

test_that("fetch_file() aborts when not called from within the RAP", {
  local_mocked_bindings(.is_on_rap = function() FALSE, .package = "ukbflow")
  expect_error(fetch_file("Showcase metadata/field.tsv"), class = "rlang_error")
})

test_that("fetch_file() returns destfile invisibly for a single file", {
  local_mocked_bindings(.is_on_rap = function() TRUE, .package = "ukbflow")
  mockery::stub(fetch_file, ".dx_probe_path",
                function(...) list(is_folder = FALSE, is_file = TRUE, exists = TRUE, stdout = ""))
  mockery::stub(fetch_file, ".dx_make_url",
                function(path, ...) "https://dl.dnanex.us/fake/field.tsv")
  mockery::stub(fetch_file, ".dx_download_file",
                function(url, destfile, ...) invisible(destfile))
  withr::with_tempdir({
    result <- fetch_file("Showcase metadata/field.tsv", dest_dir = ".")
    expect_equal(result, file.path(".", "field.tsv"))
  })
})

test_that("fetch_file() returns destfiles invisibly for a folder", {
  fake_files <- data.frame(
    name = c("field.tsv", "encoding.tsv"),
    type = "file", size = NA, modified = as.POSIXct(NA),
    stringsAsFactors = FALSE
  )
  local_mocked_bindings(.is_on_rap = function() TRUE, .package = "ukbflow")
  mockery::stub(fetch_file, ".dx_probe_path",
                function(...) list(is_folder = TRUE, is_file = FALSE, exists = TRUE, stdout = ""))
  mockery::stub(fetch_file, "fetch_ls", function(...) fake_files)
  mockery::stub(fetch_file, ".dx_make_url",
                function(path, ...) paste0("https://dl.dnanex.us/fake/", basename(path)))
  mockery::stub(fetch_file, ".dx_download_batch",
                function(urls, destfiles, ...) invisible(destfiles))
  withr::with_tempdir({
    result <- fetch_file("Showcase metadata/", dest_dir = ".")
    expect_equal(result, file.path(".", c("field.tsv", "encoding.tsv")))
  })
})
