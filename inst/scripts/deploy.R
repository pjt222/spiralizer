# Deploy Spiralizer to shinyapps.io
#
# This script deploys the Spiralizer app to shinyapps.io.
# Requires: rsconnect package and configured account.

# Load renv
source(".Rprofile")

# Load required libraries
library(rsconnect)

# Check account info
tryCatch({
  accounts <- rsconnect::accounts()
  print(accounts)
}, error = function(e) {
  message("No accounts configured. Please run rsconnect::setAccountInfo()")
})

# Deploy the app from inst/app directory
message("Deploying Spiralizer to shinyapps.io...")

tryCatch({
  rsconnect::deployApp(
    appDir = "inst/app",
    appName = "spiralizer",
    appTitle = "Spiralizer",
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
