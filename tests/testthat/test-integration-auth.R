# =============================================================================
# test-integration-auth.R — Integration tests for auth_ series
# Requires real dx-toolkit, token, and network connection
# Run manually before release: devtools::test(filter = "integration-auth")
# =============================================================================


# ===========================================================================
# auth_login()
# ===========================================================================

test_that("auth_login() successfully logs in with a valid token", {
  token <- .skip_if_no_rap()
  expect_message(auth_login(token = token), "Logged in to DNAnexus")
})


# ===========================================================================
# auth_status()
# ===========================================================================

test_that("auth_status() returns a list with user and project fields", {
  .skip_if_no_rap()
  result <- suppressMessages(auth_status())
  expect_type(result, "list")
  expect_named(result, c("user", "project"))
  expect_true(nzchar(result$user))
})

# ===========================================================================
# auth_list_projects()
# ===========================================================================

test_that("auth_list_projects() returns a non-empty character vector", {
  .skip_if_no_rap()
  result <- suppressMessages(auth_list_projects())
  expect_type(result, "character")
  expect_gt(length(result), 0)
})

# ===========================================================================
# auth_select_project()
# ===========================================================================

test_that("auth_select_project() successfully selects a valid project", {
  .skip_if_no_rap()
  projects <- suppressMessages(auth_list_projects())
  project_id <- regmatches(projects[1], regexpr("project-[A-Za-z0-9]+", projects[1]))
  expect_message(auth_select_project(project_id), "Project selected")
})

test_that("auth_select_project() switches to the correct project (confirmed via auth_status)", {
  .skip_if_no_rap()
  projects <- suppressMessages(auth_list_projects())
  project_id <- regmatches(projects[1], regexpr("project-[A-Za-z0-9]+", projects[1]))
  suppressMessages(auth_select_project(project_id))
  status <- suppressMessages(auth_status())
  expect_equal(status$project, project_id)
})

test_that("auth_select_project() throws error for a non-existent project ID", {
  .skip_if_no_rap()
  expect_error(auth_select_project("project-DOESNOTEXIST000"), "Failed to select project")
})
