# zzz.R - Package loading hooks
#
# Handles package initialization and cleanup.

#' @importFrom utils packageVersion
.onLoad <- function(libname, pkgname) {
  # Load Rcpp compiled code if available
  if (requireNamespace("Rcpp", quietly = TRUE)) {
    # The useDynLib directive in NAMESPACE handles loading
    # This is just for any additional initialization
  }

  invisible()
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    sprintf(
      "spiralizer %s - Create Voronoi diagrams from Fermat spirals",
      packageVersion("spiralizer")
    )
  )
}
