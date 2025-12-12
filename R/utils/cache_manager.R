# cache_manager.R - Intelligent caching system for Voronoi computations

library(memoise)
library(cachem)

# Create cache with size limit (100MB) and time-based expiration
spiral_cache <- cachem::cache_mem(
  max_size = 100 * 1024^2,  # 100MB
  max_age = 3600  # 1 hour TTL
)

#' Memoized Voronoi Computation
#' 
#' Cached version of expensive Voronoi calculations
#' @export
compute_voronoi_cached <- memoise::memoise(
  function(spiral_points) {
    delaunay_triangulation <- tessellation::delaunay(spiral_points)
    voronoi_diagram <- tessellation::voronoi(delaunay_triangulation)
    
    # Pre-compute bounded cells for performance
    bounded_cells <- Filter(tessellation::isBoundedCell, voronoi_diagram)
    
    list(
      voronoi = voronoi_diagram,
      bounded_count = length(bounded_cells),
      triangulation = delaunay_triangulation
    )
  },
  cache = spiral_cache
)

#' Clear Computation Cache
#' @export
clear_spiral_cache <- function() {
  spiral_cache$reset()
  message("Spiral cache cleared")
}

#' Get Cache Statistics
#' @export
get_cache_stats <- function() {
  list(
    size = spiral_cache$size(),
    max_size = 100 * 1024^2,
    usage_percent = round((spiral_cache$size() / (100 * 1024^2)) * 100, 2)
  )
}

#' Intelligent Cache Warming
#' 
#' Pre-compute common patterns for instant loading
#' @export
warm_cache <- function() {
  # Check if functions are available before warming
  if (!exists("generate_fermat_spiral", mode = "function")) {
    message("Skipping cache warming - functions not loaded yet")
    return(invisible(NULL))
  }
  
  common_patterns <- list(
    list(from = 0, to = 100, length = 300),    # Default
    list(from = 0, to = 50, length = 200),     # Simple
    list(from = 0, to = 200, length = 400),    # Medium
    list(from = 0, to = 500, length = 500),    # Complex
    list(from = 111, to = 222, length = 333),  # Example 1
    list(from = 0, to = 666, length = 999)     # Example 2
  )
  
  message("Warming cache with common patterns...")
  
  for (pattern in common_patterns) {
    tryCatch({
      points <- generate_fermat_spiral(
        pattern$from, 
        pattern$to, 
        pattern$length
      )
      compute_voronoi_cached(points)
    }, error = function(e) {
      warning(paste("Failed to warm cache for pattern:", e$message))
    })
  }
  
  message("Cache warming complete!")
}