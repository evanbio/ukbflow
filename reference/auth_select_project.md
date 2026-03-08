# Select a DNAnexus project

Switches the active project context on the DNAnexus platform. Only
project IDs (e.g. `"project-XXXXXXXXXXXX"`) are accepted. Run
[`auth_list_projects()`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md)
to find your project ID.

## Usage

``` r
auth_select_project(project)
```

## Arguments

- project:

  (character) Project ID in the form `"project-XXXXXXXXXXXX"`.

## Value

Invisible TRUE on success.

## Examples

``` r
if (FALSE) { # \dontrun{
auth_select_project("project-XXXXXXXXXXXX")
} # }
```
