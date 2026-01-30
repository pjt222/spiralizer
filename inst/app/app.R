# Spiralizer Shiny App Entry Point
#
# This file serves as the entry point for running the Spiralizer app
# when deployed to shinyapps.io or via shiny::runApp().
#
# Load order:
# 1. Try to load spiralizer package (installed via GitHub remote)
# 2. Fall back to sourcing src/ files directly (copied during deployment)

# ============================================================================
# Package Loading with Fallback
# ============================================================================

spiralizer_loaded <- tryCatch({
  library(spiralizer)
  message("✓ Loaded spiralizer package (with Rcpp if available)")
  TRUE
}, error = function(e) {
  message("⚠ Package load failed: ", e$message)
  message("  Falling back to sourcing R files...")
  FALSE
})

if (!spiralizer_loaded) {
  # Load dependencies explicitly (these are installed via DESCRIPTION Imports)
  library(shiny)
  library(bslib)
  library(tessellation)
  library(viridisLite)
  library(memoise)
  library(cachem)
  library(colourpicker)
  library(here)
  # Note: config package not loaded with library() to avoid masking base::get()
  # Use config::get() directly in constants.R

  # Source R files in dependency order
  # These are copied to inst/app/src/ during deployment
  # NOTE: We use "src" not "R" to prevent shiny::loadSupport() from
  # auto-sourcing files without loading dependencies first.
  src_dir <- "src"
  if (!dir.exists(src_dir)) {
    # Fallback: try relative to app directory
    src_dir <- file.path(getwd(), "src")
  }

  r_files <- c(
    "aaa-utils.R",
    "constants.R",
    "color_utils.R",
    "spiral_math.R",
    "cache_manager.R",
    "performance.R",
    "theme.R",
    "ui_controls.R",
    "ui_plot.R",
    "app.R"
  )

  for (f in r_files) {
    fpath <- file.path(src_dir, f)
    if (file.exists(fpath)) {
      source(fpath, local = FALSE)
      message("  Sourced ", f)
    } else {
      warning("  File not found: ", fpath)
    }
  }

  message("✓ Loaded spiralizer via source files (pure R, no Rcpp)")
}

# ============================================================================
# Run the App
# ============================================================================

spiralizer_app()
