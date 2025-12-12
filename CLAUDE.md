# Spiralizer Project Memory

## Project Overview
Spiralizer is an R Shiny web application that creates beautiful Voronoi diagrams based on Fermat spirals. The app is deployed at [pjt222.shinyapps.io/spiralizer](https://pjt222.shinyapps.io/spiralizer/).

## Technical Stack
- **Language**: R (with optional Rcpp for performance)
- **Framework**: Shiny with bslib (Bootstrap 5, darkly theme)
- **Key Dependencies**:
  - `bslib`: Modern Bootstrap 5 UI framework
  - `tessellation`: Core package for Voronoi diagram creation
  - `viridisLite`: Color palette generation
  - `config`: Configuration management (default/development/production)
  - `memoise` + `cachem`: Computation caching
- **Dependency Management**: renv

## Current Architecture (bslib Zen Mode)

### UI Structure
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

### Key Design Decisions
1. **Pure bslib** - No custom JavaScript; all interactions via Shiny reactives
2. **Collapsible sidebar** - `sidebar(open = "desktop")` auto-collapses on mobile
3. **Minimal controls** - Only essential parameters exposed
4. **Spiral-first** - Visualization dominates; UI disappears when not needed

### File Structure
```
spiralizer/
├── R/
│   ├── app_zen.R              # Main application
│   ├── theme.R                # bslib theme + zen_colors + palette_choices
│   ├── modules/
│   │   ├── ui_controls.R      # Control panel module
│   │   └── ui_plot.R          # Plot output module
│   └── utils/
│       ├── constants.R        # Config-driven constants (loads config.yml)
│       ├── cache_manager.R    # Memoized Voronoi computation
│       ├── color_utils.R      # Centralized get_color_palette()
│       ├── spiral_math.R      # Fermat spiral + Voronoi computation
│       └── performance.R      # Performance mode detection
├── src/
│   └── spiral_rcpp.cpp        # C++ implementations (optional, ~10x speedup)
├── config.yml                 # Configuration (default/development/production)
├── www/
│   └── css/zen-overlay.css    # Minimal CSS enhancements
└── docs/                      # Documentation
```

## Configuration System

### config.yml Structure
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

development:
  # Smaller limits for testing

production:
  # Full limits for deployed app
```

### Switching Configurations
```r
# Set environment variable before loading
Sys.setenv(R_CONFIG_ACTIVE = "development")

# Or reload at runtime
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

## Key Insights

### bslib Best Practices
- Use `overflow: visible` on cards/sidebar for selectize dropdowns to escape
- `input_switch()` provides clean toggle UI for boolean options
- `layout_column_wrap()` for responsive button grids
- Bootstrap utility classes (`mb-3`, `py-2`, `gap-2`) reduce custom CSS

### Shiny Module Patterns
- Debounce slider inputs (300ms) to prevent computation spam
- Pass `reactiveValues` between modules for shared state
- Use `req()` to guard against NULL parameters
- Keep download handlers in same module as data source

### CSS Minimal Approach
- Let bslib/Bootstrap handle 90% of styling
- Custom CSS only for: glass-morphism, glow effects, slider theming
- Use CSS custom properties (`--zen-glow`, etc.) for consistency

### What NOT to Do
- Avoid custom JavaScript for basic interactions (bslib handles it)
- Don't over-engineer with caching for simple computations
- Skip presets/shortcuts in minimal UI - let users explore directly

## Running the App
```r
# From RStudio
source("R/app_zen.R")

# Or with explicit renv activation
source(".Rprofile")
source("R/app_zen.R")
```

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

## Documentation
See `docs/` folder:
- `ARCHITECTURE.md` - System design and data flow
- `DEVELOPMENT.md` - Developer setup guide
- `BSLIB_THEMING.md` - Theme customization
- `UI_DESIGN.md` - Design decisions