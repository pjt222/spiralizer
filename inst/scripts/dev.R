# Development launcher - loads package and runs app
# Usage: source("inst/scripts/dev.R")
#
# Prerequisites (install via renv):
#   renv::install("devtools")
#
# Note: Uses load_all() for fast iteration (no C++ recompilation).
#       Use devtools::install() manually if you changed C++ code.

if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("[dev] devtools not found. Install with: renv::install(\"devtools\")")
}

message("[dev] Loading spiralizer (dev mode)...")
devtools::load_all(quiet = FALSE)

message("[dev] Launching app...")
run_spiralizer()
