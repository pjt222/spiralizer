# R Package Structure: Lessons Learned

This guide documents key insights from converting a Shiny application to a CRAN-compatible R package.

## Directory Structure Constraints

### R/ Directory Must Be Flat

**Critical**: R packages do NOT support subdirectories within `R/`. All `.R` files must be in the root `R/` directory.

```
# WRONG - subdirectories not supported
R/
  modules/
    ui_controls.R    # Will NOT be loaded
    ui_plot.R
  utils/
    constants.R      # Will NOT be loaded
    helpers.R

# CORRECT - flat structure
R/
  aaa-utils.R
  constants.R
  ui_controls.R
  ui_plot.R
  helpers.R
  zzz.R
```

While `R CMD build` includes subdirectory files in the tarball, they are **not sourced** during package loading unless explicitly listed in the `Collate` field - and even then, the `Collate` field doesn't support path separators.

### File Loading Order

R sources files in alphabetical order. Use naming conventions to control load order:

| File Pattern | Purpose |
|--------------|---------|
| `aaa-*.R` | Loaded first (operators, utilities) |
| `zzz.R` | Loaded last (hooks, startup) |

### Collate Field

Use the `Collate` field in DESCRIPTION when load order matters:

```yaml
Collate:
    'aaa-utils.R'      # Define operators first
    'RcppExports.R'    # Rcpp bindings
    'constants.R'      # Uses %||% from aaa-utils.R
    'spiral_math.R'
    'cache_manager.R'  # Uses constants
    'theme.R'
    'ui_controls.R'
    'ui_plot.R'
    'app_zen.R'
    'run_app.R'
    'zzz.R'            # Always last
```

## Top-Level Code Execution

### Avoid Side Effects at Load Time

Code at the top level of R files is executed when the package namespace is loaded. Avoid:

```r
# WRONG - executes at load time, may fail
spiral_cache <- cachem::cache_mem(
  max_size = CACHE_MAX_SIZE_MB * 1024^2  # Constants may not exist yet!
)

# WRONG - config may not be found during R CMD check
.config <- config::get(file = "config.yml")
```

### Use Lazy Initialization

Defer expensive or potentially failing operations:

```r
# CORRECT - lazy initialization
.cache_env <- new.env(parent = emptyenv())

.get_spiral_cache <- function() {
  if (is.null(.cache_env$spiral_cache)) {
    .cache_env$spiral_cache <- cachem::cache_mem(
      max_size = CACHE_MAX_SIZE_MB * 1024^2,
      max_age = CACHE_MAX_AGE_SECONDS
    )
  }
  .cache_env$spiral_cache
}
```

## Operators and Dependencies

### The %||% Null Coalescing Operator

The `%||%` operator (null coalescing) is:
- Available in base R since R 4.4.0
- Available from `rlang` package
- NOT available by default in older R versions

For packages supporting R < 4.4.0, define it locally:

```r
# R/aaa-utils.R - loaded first alphabetically
`%||%` <- function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}
```

### Namespace Imports

Use `importFrom()` for specific functions to avoid namespace pollution:

```r
# NAMESPACE
importFrom(grDevices, dev.off, png, svg, colorRampPalette)
importFrom(graphics, par, text)
importFrom(utils, packageVersion)
```

## Roxygen2 Best Practices

### Common Parsing Issues

Roxygen2 can misparse comments. Ensure:

1. `@importFrom` has correct syntax: `@importFrom package function1 function2`
2. Descriptions don't contain roxygen-like patterns
3. Multi-line descriptions use proper continuation

```r
# WRONG - description text parsed as import
#' @importFrom Creates the main UI container

# CORRECT
#' Creates the main UI container
#' @importFrom shiny div tags
```

### Exporting Variables vs Functions

Both functions and variables can be exported:

```r
#' Maximum number of spiral points
#' @export
SPIRAL_MAX_POINTS <- 5000L
```

## inst/ Directory for App Assets

Shiny apps in packages go in `inst/app/`:

```
inst/
  app/
    app.R           # Entry point
    config.yml      # Configuration
    www/
      css/
      js/
```

Access installed files with:

```r
system.file("app", "config.yml", package = "spiralizer")
```

## Testing Considerations

### Don't Source Package Files in Tests

```r
# WRONG - paths change after installation
source(here::here("R/utils/constants.R"))

# CORRECT - use the installed package
library(spiralizer)
```

### Test Parameter Boundaries

Ensure tests respect validation constraints:

```r
# If SPIRAL_MIN_POINTS is 3, don't test with 2 points
points <- generate_fermat_spiral(0, 10, SPIRAL_MIN_POINTS)  # Use constant
```

## R Version Dependencies

Certain syntax requires minimum R versions:

| Feature | Minimum R Version |
|---------|-------------------|
| Native pipe `\|>` | R 4.1.0 |
| Lambda shorthand `\(x)` | R 4.1.0 |
| `%\|\|%` in base | R 4.4.0 |
| RDS version 3 | R 3.5.0 |

Declare in DESCRIPTION:

```yaml
Depends:
    R (>= 4.1.0)
```

## Summary Checklist

- [ ] All R files in flat `R/` directory
- [ ] `Collate` field if load order matters
- [ ] No side effects at top-level
- [ ] Lazy initialization for expensive operations
- [ ] Define `%||%` if supporting R < 4.4.0
- [ ] Proper `importFrom()` declarations
- [ ] App assets in `inst/app/`
- [ ] Tests use installed package, not source files
- [ ] R version dependency declared
