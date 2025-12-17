# color_utils.R - Color palette utilities
#
# Centralized color palette generation to avoid code duplication.

#' Get Color Palette
#'
#' Returns a color vector for the specified palette.
#' Centralizes palette logic to avoid duplication in plot rendering.
#'
#' @param palette_name Character name of the palette
#' @param n_colors Number of colors to generate
#' @param invert Logical, whether to reverse the palette
#' @param custom_start Start color for custom palette (hex string)
#' @param custom_end End color for custom palette (hex string)
#' @return Character vector of hex colors
#' @export
get_color_palette <- function(palette_name, n_colors, invert = FALSE,
                              custom_start = NULL, custom_end = NULL) {
  colors <- switch(palette_name,
    "turbo"    = viridisLite::turbo(n_colors),
    "viridis"  = viridisLite::viridis(n_colors),
    "plasma"   = viridisLite::plasma(n_colors),
    "inferno"  = viridisLite::inferno(n_colors),
    "magma"    = viridisLite::magma(n_colors),
    "cividis"  = viridisLite::cividis(n_colors),
    "zen_mono" = colorRampPalette(c(theme_colors$black, theme_colors$accent))(n_colors),
    "custom"   = colorRampPalette(c(
      custom_start %||% "#000000",
      custom_end %||% "#ffffff"
    ))(n_colors),
    viridisLite::turbo(n_colors)  # default fallback
  )

  if (isTRUE(invert)) {
    colors <- rev(colors)
  }

  colors
}
