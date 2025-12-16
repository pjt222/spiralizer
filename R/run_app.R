# run_app.R - Launcher function for Spiralizer Shiny app
#
# Provides the main entry point for users to run the app.

#' Run Spiralizer App
#'
#' Launches the Spiralizer Shiny application for creating
#' Voronoi diagrams from Fermat spirals.
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{runApp}}
#' @return Shiny app object (invisibly)
#' @export
#' @examples
#' \dontrun{
#' run_spiralizer()
#' run_spiralizer(port = 8080)
#' }
run_spiralizer <- function(...) {
  app_dir <- system.file("app", package = "spiralizer")

  if (app_dir == "") {
    # Development mode: use project root
    app_dir <- here::here("inst", "app")

    if (!dir.exists(app_dir)) {
      stop(
        "Could not find app directory. ",
        "Make sure spiralizer is properly installed.",
        call. = FALSE
      )
    }
  }

  shiny::runApp(app_dir, ...)
}

#' Get App Directory
#'
#' Returns the path to the installed Shiny app directory.
#'
#' @return Character path to app directory
#' @export
#' @keywords internal
get_app_dir <- function() {
  app_dir <- system.file("app", package = "spiralizer")

  if (app_dir == "") {
    # Development mode
    app_dir <- here::here("inst", "app")
  }

  app_dir
}
