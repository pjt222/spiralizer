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
    min_points: 3
  cache:
    max_size_mb: 100

development:
  inherits: default
  spiral:
    max_points: 10000

production:
  inherits: default
  cache:
    max_size_mb: 500
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

### Safe Default Pattern

Always provide fallback values using `%||%`:

```r
# Define %||% first (see r-package-structure.md)
`%||%` <- function(lhs, rhs) if (is.null(lhs)) rhs else lhs

# Load config with safe defaults
.config <- .load_config()

SPIRAL_MAX_POINTS <- .config$spiral$max_points %||% 5000L
CACHE_MAX_SIZE_MB <- .config$cache$max_size_mb %||% 100L
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

## Constants vs Runtime Configuration

### Compile-Time Constants

Values set at package load, used throughout:

```r
# R/constants.R
SPIRAL_MAX_POINTS <- .config$spiral$max_points %||% 5000L
```

**Pros**: Fast access, no function call overhead
**Cons**: Requires package reload to change

### Runtime Configuration

Values fetched on each access:

```r
get_max_points <- function() {
  config::get("spiral")$max_points %||% 5000L
}
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
