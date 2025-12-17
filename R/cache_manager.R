# cache_manager.R - Intelligent caching system for Voronoi computations
#
#' @import memoise
#' @import cachem

# Internal environment for lazy-initialized cache objects
.cache_env <- new.env(parent = emptyenv())

#' Get or create the spiral cache
#' @keywords internal
.get_spiral_cache <- function() {
  if (is.null(.cache_env$spiral_cache)) {
    .cache_env$spiral_cache <- cachem::cache_mem(
      max_size = get_setting("cache", "max_size_mb") * 1024^2,
      max_age = get_setting("cache", "max_age_seconds")
    )
  }
  .cache_env$spiral_cache
}

#' Get or create the memoized compute function
#' @keywords internal
.get_compute_fn <- function() {
  if (is.null(.cache_env$compute_fn)) {
    .cache_env$compute_fn <- memoise::memoise(
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
      cache = .get_spiral_cache()
    )
  }
  .cache_env$compute_fn
}

#' Memoized Voronoi Computation
#'
#' Cached version of expensive Voronoi calculations.
#' Uses lazy initialization for the cache.
#'
#' @param spiral_points Matrix of spiral point coordinates
#' @return List with voronoi diagram, bounded cell count, and triangulation
#' @export
compute_voronoi_cached <- function(spiral_points) {
  .get_compute_fn()(spiral_points)
}

#' Clear Computation Cache
#' @export
clear_spiral_cache <- function() {
  .get_spiral_cache()$reset()
  message("Spiral cache cleared")
}

#' Get Cache Statistics
#' @export
get_cache_stats <- function() {
  cache <- .get_spiral_cache()
  max_bytes <- get_setting("cache", "max_size_mb") * 1024^2
  list(
    size = cache$size(),
    max_size = max_bytes,
    usage_percent = round((cache$size() / max_bytes) * 100, 2)
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