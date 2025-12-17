# constants.R - Configuration access for Spiralizer
#
# Provides config-only access via get_setting() function.
# All values come from config.yml with fallback defaults.
#
# Note: Do not use library(config) - use config::get() directly to avoid
# namespace conflicts with base::get() and base::merge().

# ═══════════════════════════════════════════════════════════════════════════
# LOAD CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

#' Load configuration from config.yml
#'
#' @return List with configuration values or NULL if not found
#' @keywords internal
.load_config <- function() {

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
    return(list())
  }

  config::get(file = config_file)
}

# Package-level config cache
.spiralizer_config <- .load_config()

# ═══════════════════════════════════════════════════════════════════════════
# DEFAULT VALUES
# ═══════════════════════════════════════════════════════════════════════════

#' Default configuration values (fallbacks when config.yml missing)
#' @keywords internal
.defaults <- list(

  spiral = list(
    max_points = 5000L,
    min_points = 50L,
    max_angle_range = 1000L,
    default_points = 300L
  ),
  sliders = list(
    angle_min = 0L,
    angle_max = 1000L,
    density_min = 50L,
    density_max = 2000L
  ),
  ui = list(
    sidebar_width = 320L,
    animation_interval_ms = 2000L,
    slider_step_points = 50L,
    default_angle_end = 100L
  ),
  reactive = list(
    debounce_ms = 300L
  ),
  plot = list(
    default_limits = c(-10, 10),
    limit_padding = 1.1
  ),
  export = list(
    png_size = 3000L,
    png_resolution = 300L,
    svg_size = 10L
  ),
  cache = list(
    max_size_mb = 100L,
    max_age_seconds = 3600L
  ),

  palette = list(
    default = "turbo"
  ),
  estimation = list(
    base_time_ms = 50,
    per_point_time_ms = 0.3
  ),
  performance_modes = list(
    high = list(max_points = 5000L, debounce_ms = 200L, cache_size_mb = 200L),
    medium = list(max_points = 2000L, debounce_ms = 300L, cache_size_mb = 100L),
    low = list(max_points = 1000L, debounce_ms = 500L, cache_size_mb = 50L)
  )
)

# ═══════════════════════════════════════════════════════════════════════════
# CONFIG ACCESS FUNCTION
# ═══════════════════════════════════════════════════════════════════════════

#' Get Configuration Setting
#'
#' Retrieves a configuration value from config.yml with fallback to defaults.
#' Uses dot notation for nested access: get_setting("spiral", "max_points")
#'
#' @param ... Path components to the setting (e.g., "spiral", "max_points")
#' @return The configuration value, or the default if not found
#' @export
#'
#' @examples
#' \dontrun{
#' get_setting("spiral", "max_points")
#' get_setting("ui", "sidebar_width")
#' get_setting("performance_modes", "high")
#' }
get_setting <- function(...) {
  keys <- list(...)


  # Navigate config

  value <- .spiralizer_config

  for (key in keys) {
    if (is.null(value) || !is.list(value)) {
      value <- NULL
      break
    }
    value <- value[[key]]
  }

  # If not found in config, use defaults

  if (is.null(value)) {
    value <- .defaults
    for (key in keys) {
      if (is.null(value) || !is.list(value)) {
        value <- NULL
        break
      }
      value <- value[[key]]
    }
  }

  value
}

# ═══════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

#' Get Current Configuration Name
#'
#' Returns the name of the active configuration (default, development, production).
#'
#' @return Character string with active config name
#' @export
get_config_name <- function() {
  Sys.getenv("R_CONFIG_ACTIVE", "default")
}

#' Reload Configuration
#'
#' Reloads configuration from config.yml. Call this after changing the config
#' file or switching environments. In deployed apps, a container restart
#' achieves the same effect.
#'
#' @export
reload_config <- function() {
  .spiralizer_config <<- .load_config()
  message(sprintf("Configuration reloaded: %s", get_config_name()))
}
