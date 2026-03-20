# =============================================================================
# test-auth.R — Unit tests for auth_ series (mock-based, no network required)
# =============================================================================

# Helper: build a fake .dx_run() result
.fake_dx <- function(stdout = "", stderr = "", status = 0) {
  list(
    stdout  = stdout,
    stderr  = stderr,
    status  = status,
    success = status == 0
  )
}

# ===========================================================================
# auth_login()
# ===========================================================================

test_that("auth_login() throws error when token is NULL and env var is unset", {
  withr::with_envvar(c(DX_API_TOKEN = ""), {
    expect_error(auth_login(token = NULL), "DX_API_TOKEN")
  })
})

test_that("auth_login() throws error when token is an empty string", {
  expect_error(auth_login(token = ""), "single non-empty string")
})

test_that("auth_login() uses DX_API_TOKEN env var when token argument is NULL", {
  withr::with_envvar(c(DX_API_TOKEN = "fake_token"), {
    mockery::stub(auth_login, ".dx_run", function(args, ...) {
      if (args[1] == "login") return(.fake_dx(status = 0))
      if (args[1] == "whoami") return(.fake_dx(stdout = "TestUser"))
    })
    expect_message(auth_login(token = NULL), "TestUser")
  })
})

test_that("auth_login() throws error when token is NA", {
  expect_error(auth_login(token = NA_character_), "single non-empty string")
})

test_that("auth_login() throws error when token is a length-2 vector", {
  expect_error(auth_login(token = c("tok1", "tok2")), "single non-empty string")
})

test_that("auth_login() throws error when token is non-character", {
  expect_error(auth_login(token = 123), "single non-empty string")
})

test_that("auth_login() throws error when dx login returns non-zero status", {
  mockery::stub(auth_login, ".dx_run", function(args, ...) {
    .fake_dx(stderr = "Invalid auth token", status = 1)
  })
  expect_error(auth_login(token = "bad_token"), "Login failed")
})

test_that("auth_login() throws error when whoami fails after login", {
  mockery::stub(auth_login, ".dx_run", function(args, ...) {
    if (args[1] == "login") return(.fake_dx(status = 0))
    if (args[1] == "whoami") return(.fake_dx(stderr = "Not logged in", status = 1))
  })
  expect_error(auth_login(token = "bad_token"), "token invalid or expired")
})

test_that("auth_login() returns TRUE invisibly on success", {
  mockery::stub(auth_login, ".dx_run", function(args, ...) {
    if (args[1] == "login") return(.fake_dx(status = 0))
    if (args[1] == "whoami") return(.fake_dx(stdout = "TestUser"))
  })
  expect_invisible(auth_login(token = "valid_token"))
})

# ===========================================================================
# auth_status()
# ===========================================================================

test_that("auth_status() throws error when not logged in", {
  mockery::stub(auth_status, ".dx_run", function(...) .fake_dx(stderr = "Not logged in", status = 1))
  expect_error(auth_status(), "Not logged in")
})

test_that("auth_status() returns NA project when no project is selected", {
  mockery::stub(auth_status, ".dx_run", function(args, ...) {
    if (args[1] == "whoami") return(.fake_dx(stdout = "TestUser"))
    if (args[1] == "env")    return(.fake_dx(stdout = "export DX_APISERVER_HOST=api.dnanexus.com"))
  })
  mockery::stub(auth_status, ".dx_get_project_id", function(...) NA_character_)
  result <- suppressMessages(auth_status())
  expect_true(is.na(result$project))
})

test_that("auth_status() returns correct user and project when logged in", {
  mockery::stub(auth_status, ".dx_run", function(...) .fake_dx(stdout = "TestUser"))
  mockery::stub(auth_status, ".dx_get_project_id", function(...) "project-XXXXXXXXXXXX")
  result <- suppressMessages(auth_status())
  expect_equal(result$user, "TestUser")
  expect_equal(result$project, "project-XXXXXXXXXXXX")
})

# ===========================================================================
# auth_logout()
# ===========================================================================

test_that("auth_logout() throws error when dx logout fails", {
  mockery::stub(auth_logout, ".dx_run", function(...) .fake_dx(stderr = "Not logged in", status = 1))
  expect_error(auth_logout(), "Logout failed")
})

test_that("auth_logout() returns TRUE invisibly on success", {
  mockery::stub(auth_logout, ".dx_run", function(...) .fake_dx(status = 0))
  expect_invisible(auth_logout())
})

# ===========================================================================
# auth_list_projects()
# ===========================================================================

test_that("auth_list_projects() throws error when dx find fails", {
  mockery::stub(auth_list_projects, ".dx_run", function(...) .fake_dx(stderr = "Auth error", status = 1))
  expect_error(auth_list_projects(), "Failed to list projects")
})

test_that("auth_list_projects() returns empty vector when no projects found", {
  mockery::stub(auth_list_projects, ".dx_run", function(...) .fake_dx(stdout = "", status = 0))
  result <- suppressMessages(auth_list_projects())
  expect_equal(result, character(0))
})

test_that("auth_list_projects() returns character vector of projects", {
  fake_output <- paste(
    "project-AAA : Project A (ADMINISTER)",
    "project-BBB : Project B (VIEW)",
    sep = "\n"
  )
  mockery::stub(auth_list_projects, ".dx_run", function(...) .fake_dx(stdout = fake_output, status = 0))
  result <- suppressMessages(auth_list_projects())
  expect_length(result, 2)
  expect_true(grepl("project-AAA", result[1]))
})

# ===========================================================================
# auth_select_project()
# ===========================================================================

test_that("auth_select_project() throws error when project argument is missing", {
  expect_error(auth_select_project(), "project ID")
})

test_that("auth_select_project() throws error when project is empty string", {
  expect_error(auth_select_project(""), "single non-empty string")
})

test_that("auth_select_project() throws error when project is NA", {
  expect_error(auth_select_project(NA_character_), "single non-empty string")
})

test_that("auth_select_project() throws error when project is a length-2 vector", {
  expect_error(auth_select_project(c("project-AAA", "project-BBB")), "single non-empty string")
})

test_that("auth_select_project() throws error when project is non-character", {
  expect_error(auth_select_project(123), "single non-empty string")
})

test_that("auth_select_project() throws error when dx select fails", {
  mockery::stub(auth_select_project, ".dx_run", function(...) .fake_dx(stderr = "Not found", status = 1))
  expect_error(auth_select_project("project-XXXXXXXXXXXX"), "Failed to select project")
})

test_that("auth_select_project() throws error when project context is not updated (NA)", {
  mockery::stub(auth_select_project, ".dx_run", function(...) .fake_dx(status = 0))
  mockery::stub(auth_select_project, ".dx_get_project_id", function(...) NA_character_)
  expect_error(auth_select_project("project-XXXXXXXXXXXX"), "Project selection failed")
})

test_that("auth_select_project() throws error when confirmed project differs from requested", {
  mockery::stub(auth_select_project, ".dx_run", function(...) .fake_dx(status = 0))
  mockery::stub(auth_select_project, ".dx_get_project_id", function(...) "project-YYYYYYYYYYYY")
  expect_error(auth_select_project("project-XXXXXXXXXXXX"), "Project selection failed")
})

test_that("auth_select_project() returns TRUE invisibly on success", {
  mockery::stub(auth_select_project, ".dx_run", function(...) .fake_dx(status = 0))
  mockery::stub(auth_select_project, ".dx_get_project_id", function(...) "project-XXXXXXXXXXXX")
  expect_invisible(auth_select_project("project-XXXXXXXXXXXX"))
})
