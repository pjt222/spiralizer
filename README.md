# 🌀 Spiralizer

Create beautiful Voronoi diagrams based on Fermat spirals.

[![R-CMD-check](https://github.com/pjt222/spiralizer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pjt222/spiralizer/actions/workflows/R-CMD-check.yaml)

**Live Demo:** [pjt222.shinyapps.io/spiralizer](https://pjt222.shinyapps.io/spiralizer/)

## Gallery

| Start=111, End=222, Density=333 | Start=0, End=107, Density=179 |
|:--:|:--:|
| ![example1](https://user-images.githubusercontent.com/47758568/180395339-f43c2d69-273f-401b-88b2-36edd3e7d6cb.png) | ![example2](https://user-images.githubusercontent.com/47758568/180396059-ceabcccf-4ea9-43cf-8d06-4a1e69b5e18e.png) |

| Start=0, End=666, Density=999 | Start=333, End=666, Density=999 |
|:--:|:--:|
| ![example3](https://user-images.githubusercontent.com/47758568/180396486-226a9830-687c-4426-926d-1636d81b4fc4.png) | ![example4](https://user-images.githubusercontent.com/47758568/180396769-f9108f49-e1ac-45ea-ac99-0fb8b6d129aa.png) |

## Features

- **Interactive controls** - Real-time parameter adjustment with debounced sliders
- **Multiple color palettes** - Turbo, Viridis, Plasma, Inferno, Magma, Cividis
- **Palette inversion** - Flip color direction with a switch
- **Collapsible sidebar** - Focus on the art, hide controls when not needed
- **Export** - High-resolution PNG (3000x3000) and SVG vector formats
- **Dark zen theme** - Minimalist UI with glass-morphism effects

## Quick Start

```r
# Clone and run
git clone https://github.com/pjt222/spiralizer.git
cd spiralizer

# Restore dependencies
source(".Rprofile")
renv::restore()

# Run the app
source("R/app.R")
```

## How It Works

1. **Fermat Spiral** - Points generated using `x = √θ·cos(θ)`, `y = √θ·sin(θ)`
2. **Delaunay Triangulation** - Optimal triangulation via `tessellation` package
3. **Voronoi Tessellation** - Dual of Delaunay creates the cell pattern
4. **Color Mapping** - Cells colored with viridisLite palettes

## Tech Stack

- **R Shiny** with **bslib** (Bootstrap 5, darkly theme)
- **tessellation** for Voronoi computation
- **viridisLite** for color palettes
- **renv** for dependency management

## Project Structure

```
spiralizer/
├── R/                      # All R code (flat structure)
│   ├── app.R               # Main application
│   ├── theme.R             # bslib theme
│   ├── ui_controls.R       # Control panel module
│   ├── ui_plot.R           # Plot rendering module
│   └── spiral_math.R       # Mathematical functions
├── inst/app/               # Deployment entry point
├── docs/                   # Documentation
└── tests/                  # Test suite
```

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) - Developer guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

## Acknowledgments

- [tessellation](https://github.com/stla/tessellation) by Stéphane Laurent
- [viridisLite](https://cran.r-project.org/package=viridisLite) for color palettes
- [bslib](https://rstudio.github.io/bslib/) for modern Shiny UI

## License

MIT
