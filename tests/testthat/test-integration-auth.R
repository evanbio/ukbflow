# test-integration-auth.R
# Integration tests for auth_ series (requires real dx-toolkit, token, network)
# Run manually before release: devtools::test(filter = "integration-auth")
# -------------------------------------------------------------------------

skip_on_ci()
skip_on_cran()

# Requires DX_API_TOKEN to be set in environment
token <- Sys.getenv("DX_API_TOKEN")
if (!nzchar(token)) {
  skip("DX_API_TOKEN not set. Set it to run integration tests.")
}

# ===========================================================================
# auth_login()
# ===========================================================================

test_that("auth_login() successfully logs in with a valid token", {
  expect_message(auth_login(token = token), "successfully")
})

test_that("auth_login() throws a friendly error with an invalid token", {
  expect_error(auth_login(token = "invalid_token_xyz"), "Login failed")
})

# ===========================================================================
# auth_status()
# ===========================================================================

test_that("auth_status() returns a list with user and project fields", {
  result <- suppressMessages(auth_status())
  expect_type(result, "list")
  expect_named(result, c("user", "project"))
  expect_true(nzchar(result$user))
})

# ===========================================================================
# auth_list_projects()
# ===========================================================================

test_that("auth_list_projects() returns a non-empty character vector", {
  result <- suppressMessages(auth_list_projects())
  expect_type(result, "character")
  expect_gt(length(result), 0)
})

# ===========================================================================
# auth_select_project()
# ===========================================================================

test_that("auth_select_project() successfully selects a valid project", {
  projects <- suppressMessages(auth_list_projects())
  # Extract first project ID from output line
  project_id <- regmatches(projects[1], regexpr("project-[A-Za-z0-9]+", projects[1]))
  expect_message(auth_select_project(project_id), "Project selected")
})

test_that("auth_select_project() throws error for a non-existent project ID", {
  expect_error(auth_select_project("project-DOESNOTEXIST000"), "Failed to select project")
})

# ===========================================================================
# auth_logout()
# ===========================================================================

test_that("auth_logout() successfully logs out", {
  expect_message(auth_logout(), "Logged out")
})
