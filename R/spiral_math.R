# spiral_math.R - Optimized mathematical functions for spiral generation
# Performance-optimized Fermat spiral computations
#
# Provides both R and Rcpp implementations. Use generate_fermat_spiral()
# which automatically selects the fastest available implementation.

# Check if Rcpp functions are available
.rcpp_available <- function() {

  exists("generate_spiral_cpp", mode = "function")
}

#' Generate Fermat Spiral Points
#'
#' Generates points along a Fermat spiral. Automatically uses C++
#' implementation if available for ~10x speedup.
#'
#' @param angle_start Starting angle in radians
#' @param angle_end Ending angle in radians
#' @param num_points Number of points to generate
#' @return Matrix with x,y coordinates
#' @export
generate_fermat_spiral <- function(angle_start = 0, angle_end = 100, num_points = 300) {
  # Input validation
 stopifnot(
    is.numeric(angle_start),
    is.numeric(angle_end),
    is.numeric(num_points),
    angle_end > angle_start,
    num_points >= get_setting("spiral", "min_points")
  )

  # Use Rcpp if available, otherwise fall back to R
  if (.rcpp_available()) {
    return(generate_spiral_cpp(angle_start, angle_end, as.integer(num_points)))
  }

  # R implementation (fallback)
  generate_fermat_spiral_r(angle_start, angle_end, num_points)
}

#' Generate Fermat Spiral Points (Pure R)
#'
#' Pure R implementation using vectorized operations.
#'
#' @param angle_start Starting angle in radians
#' @param angle_end Ending angle in radians
#' @param num_points Number of points to generate
#' @return Matrix with x,y coordinates
#' @keywords internal
generate_fermat_spiral_r <- function(angle_start, angle_end, num_points) {
  # Pre-allocate for performance
  theta_values <- seq(angle_start, angle_end, length.out = num_points)
  sqrt_theta <- sqrt(theta_values)

  # Vectorized computation
  cbind(
    x = sqrt_theta * cos(theta_values),
    y = sqrt_theta * sin(theta_values)
  )
}

#' Calculate Optimized Plot Limits
#'
#' Extracts vertices from Voronoi cells and calculates symmetric plot limits.
#' Uses data.table for efficient vertex extraction when available.
#'
#' @param voronoi_object Voronoi tessellation object
#' @return Numeric vector with min and max limits
#' @export
calculate_plot_limits <- function(voronoi_object) {
  # Extract all cell vertices
  all_vertices <- extract_voronoi_vertices(voronoi_object)

  if (is.null(all_vertices) || nrow(all_vertices) == 0) {
    return(get_setting("plot", "default_limits"))
  }

  # Use Rcpp if available
  if (.rcpp_available() && exists("calculate_limits_cpp", mode = "function")) {
    return(calculate_limits_cpp(all_vertices, get_setting("plot", "limit_padding")))
  }

  # R implementation
  max_coord <- max(abs(all_vertices))
  limit <- ceiling(max_coord * get_setting("plot", "limit_padding"))

  c(-limit, limit)
}

#' Extract Vertices from Voronoi Object
#'
#' Efficiently extracts all vertex coordinates from a Voronoi tessellation.
#'
#' @param voronoi_object Voronoi tessellation object
#' @return Matrix with x,y coordinates or NULL
#' @keywords internal
extract_voronoi_vertices <- function(voronoi_object) {
  # Pre-allocate list for vertices
  vertex_list <- vector("list", length(voronoi_object))

  for (i in seq_along(voronoi_object)) {
    cell <- voronoi_object[[i]]
    if (!is.null(cell[["cell"]])) {
      edges <- cell[["cell"]]
      n_edges <- length(edges)
      if (n_edges > 0) {
        # Collect vertices safely
        vertices <- list()
        for (j in seq_len(n_edges)) {
          edge <- edges[[j]]
          pt_a <- edge[["A"]]
          pt_b <- edge[["B"]]
          # Only use 2D coordinates (first 2 elements)
          if (!is.null(pt_a) && length(pt_a) >= 2) {
            vertices[[length(vertices) + 1]] <- pt_a[1:2]
          }
          if (!is.null(pt_b) && length(pt_b) >= 2) {
            vertices[[length(vertices) + 1]] <- pt_b[1:2]
          }
        }
        if (length(vertices) > 0) {
          vertex_list[[i]] <- do.call(rbind, vertices)
        }
      }
    }
  }

  # Combine all vertices
  do.call(rbind, vertex_list)
}

#' Truncate Spiral Points by Radius
#'
#' Removes outlier points that exceed a threshold based on median radius.
#' Useful for cleaning up spirals where some points extend far from center.
#'
#' @param spiral_points Matrix with x,y coordinates
#' @param factor Truncation factor: points with radius > factor * median_radius are removed
#' @return Matrix with truncated x,y coordinates
#' @export
truncate_spiral_points <- function(spiral_points, factor = 2.0) {

  if (factor <= 0) {
    stop("Truncation factor must be positive")
  }

  # Calculate radius for each point
  radii <- sqrt(spiral_points[, "x"]^2 + spiral_points[, "y"]^2)

  # Calculate threshold based on median radius
  median_radius <- median(radii)
  max_radius <- factor * median_radius

  # Filter points within threshold
  keep_mask <- radii <= max_radius
  truncated <- spiral_points[keep_mask, , drop = FALSE]

  # Ensure we keep at least min_points
  min_points <- get_setting("spiral", "min_points")
  if (nrow(truncated) < min_points) {
    # Keep the closest min_points if too many were removed
    order_by_radius <- order(radii)
    truncated <- spiral_points[order_by_radius[1:min_points], , drop = FALSE]
  }

  truncated
}

#' Compute Voronoi Diagram
#'
#' @param spiral_points Matrix with x,y coordinates
#' @return List with voronoi diagram and bounded count
#' @export
compute_voronoi <- function(spiral_points) {
  delaunay_triangulation <- tessellation::delaunay(spiral_points)
  voronoi_diagram <- tessellation::voronoi(delaunay_triangulation)

  # Count bounded cells
  bounded_cells <- Filter(tessellation::isBoundedCell, voronoi_diagram)

  list(
    voronoi = voronoi_diagram,
    bounded_count = length(bounded_cells)
  )
}

#' Validate Spiral Parameters
#'
#' @param angle_start Starting angle
#' @param angle_end Ending angle
#' @param num_points Number of points
#' @return List with valid flag and message
#' @export
validate_spiral_params <- function(angle_start, angle_end, num_points) {
  min_points <- get_setting("spiral", "min_points")
  max_points <- get_setting("spiral", "max_points")
  max_angle_range <- get_setting("spiral", "max_angle_range")

  if (angle_start >= angle_end) {
    return(list(valid = FALSE, message = "Start angle must be less than end angle"))
  }

  if (num_points < min_points) {
    return(list(
      valid = FALSE,
      message = sprintf("Need at least %d points for Voronoi diagram", min_points)
    ))
  }

  if (num_points > max_points) {
    return(list(
      valid = FALSE,
      message = sprintf("Too many points! Maximum is %d for performance", max_points)
    ))
  }

  if (angle_end - angle_start > max_angle_range) {
    return(list(
      valid = FALSE,
      message = sprintf("Angle range too large! Keep it under %d", max_angle_range)
    ))
  }

  list(valid = TRUE, message = "")
}

#' Estimate Computation Time
#'
#' @param num_points Number of points
#' @return Estimated time in milliseconds
#' @export
estimate_computation_time <- function(num_points) {
  # Based on empirical benchmarks, values from config
  base_time <- get_setting("estimation", "base_time_ms")
  per_point <- get_setting("estimation", "per_point_time_ms")
  return(base_time + (num_points * per_point))
}
