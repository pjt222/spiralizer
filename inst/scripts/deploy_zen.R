# Deploy Zen Spiralizer to shinyapps.io

# Load renv
source(".Rprofile")

# Load required libraries
library(rsconnect)

# First, let's create a deployment version of the app that includes all necessary files
# We'll create app.R in the root that sources our zen app

# Create main app.R that will be deployed
app_content <- '
# Spiralizer Zen Mode - Main entry point for deployment

# Source all necessary files
source("R/modules/ui_controls.R")
source("R/modules/ui_plot.R")
source("R/utils/spiral_math.R")
source("R/utils/cache_manager.R")
source("R/utils/performance.R")
source("R/app_zen.R")
'

writeLines(trimws(app_content), "app.R")

# Check account info
tryCatch({
  accounts <- rsconnect::accounts()
  print(accounts)
}, error = function(e) {
  message("No accounts configured. Please run rsconnect::setAccountInfo()")
})

# Deploy the app
message("Deploying Zen Spiralizer to shinyapps.io...")

# List files to include in deployment
app_files <- c(
  "app.R",
  "R/app_zen.R",
  "R/modules/ui_controls.R", 
  "R/modules/ui_plot.R",
  "R/utils/spiral_math.R",
  "R/utils/cache_manager.R",
  "R/utils/performance.R",
  "www/css/zen-theme.css",
  "www/js/zen-interactions.js"
)

# Deploy
tryCatch({
  rsconnect::deployApp(
    appDir = ".",
    appFiles = app_files,
    appName = "your-zen-app-name",  # Change this to your desired app name
    appTitle = "Spiralizer Zen Mode",
    forceUpdate = TRUE,
    launch.browser = TRUE
  )
}, error = function(e) {
  message("Deployment failed: ", e$message)
  message("\nTo set up deployment:")
  message("1. Create account at https://www.shinyapps.io/")
  message("2. Get your token from Account > Tokens")
  message("3. Run: rsconnect::setAccountInfo(name='YOUR_ACCOUNT', token='YOUR_TOKEN', secret='YOUR_SECRET')")
})