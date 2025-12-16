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
  library(config)
  library(here)

  # Source all R files in dependency order
  source(here::here("R/theme.R"))
  source(here::here("R/utils/constants.R"))
  source(here::here("R/utils/cache_manager.R"))
  source(here::here("R/utils/color_utils.R"))
  source(here::here("R/utils/spiral_math.R"))
  source(here::here("R/utils/performance.R"))
  source(here::here("R/modules/ui_controls.R"))
  source(here::here("R/modules/ui_plot.R"))
  source(here::here("R/app_zen.R"))

  # Run the app
  spiralizer_app()
}
