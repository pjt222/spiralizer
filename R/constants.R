# constants.R - Configuration constants for Spiralizer
#
# Loads configuration from config.yml using the config package.
# Supports different configurations for default, development, and production.
#
# Note: Do not use library(config) - use config::get() directly to avoid
# namespace conflicts with base::get() and base::merge().

# ═══════════════════════════════════════════════════════════════════════════
# LOAD CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

#' Get configuration
#'
#' Loads configuration from config.yml. The active configuration is determined
#' by the R_CONFIG_ACTIVE environment variable (default, development, production).
#'
#' @return List with configuration values
#' @keywords internal
.load_config <- function() {
  # Try multiple locations for config.yml
  config_paths <- c(
    here::here("config.yml"),
    here::here("inst", "app", "config.yml"),
    system.file("app", "config.yml", package = "spiralizer")
  )

  config_file <- NULL
  for (path in config_paths) {
    if (nzchar(path) && file.exists(path)) {
      config_file <- path
      break
    }
  }

  if (is.null(config_file)) {
    warning("config.yml not found, using hardcoded defaults")
    return(NULL)
  }

  config::get(file = config_file)
}
# Load config once at package/app load time
.spiralizer_config <- .load_config()

# ═══════════════════════════════════════════════════════════════════════════
# SPIRAL PARAMETERS
# ═══════════════════════════════════════════════════════════════════════════

#' Maximum number of points allowed for spiral generation
#' @export
SPIRAL_MAX_POINTS <- .spiralizer_config$spiral$max_points %||% 5000L

#' Minimum number of points required for Voronoi diagram
#' @export
SPIRAL_MIN_POINTS <- .spiralizer_config$spiral$min_points %||% 3L

#' Maximum angle range allowed
#' @export
SPIRAL_MAX_ANGLE_RANGE <- .spiralizer_config$spiral$max_angle_range %||% 1000L

#' Default number of points
#' @export
SPIRAL_DEFAULT_POINTS <- .spiralizer_config$spiral$default_points %||% 300L

# ═══════════════════════════════════════════════════════════════════════════
# UI SLIDER LIMITS
# ═══════════════════════════════════════════════════════════════════════════

#' Slider minimum for angles
#' @export
SLIDER_ANGLE_MIN <- .spiralizer_config$sliders$angle_min %||% 0L

#' Slider maximum for angles
#' @export
SLIDER_ANGLE_MAX <- .spiralizer_config$sliders$angle_max %||% 1000L

#' Slider minimum for density
#' @export
SLIDER_DENSITY_MIN <- .spiralizer_config$sliders$density_min %||% 3L

#' Slider maximum for density
#' @export
SLIDER_DENSITY_MAX <- .spiralizer_config$sliders$density_max %||% 2000L

# ═══════════════════════════════════════════════════════════════════════════
# PERFORMANCE SETTINGS
# ═══════════════════════════════════════════════════════════════════════════

#' Debounce delay in milliseconds for slider inputs
#' @export
DEBOUNCE_MS <- .spiralizer_config$reactive$debounce_ms %||% 300L

#' Default plot limits when calculation fails
#' @export
DEFAULT_PLOT_LIMITS <- .spiralizer_config$plot$default_limits %||% c(-10, 10)

#' Plot limit padding factor (10% padding)
#' @export
PLOT_LIMIT_PADDING <- .spiralizer_config$plot$limit_padding %||% 1.1

# ═══════════════════════════════════════════════════════════════════════════
# EXPORT SETTINGS
# ═══════════════════════════════════════════════════════════════════════════

#' PNG export dimensions (pixels)
#' @export
EXPORT_PNG_SIZE <- .spiralizer_config$export$png_size %||% 3000L

#' PNG export resolution (DPI)
#' @export
EXPORT_PNG_RES <- .spiralizer_config$export$png_resolution %||% 300L

#' SVG export dimensions (inches)
#' @export
EXPORT_SVG_SIZE <- .spiralizer_config$export$svg_size %||% 10L

# ═══════════════════════════════════════════════════════════════════════════
# CACHE SETTINGS
# ═══════════════════════════════════════════════════════════════════════════

#' Cache maximum size in MB
#' @export
CACHE_MAX_SIZE_MB <- .spiralizer_config$cache$max_size_mb %||% 100L

#' Cache maximum age in seconds
#' @export
CACHE_MAX_AGE_SECONDS <- .spiralizer_config$cache$max_age_seconds %||% 3600L

# ═══════════════════════════════════════════════════════════════════════════
# PALETTE SETTINGS
# ═══════════════════════════════════════════════════════════════════════════

#' Default color palette
#' @export
DEFAULT_PALETTE <- .spiralizer_config$palette$default %||% "turbo"

# ═══════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

#' Get current configuration name
#'
#' Returns the name of the active configuration (default, development, production).
#'
#' @return Character string with active config name
#' @export
get_config_name <- function() {
  Sys.getenv("R_CONFIG_ACTIVE", "default")
}

#' Reload configuration
#'
#' Reloads configuration from config.yml. Useful after changing the config file.
#'
#' @export
reload_config <- function() {
  .spiralizer_config <<- .load_config()
  message(sprintf("Configuration reloaded: %s", get_config_name()))
}
