# Spiralizer Project Memory

## Project Overview
Spiralizer is an R Shiny web application that creates beautiful Voronoi diagrams based on Fermat spirals. The app is deployed at [pjt222.shinyapps.io/spiralizer](https://pjt222.shinyapps.io/spiralizer/).

## Technical Stack
- **Language**: R
- **Framework**: Shiny with bslib (Bootstrap 5, darkly theme)
- **Key Dependencies**:
  - `bslib`: Modern Bootstrap 5 UI framework
  - `tessellation`: Core package for Voronoi diagram creation
  - `viridisLite`: Color palette generation
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
│   ├── theme.R                # bslib theme configuration
│   ├── modules/
│   │   ├── ui_controls.R      # Control panel module
│   │   └── ui_plot.R          # Plot output module
│   └── utils/
│       ├── spiral_math.R      # Fermat spiral + Voronoi computation
│       └── performance.R      # Performance mode detection
├── www/
│   └── css/zen-overlay.css    # Minimal CSS enhancements
└── docs/                      # Documentation
```

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