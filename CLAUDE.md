# Spiralizer Project Memory

## Project Overview
Spiralizer is an R package and Shiny web application that creates beautiful Voronoi diagrams based on Fermat spirals. The app is deployed at [pjt222.shinyapps.io/spiralizer](https://pjt222.shinyapps.io/spiralizer/).

## Technical Stack
- **Language**: R (with optional Rcpp for performance)
- **Framework**: Shiny with bslib (Bootstrap 5, darkly theme)
- **Package Structure**: CRAN-compatible R package
- **Key Dependencies**:
  - `bslib`: Modern Bootstrap 5 UI framework
  - `tessellation`: Core package for Voronoi diagram creation
  - `viridisLite`: Color palette generation
  - `config`: Configuration management (default/development/production)
  - `memoise` + `cachem`: Computation caching
- **Dependency Management**: renv (for development), DESCRIPTION (for package)

## Package Structure (CRAN-compatible)

**Important**: R packages require a flat `R/` directory - no subdirectories allowed.
See `docs/development-guides/r-package-structure.md` for details.

```
spiralizer/
├── DESCRIPTION              # Package metadata and dependencies
├── NAMESPACE                # Exports and imports
├── LICENSE                  # MIT license
├── README.md                # Package documentation
├── .Rbuildignore            # Files to exclude from R CMD build
│
├── R/                       # Package R code (FLAT structure required)
│   ├── aaa-utils.R          # Loaded first: %||% operator
│   ├── RcppExports.R        # Auto-generated Rcpp wrappers
│   ├── constants.R          # Config-driven constants
│   ├── color_utils.R        # Centralized get_color_palette()
│   ├── spiral_math.R        # Fermat spiral + Voronoi computation
│   ├── cache_manager.R      # Memoized Voronoi computation (lazy init)
│   ├── performance.R        # Performance mode detection
│   ├── theme.R              # bslib theme + zen_colors + palette_choices
│   ├── ui_controls.R        # Control panel module
│   ├── ui_plot.R            # Plot output module
│   ├── app_zen.R            # Main app UI/server + spiralizer_app()
│   ├── run_app.R            # run_spiralizer() launcher function
│   └── zzz.R                # Loaded last: package hooks
│
├── inst/                    # Installed files
│   ├── app/                 # Shiny app for deployment
│   │   ├── app.R            # App entry point
│   │   ├── config.yml       # Configuration file
│   │   └── www/             # Static assets
│   │       ├── css/
│   │       └── js/
│   ├── archive/             # Legacy code
│   │   └── app_legacy_semantic.R
│   ├── docs/                # Documentation (installed with package)
│   └── scripts/             # Utility scripts
│       ├── deploy_zen.R
│       └── run_zen.R
│
├── src/                     # C++ source (Rcpp)
│   ├── spiral_rcpp.cpp      # C++ implementations
│   └── RcppExports.cpp      # Auto-generated registration
│
├── man/                     # Generated documentation (roxygen2)
├── tests/                   # Test suite
│   ├── testthat/
│   └── testthat.R
├── docs/                    # Documentation
│   ├── development-guides/  # Development best practices
│   └── *.md                 # Architecture, design docs
│
├── renv/                    # renv library (development)
├── renv.lock                # renv lockfile
└── spiralizer.Rproj         # RStudio project
```

## Running the App

### As installed package
```r
# Install the package
devtools::install()

# Run the app
library(spiralizer)
run_spiralizer()

# Or get the app object
app <- spiralizer_app()
shiny::runApp(app)
```

### Development mode
```r
# From project root
source(".Rprofile")  # Activate renv
shiny::runApp("inst/app")

# Or source directly
source("inst/app/app.R")
```

## UI Structure
```
page_navbar
├── nav_spacer()
└── nav_panel (main)
    └── layout_sidebar
        ├── sidebar (collapsible, 320px)
        │   └── zen_controls_ui
        │       ├── card: Spiral Shape (Start, End, Density sliders)
        │       └── card: Color (palette dropdown + invert switch)
        └── zen_plot_ui
            ├── plotOutput (fills viewport)
            └── export buttons (PNG, SVG)
```

## Key Design Decisions
1. **Pure bslib** - No custom JavaScript; all interactions via Shiny reactives
2. **Collapsible sidebar** - `sidebar(open = "desktop")` auto-collapses on mobile
3. **Minimal controls** - Only essential parameters exposed
4. **Spiral-first** - Visualization dominates; UI disappears when not needed
5. **CRAN-compatible** - Proper package structure for distribution

## Configuration System

Configuration is stored in `inst/app/config.yml`:

```yaml
default:
  spiral:
    max_points: 5000
    min_points: 3
    default_points: 300
  sliders:
    angle_min: 0
    angle_max: 1000
    density_min: 3
    density_max: 2000
  reactive:
    debounce_ms: 300
  cache:
    max_size_mb: 100
    max_age_seconds: 3600
  palette:
    default: "turbo"
  export:
    png_size: 3000
    png_resolution: 300
    svg_size: 10
```

### Switching Configurations
```r
Sys.setenv(R_CONFIG_ACTIVE = "development")
reload_config()
get_config_name()  # Returns active config name
```

### Important: config Package Usage
Do NOT use `library(config)` - it masks `base::get()` and `base::merge()`.
Always use `config::get()` directly.

## Performance Enhancements

### Rcpp C++ Backend (Optional)
The `src/spiral_rcpp.cpp` file provides C++ implementations:
- `generate_spiral_cpp()` - ~10x faster spiral point generation
- `calculate_limits_cpp()` - Fast plot limit calculation

The R code auto-detects if Rcpp functions are available and uses them.

### Caching Strategy
- `memoise` + `cachem` for Voronoi computation caching
- Cache size and TTL configurable via `config.yml`
- Debounced slider inputs (300ms default) prevent computation spam

## Key Exports

### App Functions
- `run_spiralizer()` - Launch the Shiny app
- `spiralizer_app()` - Get app object
- `zen_ui()`, `zen_server()` - UI and server components

### Spiral Math
- `generate_fermat_spiral()` - Generate spiral points
- `compute_voronoi()` - Compute Voronoi diagram
- `validate_spiral_params()` - Parameter validation

### Theme
- `spiralizer_theme` - bslib theme object
- `zen_colors` - Color palette list
- `palette_choices` - Available color palettes

## Fermat Spiral Formula
```
x = √θ * cos(θ)
y = √θ * sin(θ)
```
Where θ ranges from `angle_start` to `angle_end` with `point_density` samples.

## Color Palettes
- Turbo, Viridis, Plasma, Inferno, Magma, Cividis (viridisLite)
- Zen Mono (black → accent gradient)
- All palettes support inversion via `rev(colors)`

## Code Style
- Descriptive variable names
- roxygen2-style documentation comments
- Consistent section headers with box-drawing characters
- No `library()` calls in R/ files (use `@import` roxygen2 tags)

## Documentation

### General Documentation
See `docs/` folder:
- `ARCHITECTURE.md` - System design and data flow
- `DEVELOPMENT.md` - Developer setup guide
- `BSLIB_THEMING.md` - Theme customization
- `UI_DESIGN.md` - Design decisions
- `TROUBLESHOOTING.md` - Common issues and solutions

### Development Guides
See `docs/development-guides/` folder:
- `r-package-structure.md` - Lessons learned from R package development
- `rcpp-integration.md` - C++ integration via Rcpp
- `config-management.md` - Configuration management patterns
