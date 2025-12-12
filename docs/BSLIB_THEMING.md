# Spiralizer Theme Guide

## Overview

Spiralizer uses [bslib](https://rstudio.github.io/bslib/) for theming, built on Bootstrap 5 with the Bootswatch "darkly" preset as a foundation. Custom zen aesthetics are layered on top.

## Theme Architecture

```
┌─────────────────────────────────────────┐
│         www/css/zen-overlay.css         │  ← Custom zen effects
├─────────────────────────────────────────┤
│            R/theme.R                    │  ← bslib customizations
├─────────────────────────────────────────┤
│       Bootswatch "darkly" preset        │  ← Dark theme foundation
├─────────────────────────────────────────┤
│           Bootstrap 5                   │  ← Core framework
└─────────────────────────────────────────┘
```

## Core Theme Definition

Located in `R/theme.R`:

```r
library(bslib)

spiralizer_theme <- bs_theme(
  version = 5,
  preset = "darkly",

  # Zen color palette
  bg = "#0a0a0a",         # Deep space black
  fg = "#e0e0e0",         # Soft white
  primary = "#00ff88",    # Ethereal green accent
  secondary = "#2a2a2a",  # Mid gray

  # Typography
  base_font = font_google("Inter", wght = "300..600"),
  heading_font = font_google("Inter"),

  # Component customization
  "border-radius" = "8px",
  "card-border-width" = "1px",
  "card-bg" = "#1a1a1a"
)
```

## Color Palette

### Primary Colors

| Variable | Hex | Usage |
|----------|-----|-------|
| `bg` | `#0a0a0a` | Page background, plot background |
| `fg` | `#e0e0e0` | Primary text |
| `primary` | `#00ff88` | Accent, buttons, links, highlights |
| `secondary` | `#2a2a2a` | Borders, dividers, subtle backgrounds |

### Extended Palette (CSS Variables)

These are available via Bootstrap's CSS variables:

```css
/* Access in CSS as: */
var(--bs-body-bg)      /* #0a0a0a */
var(--bs-body-color)   /* #e0e0e0 */
var(--bs-primary)      /* #00ff88 */
var(--bs-secondary)    /* #2a2a2a */
var(--bs-border-color) /* derived from secondary */
```

## Customizing the Theme

### Changing the Accent Color

In `R/theme.R`:

```r
spiralizer_theme <- bs_theme(
  ...
  primary = "#ff6b6b",  # Change to coral red
  ...
)
```

### Changing Typography

```r
spiralizer_theme <- bs_theme(
  ...
  base_font = font_google("Fira Code"),  # Monospace aesthetic
  "font-size-base" = "0.9rem",           # Smaller text
  ...
)
```

### Adding Custom Sass Variables

```r
spiralizer_theme <- bs_theme(
  ...
) |>
  bs_add_variables(
    "zen-glow" = "0 0 20px rgba(0, 255, 136, 0.3)",
    "zen-transition" = "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
  )
```

## Component Styling

### Cards

Cards use these Bootstrap variables:

```r
bs_theme(
  "card-bg" = "#1a1a1a",           # Card background
  "card-border-width" = "1px",     # Border thickness
  "card-border-color" = "#2a2a2a", # Border color
  "card-border-radius" = "8px",    # Corner radius
  "card-cap-bg" = "#151515"        # Header background
)
```

### Buttons

Primary outline buttons (used for presets):

```r
bs_theme(
  "btn-border-radius" = "6px",
  "btn-padding-x" = "1rem",
  "btn-padding-y" = "0.5rem"
)
```

### Sidebar

The collapsible sidebar uses:

```r
bs_theme(
  "sidebar-bg" = "#1a1a1a",
  "sidebar-width" = "320px"
)
```

## Zen Overlay CSS

Custom effects not achievable through bslib are in `www/css/zen-overlay.css`:

### Glass-morphism Effect

```css
.bslib-sidebar-layout > .sidebar {
  backdrop-filter: blur(10px);
  background: rgba(26, 26, 26, 0.9) !important;
}
```

### Accent Glow on Hover

```css
.btn-outline-primary:hover {
  box-shadow: 0 0 20px rgba(0, 255, 136, 0.3);
}

input[type="range"]::-webkit-slider-thumb:hover {
  box-shadow: 0 0 15px var(--bs-primary);
}
```

### Breathing Animation

```css
.zen-breathing {
  animation: zen-breathe 4s ease-in-out infinite;
}

@keyframes zen-breathe {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.95; transform: scale(1.002); }
}
```

### Performance Indicator Pulse

```css
.performance-indicator .indicator-dot {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

## Live Theme Preview

During development, preview theme changes instantly:

```r
library(bslib)
source("R/theme.R")

# Opens interactive preview
bs_theme_preview(spiralizer_theme)
```

## Best Practices

### 1. Use Bootstrap Variables First

Prefer Bootstrap CSS variables over hardcoded values:

```css
/* Good */
background: var(--bs-body-bg);
color: var(--bs-primary);

/* Avoid */
background: #0a0a0a;
color: #00ff88;
```

### 2. Leverage Utility Classes

Bootstrap 5 provides utility classes for common patterns:

```r
# Spacing
div(class = "p-3 mt-2 mb-4")  # padding-3, margin-top-2, margin-bottom-4

# Text
span(class = "text-uppercase small")

# Flexbox
div(class = "d-flex justify-content-between align-items-center")
```

### 3. Keep Custom CSS Minimal

Only add custom CSS for:
- Animations (breathing, pulse)
- Special effects (glass-morphism, glow)
- Specific component overrides

### 4. Test Dark Mode Contrast

Ensure sufficient contrast ratios:
- Text on background: 7:1 minimum (WCAG AAA)
- Interactive elements: 4.5:1 minimum

## Troubleshooting

### Theme Not Applying

```r
# Verify theme is passed to UI
page_navbar(
  theme = spiralizer_theme,  # Must be included
  ...
)
```

### CSS Variables Not Working

```r
# Check Bootstrap version
bslib::bs_version()  # Should return "5"
```

### Google Fonts Not Loading

```r
# Fonts require internet connection on first load
# For offline use, include fonts locally in www/fonts/
```

## Reference Links

- [bslib documentation](https://rstudio.github.io/bslib/)
- [Bootstrap 5 CSS Variables](https://getbootstrap.com/docs/5.3/customize/css-variables/)
- [Bootswatch Darkly](https://bootswatch.com/darkly/)
- [Google Fonts](https://fonts.google.com/)
