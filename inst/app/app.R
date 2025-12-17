# Spiralizer Shiny App Entry Point
#
# This file serves as the entry point for running the Spiralizer app
# either via shiny::runApp() or when deployed to shinyapps.io.
#
# Usage:
#   shiny::runApp(system.file("app", package = "spiralizer"))
#   # or
#   spiralizer::run_spiralizer()

# Check if running from installed package or development
if (requireNamespace("spiralizer", quietly = TRUE) &&
    "spiralizer_app" %in% getNamespaceExports("spiralizer")) {
  # Running from installed package
  spiralizer::spiralizer_app()
} else {
  # Development mode: source files directly
  library(shiny)
  library(bslib)
  library(tessellation)
  library(viridisLite)
  library(memoise)
  library(cachem)
  # Note: config package not loaded with library() to avoid masking base::get()
  # and base::merge(). Use config::get() directly in constants.R instead.
  library(here)

  # Source all R files in dependency order (flat R/ directory)
  source(here::here("R/aaa-utils.R"))
  source(here::here("R/theme.R"))
  source(here::here("R/constants.R"))
  source(here::here("R/cache_manager.R"))
  source(here::here("R/color_utils.R"))
  source(here::here("R/spiral_math.R"))
  source(here::here("R/performance.R"))
  source(here::here("R/ui_controls.R"))
  source(here::here("R/ui_plot.R"))
  source(here::here("R/app.R"))

  # Run the app
  spiralizer_app()
}
