# Spiralizer Architecture

## Overview

Spiralizer is a modular R Shiny application for creating interactive Voronoi diagrams based on Fermat spirals. The architecture emphasizes performance, maintainability, and a clean separation of concerns.

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                           │
│  ┌─────────────────────┐    ┌─────────────────────────────────┐ │
│  │   Controls Module   │    │        Plot Module              │ │
│  │  (ui_controls.R)    │    │       (ui_plot.R)               │ │
│  │                     │    │                                 │ │
│  │  - Angle sliders    │───▶│  - Voronoi visualization       │ │
│  │  - Color palette    │    │  - Export handlers              │ │
│  │  - Preset buttons   │    │  - Loading overlay              │ │
│  └─────────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION CORE                           │
│                       (app_zen.R)                               │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   theme.R    │  │ Module Init  │  │  Observers   │          │
│  │  (bslib)     │  │  & Routing   │  │ & Handlers   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       UTILITIES LAYER                           │
│  ┌──────────────────┐ ┌──────────────────┐ ┌─────────────────┐ │
│  │  spiral_math.R   │ │ cache_manager.R  │ │  performance.R  │ │
│  │                  │ │                  │ │                 │ │
│  │ - Fermat spiral  │ │ - Memoise cache  │ │ - Time tracking │ │
│  │ - Validation     │ │ - Cache warming  │ │ - System info   │ │
│  │ - Plot limits    │ │ - Cache stats    │ │ - Perf mode     │ │
│  └──────────────────┘ └──────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EXTERNAL PACKAGES                           │
│  tessellation  │  viridisLite  │  memoise  │  bslib  │  shiny  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
User Input (slider change)
    │
    ▼
Debounce (300ms)
    │
    ▼
Parameter Validation (validate_spiral_params)
    │
    ▼
Cache Key Generation (create_cache_key)
    │
    ├──▶ Cache HIT: Return cached result (~1ms)
    │
    └──▶ Cache MISS:
            │
            ▼
         Generate Spiral Points (generate_fermat_spiral)
            │
            ▼
         Compute Voronoi (tessellation::delaunay → voronoi)
            │
            ▼
         Store in Cache
            │
            ▼
         Return Result
    │
    ▼
Calculate Plot Limits
    │
    ▼
Render Visualization
    │
    ▼
Update Performance Indicator
```

## Module Structure

### Controls Module (`R/modules/ui_controls.R`)

**Purpose**: Manages all user input controls and preset patterns.

**UI Elements**:
- Three sliders: Start Angle, End Angle, Point Density
- Color palette selector
- Preset pattern buttons (Simple, Classic, Complex, Ethereal, Random)

**Returns**: Reactive values object with current parameters

```r
zen_controls_server(id) → reactiveValues(
  angle_start,
  angle_end,
  point_density,
  color_palette
)
```

### Plot Module (`R/modules/ui_plot.R`)

**Purpose**: Handles spiral visualization and export functionality.

**Inputs**: Parameter reactive from controls module

**Outputs**:
- Main plot output
- PNG download handler
- SVG download handler
- Computation statistics reactive

```r
zen_plot_server(id, params) → reactive(
  computation_time,
  point_count,
  cell_count
)
```

## Performance Optimizations

### 1. Memoization Cache
- **Package**: `memoise` with `cachem` backend
- **Size limit**: 100MB
- **TTL**: 1 hour
- **Cache warming**: Pre-computes 6 common patterns on startup

### 2. Vectorization
- Spiral generation uses vectorized R operations
- No loops in mathematical computations
- Achieves ~0.1ms per 100 points

### 3. Input Debouncing
- 300ms debounce on parameter changes
- Prevents computation spam during slider drag
- Uses Shiny's native `debounce()` function

### 4. Adaptive Performance
- System detection for RAM and CPU cores
- Three modes: High (5000 pts), Medium (2000 pts), Low (1000 pts)
- Auto-adjusts based on available resources

## File Dependencies

```
app_zen.R
├── sources: R/theme.R
├── sources: R/utils/spiral_math.R
├── sources: R/utils/performance.R
├── sources: R/utils/cache_manager.R
├── sources: R/modules/ui_controls.R
└── sources: R/modules/ui_plot.R
    ├── uses: spiral_math.R functions
    ├── uses: cache_manager.R functions
    └── uses: performance.R functions
```

## Key Design Decisions

### 1. Modular Architecture
Shiny modules provide encapsulation and reusability. Each module has its own namespace, preventing ID collisions and enabling independent testing.

### 2. bslib for UI Framework
Bootstrap 5 via bslib provides:
- Native dark mode support
- Collapsible sidebar component
- Responsive grid system
- CSS variable theming

### 3. Utility Separation
Mathematical and caching logic separated from UI:
- Enables unit testing without Shiny
- Reusable across different UI implementations
- Clear responsibility boundaries

### 4. Minimal Custom CSS
Leverage Bootstrap utilities where possible:
- Custom CSS only for zen-specific effects
- Animations and glass-morphism in overlay file
- Reduces maintenance burden

## Security Considerations

- No user authentication (public visualization tool)
- Input validation prevents extreme parameter values
- No external API calls
- Cache limited to prevent memory exhaustion

## Deployment Architecture

```
Local Development          Production (shinyapps.io)
┌───────────────┐         ┌───────────────────────┐
│   RStudio     │         │    shinyapps.io       │
│   R Session   │ ──────▶ │    Container          │
│   renv        │ deploy  │    R + Dependencies   │
└───────────────┘         └───────────────────────┘
```

## Future Considerations

- WebSocket for real-time collaborative patterns
- WebGL renderer for massive point clouds
- Database for saving/loading patterns
- User authentication for personal galleries
