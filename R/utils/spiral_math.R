# spiral_math.R - Optimized mathematical functions for spiral generation
# Performance-optimized Fermat spiral computations

#' Generate Fermat Spiral Points
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
    num_points >= 3
  )
  
  # Pre-allocate for performance
  theta_values <- seq(angle_start, angle_end, length.out = num_points)
  sqrt_theta <- sqrt(theta_values)
  
  # Vectorized computation - much faster than loops
  spiral_points <- cbind(
    x = sqrt_theta * cos(theta_values),
    y = sqrt_theta * sin(theta_values)
  )
  
  return(spiral_points)
}

#' Calculate Optimized Plot Limits
#' 
#' @param voronoi_object Voronoi tessellation object
#' @return Numeric vector with min and max limits
#' @export
calculate_plot_limits <- function(voronoi_object) {
  # Extract all cell vertices efficiently
  all_vertices <- do.call(rbind, lapply(voronoi_object, function(cell) {
    if (!is.null(cell[["cell"]])) {
      do.call(rbind, lapply(cell[["cell"]], function(edge) {
        rbind(edge[["A"]], edge[["B"]])
      }))
    }
  }))
  
  if (is.null(all_vertices) || nrow(all_vertices) == 0) {
    return(c(-10, 10))  # Default fallback
  }
  
  # Calculate limits with padding
  max_coord <- max(abs(all_vertices))
  limit <- ceiling(max_coord * 1.1)  # 10% padding
  
  return(c(-limit, limit))
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
  
  if (num_points < 3) {
    return(list(valid = FALSE, message = "Need at least 3 points for Voronoi diagram"))
  }
  
  if (num_points > 5000) {
    return(list(valid = FALSE, message = "Too many points! Maximum is 5000 for performance"))
  }
  
  if (angle_end - angle_start > 1000) {
    return(list(valid = FALSE, message = "Angle range too large! Keep it under 1000"))
  }
  
  return(list(valid = TRUE, message = ""))
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