# test_spiral_math.R - Unit tests for spiral mathematics

library(testthat)

# Source constants first (required by spiral_math.R)
source(here::here("R/utils/constants.R"))

# Source the functions
source(here::here("R/utils/spiral_math.R"))

test_that("generate_fermat_spiral creates correct number of points", {
  points <- generate_fermat_spiral(0, 100, 50)
  expect_equal(nrow(points), 50)
  expect_equal(ncol(points), 2)
  expect_true(all(colnames(points) == c("x", "y")))
})

test_that("generate_fermat_spiral handles edge cases", {
  # Minimum points
  points_min <- generate_fermat_spiral(0, 1, SPIRAL_MIN_POINTS)
  expect_equal(nrow(points_min), SPIRAL_MIN_POINTS)

  # Zero start angle
  points_zero <- generate_fermat_spiral(0, 10, 10)
  expect_equal(points_zero[1, "x"], 0)
  expect_equal(points_zero[1, "y"], 0)
})

test_that("generate_fermat_spiral produces mathematically correct values", {
  # Test specific known values
  theta <- pi/4  # 45 degrees
  expected_x <- sqrt(theta) * cos(theta)
  expected_y <- sqrt(theta) * sin(theta)
  
  points <- generate_fermat_spiral(theta, theta + 0.0001, 2)
  
  expect_equal(points[1, "x"], expected_x, tolerance = 0.001)
  expect_equal(points[1, "y"], expected_y, tolerance = 0.001)
})

test_that("validate_spiral_params catches invalid inputs", {
  # Start >= End
  result1 <- validate_spiral_params(100, 50, 100)
  expect_false(result1$valid)
  expect_match(result1$message, "Start angle must be less than")

  # Too few points
  result2 <- validate_spiral_params(0, 100, SPIRAL_MIN_POINTS - 1)
  expect_false(result2$valid)
  expect_match(result2$message, sprintf("at least %d points", SPIRAL_MIN_POINTS))

  # Too many points
  result3 <- validate_spiral_params(0, 100, SPIRAL_MAX_POINTS + 1)
  expect_false(result3$valid)
  expect_match(result3$message, "Too many points")

  # Valid params
  result4 <- validate_spiral_params(0, 100, SPIRAL_DEFAULT_POINTS)
  expect_true(result4$valid)
  expect_equal(result4$message, "")
})

test_that("calculate_plot_limits handles empty voronoi", {
  # Mock empty voronoi object
  empty_voronoi <- list()
  limits <- calculate_plot_limits(empty_voronoi)

  expect_equal(limits, DEFAULT_PLOT_LIMITS)
})

test_that("estimate_computation_time provides reasonable estimates", {
  time_10 <- estimate_computation_time(10)
  time_100 <- estimate_computation_time(100)
  time_1000 <- estimate_computation_time(1000)
  
  expect_true(time_10 < time_100)
  expect_true(time_100 < time_1000)
  expect_true(time_10 > 0)
})