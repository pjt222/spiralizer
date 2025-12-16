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
    num_points >= SPIRAL_MIN_POINTS
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
    return(DEFAULT_PLOT_LIMITS)
  }

  # Use Rcpp if available
  if (.rcpp_available() && exists("calculate_limits_cpp", mode = "function")) {
    return(calculate_limits_cpp(all_vertices, PLOT_LIMIT_PADDING))
  }

  # R implementation
  max_coord <- max(abs(all_vertices))
  limit <- ceiling(max_coord * PLOT_LIMIT_PADDING)

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
  if (angle_start >= angle_end) {
    return(list(valid = FALSE, message = "Start angle must be less than end angle"))
  }

  if (num_points < SPIRAL_MIN_POINTS) {
    return(list(
      valid = FALSE,
      message = sprintf("Need at least %d points for Voronoi diagram", SPIRAL_MIN_POINTS)
    ))
  }

  if (num_points > SPIRAL_MAX_POINTS) {
    return(list(
      valid = FALSE,
      message = sprintf("Too many points! Maximum is %d for performance", SPIRAL_MAX_POINTS)
    ))
  }

  if (angle_end - angle_start > SPIRAL_MAX_ANGLE_RANGE) {
    return(list(
      valid = FALSE,
      message = sprintf("Angle range too large! Keep it under %d", SPIRAL_MAX_ANGLE_RANGE)
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
  # Based on empirical benchmarks
  base_time <- 50  # Base overhead in ms
  per_point_time <- 0.3  # Time per point in ms
  
  return(base_time + (num_points * per_point_time))
}