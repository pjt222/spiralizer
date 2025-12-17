# Configuration Management in R Packages

This guide covers strategies for managing configuration in R packages, especially for Shiny applications.

## The config Package

### Basic Usage

The `config` package reads YAML configuration files with environment-based profiles:

```yaml
# inst/app/config.yml
default:
  spiral:
    max_points: 5000
    min_points: 50
    default_points: 300
  sliders:
    angle_min: 0
    angle_max: 1000
    density_min: 50
    density_max: 2000
  ui:
    sidebar_width: 320
    animation_interval_ms: 2000
    slider_step_points: 50
    default_angle_end: 100
  cache:
    max_size_mb: 100
  estimation:
    base_time_ms: 50
    per_point_time_ms: 0.3
  performance_modes:
    high:
      max_points: 5000
      debounce_ms: 200
      cache_size_mb: 200

development:
  spiral:
    max_points: 2000
  cache:
    max_size_mb: 50

production:
  cache:
    max_size_mb: 200
```

### Important: Namespace Conflicts

**Never use `library(config)`** - it masks `base::get()` and `base::merge()`:

```r
# WRONG - causes namespace conflicts
library(config)
settings <- get()  # Calls config::get, not base::get!

# CORRECT - always use explicit namespace
settings <- config::get(file = "config.yml")
base_value <- base::get("my_var")
```

## Loading Configuration in Packages

### Challenge: Finding config.yml

During package loading, the config file location varies:
- **Development**: Project root or `inst/app/`
- **Installed**: `system.file("app", "config.yml", package = "pkg")`
- **R CMD check**: Temporary directory

### Solution: Multiple Path Search

```r
.load_config <- function() {
  config_paths <- c(
    here::here("config.yml"),                                    # Dev root
    here::here("inst", "app", "config.yml"),                    # Dev inst
    system.file("app", "config.yml", package = "spiralizer")    # Installed
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
```

### Safe Default Pattern (get_setting)

Use `get_setting()` for clean config access with fallback defaults:

```r
# Access config values with automatic fallback to defaults
get_setting("spiral", "max_points")    # Returns 5000 if not in config
get_setting("cache", "max_size_mb")    # Returns 100 if not in config
get_setting("performance_modes", "high")  # Returns nested config

# Defaults are defined in .defaults list in constants.R
.defaults <- list(
  spiral = list(max_points = 5000L, min_points = 50L, ...),
  cache = list(max_size_mb = 100L, ...),
  ...
)
```

## Environment-Based Configuration

### Switching Environments

```r
# Set before loading package/running app
Sys.setenv(R_CONFIG_ACTIVE = "production")

# In code
get_config_name <- function() {
  Sys.getenv("R_CONFIG_ACTIVE", "default")
}
```

### Reloading Configuration

```r
reload_config <- function() {
  .spiralizer_config <<- .load_config()
  message(sprintf("Configuration reloaded: %s", get_config_name()))
}
```

## Config-Only Approach (Recommended)

Spiralizer uses a config-only approach with `get_setting()`:

```r
# All values come from config.yml via get_setting()
width = get_setting("ui", "sidebar_width")
min_points = get_setting("spiral", "min_points")

# For deployment:
# - Container restart reloads config automatically
# - Development: call reload_config() to pick up changes
```

**Pros**:
- Single source of truth (config.yml)
- No duplicate fallback values scattered in code
- Container restart picks up config changes
- Clean, readable code

**Cons**:
- Slight function call overhead (negligible in practice)

### Legacy: Compile-Time Constants

The old approach used exported constants:

```r
# OLD - constants loaded at package load time
SPIRAL_MAX_POINTS <- .config$spiral$max_points %||% 5000L
# Required package reload to change
```

**Pros**: Can change without reload
**Cons**: Slower, file I/O on each call

### Hybrid Approach

Use constants with explicit reload capability:

```r
# Constants for performance
SPIRAL_MAX_POINTS <- 5000L

# Reload function for development
reload_config <- function() {
  cfg <- .load_config()
  SPIRAL_MAX_POINTS <<- cfg$spiral$max_points %||% 5000L
}
```

## Shiny-Specific Configuration

### Reactive Configuration

For Shiny apps, consider reactive config values:

```r
# In server
config_values <- reactiveValues(
  max_points = SPIRAL_MAX_POINTS,
  cache_size = CACHE_MAX_SIZE_MB
)

# Update reactively
observeEvent(input$reload_config, {
  cfg <- .load_config()
  config_values$max_points <- cfg$spiral$max_points
})
```

### Config in UI

Pass config values to UI at startup:

```r
app_ui <- function() {
  page_navbar(
    sliderInput("density", "Points",
      min = SLIDER_DENSITY_MIN,
      max = SLIDER_DENSITY_MAX,
      value = SPIRAL_DEFAULT_POINTS
    )
  )
}
```

## Testing with Configuration

### Mock Configuration

```r
test_that("handles custom config", {
  withr::local_envvar(R_CONFIG_ACTIVE = "test")

  # Or mock the config directly
  mockery::stub(my_function, ".config$max_points", 100)

  result <- my_function()
  expect_equal(result, expected_value)
})
```

### Test-Specific Config Profile

```yaml
# config.yml
test:
  inherits: default
  spiral:
    max_points: 100  # Smaller for faster tests
  cache:
    max_size_mb: 10
```

## Security Considerations

### Sensitive Values

Never store secrets in config.yml:

```yaml
# WRONG - secrets in config
default:
  api_key: "sk-secret123"

# CORRECT - use environment variables
default:
  api_key_env: "MY_API_KEY"
```

```r
# Access via environment
api_key <- Sys.getenv(.config$api_key_env, "")
```

### .gitignore

```gitignore
# Ignore local config overrides
config.local.yml
.Renviron
```

## Summary

| Approach | Use Case | Reload Required |
|----------|----------|-----------------|
| Constants | Performance-critical values | Yes |
| config::get() | Rarely changing values | No |
| Reactive values | Shiny dynamic config | No |
| Environment vars | Secrets, deployment config | App restart |

Best practices:
1. Use `config::get()` explicitly, never `library(config)`
2. Search multiple paths for config file
3. Always provide `%||%` fallback defaults
4. Use environment variables for secrets
5. Consider reload capability for development
