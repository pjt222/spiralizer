# install_deps.R - Install all package dependencies into renv
#
# Run this script to install all required packages before renv::snapshot()
# Usage: source("inst/scripts/install_deps.R")

# Activate renv
source(".Rprofile")

# Disable prompts for non-interactive install
options(renv.config.install.prompt = FALSE)

# CRAN packages
cran_packages <- c(
  "bslib",
  "cachem",
  "config",
  "duckdb",
  "here",
  "memoise",
  "Rcpp",
  "rsconnect",
  "shiny",
  "viridisLite",
  "testthat",
  "microbenchmark",
  "ggplot2",
  "data.table"
)

# Install CRAN packages
message("Installing CRAN packages...")
renv::install(cran_packages, prompt = FALSE)

# GitHub packages (order matters - dependencies first)
message("\nInstalling GitHub packages...")
renv::install("stla/cxhull", prompt = FALSE)
renv::install("stla/colorsGen", prompt = FALSE)
renv::install("stla/tessellation", prompt = FALSE)

# Optional: legacy app dependency (only needed for inst/archive/)
# renv::install("Appsilon/shiny.semantic", prompt = FALSE)

message("\nAll packages installed!")
message("Now run: renv::snapshot()")
