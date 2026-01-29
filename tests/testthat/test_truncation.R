# test_truncation.R - Unit tests for spiral truncation feature

test_that("truncate_spiral_points works with default factor", {
  # Generate a spiral with known points
  spiral <- generate_fermat_spiral(0, 100, 100)

  # Truncate with default factor (2.0)
  truncated <- truncate_spiral_points(spiral)

  # Should have fewer or equal points

  expect_lte(nrow(truncated), nrow(spiral))

  # Should still have valid structure
  expect_equal(ncol(truncated), 2)
  expect_true(all(colnames(truncated) == c("x", "y")))

  # All remaining points should be within threshold
  radii <- sqrt(truncated[, "x"]^2 + truncated[, "y"]^2)
  original_radii <- sqrt(spiral[, "x"]^2 + spiral[, "y"]^2)
  median_radius <- median(original_radii)
  expect_true(all(radii <= 2.0 * median_radius))
})

test_that("truncate_spiral_points works with aggressive factor (0.1)", {
  spiral <- generate_fermat_spiral(0, 100, 100)

  # Truncate with very aggressive factor
  truncated <- truncate_spiral_points(spiral, factor = 0.1)

  # Should have significantly fewer points
  expect_lt(nrow(truncated), nrow(spiral))

  # Should maintain at least min_points
  min_points <- get_setting("spiral", "min_points")
  expect_gte(nrow(truncated), min_points)
})

test_that("truncate_spiral_points errors on invalid factor", {
  spiral <- generate_fermat_spiral(0, 100, 100)

  # Factor = 0 should error
  expect_error(
    truncate_spiral_points(spiral, factor = 0),
    "Truncation factor must be positive"
  )

  # Negative factor should error
  expect_error(
    truncate_spiral_points(spiral, factor = -1),
    "Truncation factor must be positive"
  )
})

test_that("truncate_spiral_points preserves min_points when aggressive", {
  spiral <- generate_fermat_spiral(0, 100, 100)
  min_points <- get_setting("spiral", "min_points")

  # Very aggressive truncation that would remove most points
  truncated <- truncate_spiral_points(spiral, factor = 0.01)

  # Should never go below min_points
  expect_gte(nrow(truncated), min_points)
})

test_that("truncation integrates with Voronoi computation", {
  # Generate spiral
  spiral <- generate_fermat_spiral(0, 100, 200)

  # Truncate
  truncated <- truncate_spiral_points(spiral, factor = 1.5)

  # Should be able to compute Voronoi on truncated points
  result <- compute_voronoi(truncated)

  expect_true(is.list(result))
  expect_true("voronoi" %in% names(result))
  expect_true("bounded_count" %in% names(result))
  expect_gte(result$bounded_count, 0)
})
