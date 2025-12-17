# performance.R - Performance monitoring and optimization utilities

#' Performance Timer
#' 
#' Simple timing wrapper for performance monitoring
#' @export
time_it <- function(expr, label = "Operation") {
  start_time <- Sys.time()
  result <- force(expr)
  end_time <- Sys.time()
  
  elapsed <- as.numeric(end_time - start_time, units = "secs") * 1000  # Convert to ms
  
  if (getOption("spiralizer.debug", FALSE)) {
    message(sprintf("%s took %.2f ms", label, elapsed))
  }
  
  attr(result, "elapsed_ms") <- elapsed
  return(result)
}

#' Create Performance Report
#' @export
create_performance_report <- function(timings) {
  report <- list(
    total_ms = sum(timings),
    breakdown = list(
      spiral_generation = timings[1],
      voronoi_computation = timings[2],
      plot_rendering = timings[3]
    ),
    timestamp = Sys.time()
  )
  
  class(report) <- "performance_report"
  return(report)
}

#' Check System Performance Capability
#' @export
check_performance_mode <- function() {
  # Simple heuristic based on available memory and cores
  cores <- parallel::detectCores()
  
  # Windows-compatible memory detection
  mem_gb <- tryCatch({
    if (.Platform$OS.type == "windows") {
      # Windows fallback - assume reasonable memory
      8
    } else {
      # Unix/Linux systems
      as.numeric(system("free -g | awk '/^Mem:/{print $2}'", intern = TRUE))
    }
  }, error = function(e) {
    # Fallback for any system
    8  # Assume 8GB
  })
  
  if (is.na(mem_gb) || mem_gb <= 0) {
    mem_gb <- 8  # Safe fallback
  }
  
  if (mem_gb >= 16 && cores >= 8) {
    return("high")
  } else if (mem_gb >= 8 && cores >= 4) {
    return("medium")
  } else {
    return("low")
  }
}

#' Get Recommended Settings Based on Performance Mode
#' @export
get_performance_recommendations <- function(mode = NULL) {
  if (is.null(mode)) {
    mode <- check_performance_mode()
  }

  # Get base recommendations from config
  mode_config <- get_setting("performance_modes", mode)

  # Add enable_animations based on mode (low = FALSE, others = TRUE)
  recommendations <- list(
    max_points = mode_config$max_points,
    debounce_ms = mode_config$debounce_ms,
    cache_size_mb = mode_config$cache_size_mb,
    enable_animations = (mode != "low")
  )

  return(recommendations)
}

#' Memory Usage Monitor
#' @export
monitor_memory <- function() {
  gc_info <- gc()
  
  # Windows-compatible available memory
  available_mb <- tryCatch({
    if (.Platform$OS.type == "windows") {
      # Windows fallback - can't easily get available memory
      NA
    } else {
      as.numeric(system("free -m | awk '/^Mem:/{print $7}'", intern = TRUE))
    }
  }, error = function(e) {
    NA
  })
  
  list(
    used_mb = sum(gc_info[, "used"]) / 1024,
    max_mb = sum(gc_info[, "max used"]) / 1024,
    available_mb = available_mb
  )
}