# Deploy Spiralizer to shinyapps.io
#
# This script prepares the inst/app directory for deployment and deploys
# the Spiralizer app to shinyapps.io.
#
# The key insight: shinyapps.io detects DESCRIPTION files and treats the
# directory as a package. We use a Type: Shiny DESCRIPTION that installs
# spiralizer from GitHub, with R/ files as fallback.
#
# Requires: rsconnect package and configured account (or env vars)

# ============================================================================
# Setup
# ============================================================================

message("=== Spiralizer Deployment Script ===")
message("Time: ", Sys.time())

# Load rsconnect
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("rsconnect package is required. Install with: install.packages('rsconnect')")
}
library(rsconnect)

# ============================================================================
# Configuration
# ============================================================================

APP_DIR <- "inst/app"
APP_NAME <- "spiralizer"
GITHUB_REPO <- "pjt222/spiralizer"

# R files to copy (in load order from DESCRIPTION Collate)
R_FILES <- c(
  "aaa-utils.R",
  "RcppExports.R",
  "constants.R",
  "color_utils.R",
  "spiral_math.R",
  "cache_manager.R",
  "performance.R",
  "theme.R",
  "ui_controls.R",
  "ui_plot.R",
  "app.R",
  "run_app.R",
  "zzz.R"
)

# Dependencies (from main DESCRIPTION Imports)
DEPENDENCIES <- c(
  "bslib (>= 0.6.0)",
  "cachem",
  "colourpicker",
  "config",
  "grDevices",
  "here",
  "memoise",
  "shiny (>= 1.8.0)",
  "tessellation (>= 2.3.0)",
  "viridisLite"
)

# ============================================================================
# Helper Functions
# ============================================================================

create_shiny_description <- function(app_dir, github_repo, dependencies) {
  # Add spiralizer itself to imports so shinyapps.io tries to install it
  all_imports <- c("spiralizer", dependencies)

  desc_content <- sprintf('Type: Shiny
Title: Spiralizer - Interactive Voronoi Diagrams
Version: 0.1.0
Author: Philipp Thoss
Depends:
    R (>= 4.1.0)
Imports:
    %s
Remotes:
    github::%s
', paste(all_imports, collapse = ",\n    "), github_repo)

  desc_path <- file.path(app_dir, "DESCRIPTION")
  writeLines(desc_content, desc_path)
  message("✓ Created ", desc_path)
}

create_rprofile_fallback <- function(app_dir) {
  rprofile_content <- '# .Rprofile for shinyapps.io deployment
# Fallback package installation if GitHub remote fails

local({
  # Try to install spiralizer from GitHub if not available
  if (!requireNamespace("spiralizer", quietly = TRUE)) {
    message("spiralizer package not found, attempting GitHub install...")
    tryCatch({
      if (!requireNamespace("remotes", quietly = TRUE)) {
        install.packages("remotes")
      }
      remotes::install_github("pjt222/spiralizer", dependencies = TRUE)
      message("✓ Installed spiralizer from GitHub")
    }, error = function(e) {
      message("⚠ GitHub install failed: ", e$message)
      message("  Will fall back to sourcing R files directly")
    })
  }
})
'
  rprofile_path <- file.path(app_dir, ".Rprofile")
  writeLines(rprofile_content, rprofile_path)
  message("✓ Created ", rprofile_path)
}

copy_r_files <- function(app_dir, r_files) {
  # IMPORTANT: Use "src" not "R" to prevent shiny::loadSupport() from
  # auto-sourcing files without loading dependencies first.
  # loadSupport() only looks in R/ subdirectory.
  src_dir <- file.path(app_dir, "src")

  # Clean up any old R/ directory from previous deployments
  old_r_dir <- file.path(app_dir, "R")
  if (dir.exists(old_r_dir)) {
    unlink(old_r_dir, recursive = TRUE)
    message("✓ Removed old R/ directory")
  }

  # Create src directory if it doesn't exist
  if (!dir.exists(src_dir)) {
    dir.create(src_dir, recursive = TRUE)
    message("✓ Created ", src_dir)
  }

  # Copy each R file
  for (f in r_files) {
    src_file <- file.path("R", f)
    dst_file <- file.path(src_dir, f)

    if (file.exists(src_file)) {
      file.copy(src_file, dst_file, overwrite = TRUE)
      message("  Copied ", f)
    } else {
      warning("  Source file not found: ", src_file)
    }
  }
  message("✓ Copied ", length(r_files), " R files to ", src_dir)
}

copy_config <- function(app_dir) {
  # config.yml should already be in inst/app, but verify
  config_path <- file.path(app_dir, "config.yml")
  if (!file.exists(config_path)) {
    # Try to copy from inst/app location (in case we're running from wrong dir)
    if (file.exists("inst/app/config.yml")) {
      file.copy("inst/app/config.yml", config_path)
      message("✓ Copied config.yml")
    } else {
      warning("config.yml not found!")
    }
  } else {
    message("✓ config.yml already present")
  }
}

setup_rsconnect <- function() {
  # Check for environment variables (CI deployment)
  account <- Sys.getenv("SHINYAPPS_ACCOUNT", "")
  token <- Sys.getenv("SHINYAPPS_TOKEN", "")
  secret <- Sys.getenv("SHINYAPPS_SECRET", "")

  if (nzchar(account) && nzchar(token) && nzchar(secret)) {
    message("Setting up rsconnect from environment variables...")
    rsconnect::setAccountInfo(
      name = account,
      token = token,
      secret = secret
    )
    message("✓ rsconnect configured for account: ", account)
    return(TRUE)
  }

  # Check for existing accounts (local deployment)
  accounts <- tryCatch(rsconnect::accounts(), error = function(e) NULL)
  if (!is.null(accounts) && nrow(accounts) > 0) {
    message("✓ Using existing rsconnect account: ", accounts$name[1])
    return(TRUE)
  }

  message("✗ No rsconnect account configured")
  message("  For CI: Set SHINYAPPS_ACCOUNT, SHINYAPPS_TOKEN, SHINYAPPS_SECRET")
  message("  For local: Run rsconnect::setAccountInfo(...)")
  return(FALSE)
}

# ============================================================================
# Main Deployment Process
# ============================================================================

main <- function() {
  # Verify we're in the right directory
  if (!file.exists("DESCRIPTION") || !dir.exists("inst/app")) {
    stop("Must run from spiralizer package root directory")
  }

  message("\n--- Preparing deployment files ---")

  # 1. Create Type: Shiny DESCRIPTION
  create_shiny_description(APP_DIR, GITHUB_REPO, DEPENDENCIES)

  # 2. Create .Rprofile fallback
  create_rprofile_fallback(APP_DIR)

  # 3. Copy R files as fallback
  copy_r_files(APP_DIR, R_FILES)

  # 4. Verify config.yml
  copy_config(APP_DIR)

  message("\n--- Setting up rsconnect ---")

  # 5. Setup rsconnect
  if (!setup_rsconnect()) {
    stop("rsconnect not configured")
  }

  message("\n--- Deploying to shinyapps.io ---")
  message("App directory: ", APP_DIR)
  message("App name: ", APP_NAME)

  # 6. Deploy
  tryCatch({
    rsconnect::deployApp(
      appDir = APP_DIR,
      appName = APP_NAME,
      appTitle = "Spiralizer",
      forceUpdate = TRUE,
      launch.browser = interactive()
    )
    message("\n✓ Deployment successful!")
    message("  URL: https://pjt222.shinyapps.io/spiralizer/")
  }, error = function(e) {
    message("\n✗ Deployment failed: ", e$message)
    stop(e)
  })
}

# Run main
main()
