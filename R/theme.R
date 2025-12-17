# theme.R - Centralized bslib theme configuration for Spiralizer
#
# This file defines the visual theme using bslib with Bootstrap 5
# and the Bootswatch "darkly" preset as foundation.
#
#' @import bslib

#' Spiralizer Theme
#'
#' Creates the main application theme using bslib.
#' Based on Bootstrap 5 with darkly preset and zen customizations.
#'
#' @return A bslib theme object
#' @export
spiralizer_theme <- bs_theme(
  version = 5,

preset = "darkly",

  # ═══════════════════════════════════════════════════════════════════
# THEME COLOR PALETTE
  # ═══════════════════════════════════════════════════════════════════

  # Backgrounds
  bg = "#0a0a0a",             # Deep space black - main background
  "body-bg" = "#0a0a0a",      # Ensure body matches

  # Text
  fg = "#e0e0e0",             # Soft white - primary text
  "body-color" = "#e0e0e0",   # Ensure body text matches

  # Accent colors
  primary = "#00ff88",        # Ethereal green - main accent
  secondary = "#2a2a2a",      # Mid gray - subtle elements
  success = "#00ff88",        # Use primary for success states
  info = "#17a2b8",           # Keep Bootstrap default
  warning = "#ffc107",        # Keep Bootstrap default
  danger = "#ff0044",         # Zen error red

  # ═══════════════════════════════════════════════════════════════════
  # TYPOGRAPHY
  # ═══════════════════════════════════════════════════════════════════

  # Font families
  base_font = font_google("Inter", wght = "300..600"),
  heading_font = font_google("Inter"),
  code_font = font_google("JetBrains Mono"),

  # Font sizing
  "font-size-base" = "0.9375rem",     # 15px base
  "font-weight-base" = "300",         # Light weight for zen feel
  "line-height-base" = "1.6",         # Comfortable reading

  # ═══════════════════════════════════════════════════════════════════
  # COMPONENT STYLING
  # ═══════════════════════════════════════════════════════════════════

  # Border radius - subtle rounding
  "border-radius" = "8px",
  "border-radius-sm" = "6px",
  "border-radius-lg" = "10px",

  # Cards
  "card-bg" = "#1a1a1a",              # Slightly lighter than body
  "card-border-width" = "1px",
  "card-border-color" = "#2a2a2a",
  "card-cap-bg" = "transparent",      # No header background

  # Sidebar
  "sidebar-bg" = "#1a1a1a",

  # Inputs
  "input-bg" = "#1a1a1a",
  "input-border-color" = "#2a2a2a",
  "input-focus-border-color" = "#00ff88",

  # Buttons
  "btn-border-radius" = "6px",

  # Links
  "link-color" = "#00ff88",
  "link-hover-color" = "#33ff99"
)

#' Get the Spiralizer theme
#'
#' Returns the theme object. Use this function if you need
#' to modify or extend the theme.
#'
#' @return bslib theme object
#' @export
get_spiralizer_theme <- function() {
  spiralizer_theme
}

#' Preview the theme in an interactive viewer
#'
#' Opens an interactive bslib theme preview for development.
#' Allows real-time color adjustments.
#'
#' @export
preview_theme <- function() {
  bs_theme_preview(spiralizer_theme)
}

# ═══════════════════════════════════════════════════════════════════════
# COLOR CONSTANTS (for use in R code)
# ═══════════════════════════════════════════════════════════════════════

#' Theme color palette
#'
#' Named list of theme colors for use in R plotting code.
#' @export
theme_colors <- list(
  black = "#0a0a0a",
  gray_dark = "#1a1a1a",
  gray_mid = "#2a2a2a",
  gray_light = "#888888",
  white = "#e0e0e0",
  accent = "#00ff88",
  accent_dim = "#00ff8833",
  error = "#ff0044"
)

#' Available color palettes for spirals
#'
#' Named list for use in selectInput choices.
#' @export
palette_choices <- list(
  "Turbo" = "turbo",
  "Viridis" = "viridis",
  "Plasma" = "plasma",
  "Inferno" = "inferno",
  "Magma" = "magma",
  "Cividis" = "cividis",
  "Zen Mono" = "zen_mono",
  "Custom" = "custom"
)
