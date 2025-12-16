# Spiralizer Development Guide

## Prerequisites

- R 4.5.0 or higher
- RStudio (recommended) or any R IDE
- Git

## Quick Start

```r
# Clone and enter project
git clone https://github.com/pjt222/spiralizer.git
cd spiralizer

# Restore dependencies via renv
source(".Rprofile")
renv::restore()

# Run the Zen app
source("R/app.R")
```

The app will launch at `http://127.0.0.1:XXXX`.

## Project Structure

```
spiralizer/
├── R/
│   ├── app.R              # Main application entry point
│   ├── theme.R                # bslib theme configuration
│   ├── modules/
│   │   ├── ui_controls.R      # Control panel module
│   │   └── ui_plot.R          # Plot rendering module
│   └── utils/
│       ├── spiral_math.R      # Mathematical functions
│       ├── cache_manager.R    # Caching utilities
│       └── performance.R      # Performance monitoring
├── www/
│   ├── css/
│   │   └── overlay.css    # Custom zen effects
│   └── js/
│       └── interactions.js # Client-side interactions
├── tests/
│   ├── testthat/
│   │   └── test_spiral_math.R # Unit tests
│   └── benchmarks/
│       └── benchmark_spiral.R # Performance benchmarks
├── docs/                       # Documentation
├── app.R                       # Legacy app (for reference)
├── renv.lock                   # Dependency lockfile
└── .Rprofile                   # renv activation
```

## Development Workflow

### 1. Making Changes

Always source `.Rprofile` first to activate renv:

```r
source(".Rprofile")
```

Then work on your changes. The Shiny app supports live reloading.

### 2. Running Tests

```r
# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test file
testthat::test_file("tests/testthat/test_spiral_math.R")
```

### 3. Running Benchmarks

```r
source("tests/benchmarks/benchmark_spiral.R")
```

Results are saved to `tests/benchmarks/benchmark_results.rds`.

### 4. Adding Dependencies

```r
# Install new package
renv::install("package_name")

# Update lockfile
renv::snapshot()
```

### 5. Previewing Theme Changes

```r
library(bslib)
source("R/theme.R")
bs_theme_preview(spiralizer_theme)
```

## Key Files to Know

### `R/app.R`
Main application file. Contains:
- UI definition with bslib layout
- Server function with module initialization
- Session lifecycle handlers

### `R/theme.R`
Centralized bslib theme. Modify here to change:
- Colors (primary, secondary, background)
- Typography (fonts, sizes)
- Component styling (cards, buttons)

### `R/modules/ui_controls.R`
Control panel module. Key functions:
- `controls_ui(id)` - UI definition
- `controls_server(id)` - Server logic, returns reactive params

### `R/modules/ui_plot.R`
Plot module. Key functions:
- `plot_ui(id)` - Plot container
- `plot_server(id, params)` - Rendering and export

### `R/utils/spiral_math.R`
Core mathematical functions:
- `generate_fermat_spiral()` - Point generation
- `validate_spiral_params()` - Input validation
- `calculate_plot_limits()` - Dynamic plot bounds

### `R/utils/cache_manager.R`
Caching system:
- `compute_voronoi_cached()` - Memoized Voronoi computation
- `warm_cache()` - Pre-computation of common patterns
- `get_cache_stats()` - Cache monitoring

## Common Tasks

### Adding a New Preset

In `R/modules/ui_controls.R`:

```r
# 1. Add button in UI
actionButton(ns("preset_mypreset"), "My Preset", class = "btn-outline-primary btn-sm")

# 2. Add handler in server
observeEvent(input$preset_mypreset, {
  updateSliderInput(session, "angle_start", value = 42)
  updateSliderInput(session, "angle_end", value = 420)
  updateSliderInput(session, "point_density", value = 500)
})
```

### Adding a New Color Palette

In `R/modules/ui_controls.R`, update choices:

```r
selectInput(ns("color_palette"), NULL, choices = list(
  "Turbo" = "turbo",
  "My Palette" = "my_palette",  # Add here
  # ...
))
```

In `R/modules/ui_plot.R`, handle the palette:

```r
colors <- switch(params$color_palette,
  "my_palette" = colorRampPalette(c("#color1", "#color2"))(n),
  # ...
)
```

### Modifying the Theme

In `R/theme.R`:

```r
spiralizer_theme <- bs_theme(
  version = 5,
  preset = "darkly",
  primary = "#your_new_color",  # Change accent color
  # ...
)
```

### Adding Custom CSS

Add to `www/css/overlay.css`:

```css
/* Your custom styles */
.my-custom-class {
  /* styles */
}
```

## Debugging

### Common Issues

**"Package not found"**
```r
source(".Rprofile")
renv::restore()
```

**"tessellation not available"**
```r
renv::install("stla/tessellation")
```

**Slider values not updating**
- Check browser console for JavaScript errors
- Verify module namespace (`ns()`) is correct

### Useful Debug Commands

```r
# Check session info
sessionInfo()

# View cache stats
source("R/utils/cache_manager.R")
get_cache_stats()

# Profile performance
profvis::profvis({
  source("R/app.R")
})

# Check reactive dependencies
reactlog::reactlog_enable()
# Then run app and press Ctrl+F3
```

## Code Style

- Use descriptive variable names
- Follow tidyverse style guide
- Add roxygen comments to exported functions
- Keep functions focused (single responsibility)

## Before Committing

1. Run tests: `testthat::test_dir("tests/testthat")`
2. Check style: Consider using `lintr::lint_dir("R")`
3. Update documentation if needed
4. Snapshot dependencies: `renv::snapshot()`

## Deployment

See `deploy.R` for deployment to shinyapps.io:

```r
# Configure credentials first
rsconnect::setAccountInfo(
  name = "your_account",
  token = "your_token",
  secret = "your_secret"
)

# Deploy
source("deploy.R")
```

## Getting Help

- Check `TROUBLESHOOTING.md` for common issues
- Review architecture in `docs/ARCHITECTURE.md`
- Open an issue on GitHub
