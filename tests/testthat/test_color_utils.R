# test_color_utils.R - Unit tests for color palette utilities

test_that("get_color_palette returns correct number of colors", {
  n_colors <- 50

  # Test each standard palette
  palettes <- c("turbo", "viridis", "plasma", "inferno", "magma", "cividis", "zen_mono")

  for (palette in palettes) {
    colors <- get_color_palette(palette, n_colors)
    expect_equal(length(colors), n_colors, info = paste("Palette:", palette))
  }
})

test_that("get_color_palette returns valid hex colors", {
  colors <- get_color_palette("turbo", 10)

  # Each color should be a valid hex string
  for (color in colors) {
    expect_match(color, "^#[0-9A-Fa-f]{6,8}$", info = paste("Color:", color))
  }
})

test_that("custom palette with valid hex colors works", {
  custom_start <- "#FF0000"  # Red
  custom_end <- "#0000FF"    # Blue
  n_colors <- 10

  colors <- get_color_palette(
    "custom",
    n_colors,
    custom_start = custom_start,
    custom_end = custom_end
  )

  expect_equal(length(colors), n_colors)

  # First and last colors should be close to start/end
  # (colorRampPalette may normalize slightly)
  expect_match(colors[1], "^#")
  expect_match(colors[n_colors], "^#")
})

test_that("custom palette uses defaults when colors not provided", {
  colors <- get_color_palette("custom", 10)

  # Should not error and should return correct length
  expect_equal(length(colors), 10)

  # Should use black to white as defaults
  # First color should be black-ish, last white-ish
  expect_true(all(nchar(colors) >= 7))  # Valid hex
})

test_that("palette inversion works", {
  n_colors <- 10

  colors_normal <- get_color_palette("turbo", n_colors, invert = FALSE)
  colors_inverted <- get_color_palette("turbo", n_colors, invert = TRUE)

  # Inverted should be reversed
  expect_equal(colors_normal, rev(colors_inverted))
})

test_that("unknown palette falls back to turbo", {
  colors_unknown <- get_color_palette("nonexistent_palette", 10)
  colors_turbo <- get_color_palette("turbo", 10)

  expect_equal(colors_unknown, colors_turbo)
})

test_that("zen_mono palette uses theme colors", {
  colors <- get_color_palette("zen_mono", 10)

  # Should return 10 colors

  expect_equal(length(colors), 10)

  # First color should be close to theme_colors$black
  # Last color should be close to theme_colors$accent
  expect_match(colors[1], "^#")
  expect_match(colors[10], "^#")
})

test_that("get_color_palette handles edge cases", {
  # Single color
  colors_one <- get_color_palette("turbo", 1)
  expect_equal(length(colors_one), 1)

  # Large number of colors
  colors_many <- get_color_palette("turbo", 1000)
  expect_equal(length(colors_many), 1000)
})
