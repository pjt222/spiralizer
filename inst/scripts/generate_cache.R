# generate_cache.R - Pre-compute spiral cache for deployment
#
# Run this script to generate a cache file that ships with the app.
# Usage: source("inst/scripts/generate_cache.R")
#
# Options:
#   build_cache("minimal")  - ~100 entries, fast presets only
#   build_cache("standard") - ~1,000 entries, good coverage
#   build_cache("full")     - ~10,000 entries, fine-grained
#   build_cache("exhaustive", step_angle=5, step_density=25) - custom grid

source(".Rprofile")

library(here)
library(bslib)
library(tessellation)

source(here("R/theme.R"))
source(here("R/utils/constants.R"))
source(here("R/utils/spiral_math.R"))

# Calculate estimated combinations
estimate_combinations <- function(step_angle = 1, step_density = 1,
                                   angle_max = SLIDER_ANGLE_MAX,
                                   density_min = SLIDER_DENSITY_MIN,
                                   density_max = SLIDER_DENSITY_MAX) {
  n_angles <- length(seq(0, angle_max, by = step_angle))
  n_density <- length(seq(density_min, density_max, by = step_density))
  # start < end constraint reduces by roughly half
  n_valid_angle_pairs <- (n_angles * (n_angles - 1)) / 2
  total <- n_valid_angle_pairs * n_density
  list(
    angle_values = n_angles,
    density_values = n_density,
    angle_pairs = n_valid_angle_pairs,
    total = total
  )
}

# Generate parameter combinations based on mode
generate_cache_params <- function(mode = "standard",
                                   step_angle = NULL,
                                   step_density = NULL,
                                   angle_max = NULL,
                                   density_max = NULL) {

  # Use config values as defaults
  angle_max <- angle_max %||% SLIDER_ANGLE_MAX
  density_min <- SLIDER_DENSITY_MIN
  density_max <- density_max %||% SLIDER_DENSITY_MAX

  params <- list()

  if (mode == "minimal") {
    # ~100 entries: presets and default animation paths
    step_angle <- 10
    step_density <- 50

    # Default
    params[[length(params) + 1]] <- list(start = 0, end = 100, density = 300)

    # Animate end slider (start=0, density=300)
    for (end in seq(10, 200, by = step_angle)) {
      params[[length(params) + 1]] <- list(start = 0, end = end, density = 300)
    }

    # Animate density (start=0, end=100)
    for (density in seq(density_min, 500, by = step_density)) {
      params[[length(params) + 1]] <- list(start = 0, end = 100, density = density)
    }

  } else if (mode == "standard") {
    # ~1,000 entries: broader coverage with step=10/25
    step_angle <- step_angle %||% 10
    step_density <- step_density %||% 25

    for (start in seq(0, min(200, angle_max), by = step_angle)) {
      for (end in seq(start + step_angle, min(500, angle_max), by = step_angle)) {
        for (density in seq(density_min, min(1000, density_max), by = step_density)) {
          params[[length(params) + 1]] <- list(start = start, end = end, density = density)
        }
      }
    }

  } else if (mode == "full") {
    # ~10,000 entries: finer grid
    step_angle <- step_angle %||% 5
    step_density <- step_density %||% 10

    for (start in seq(0, min(300, angle_max), by = step_angle)) {
      for (end in seq(start + step_angle, min(600, angle_max), by = step_angle)) {
        for (density in seq(density_min, min(1000, density_max), by = step_density)) {
          params[[length(params) + 1]] <- list(start = start, end = end, density = density)
        }
      }
    }

  } else if (mode == "exhaustive") {
    # Custom grid over full range
    step_angle <- step_angle %||% 10
    step_density <- step_density %||% 50

    est <- estimate_combinations(step_angle, step_density, angle_max, density_min, density_max)
    message(sprintf("Exhaustive mode: %d angle values, %d density values", est$angle_values, est$density_values))
    message(sprintf("Estimated combinations: %s", format(est$total, big.mark = ",")))

    if (est$total > 100000) {
      stop("Too many combinations! Increase step sizes or reduce range.")
    }

    for (start in seq(0, angle_max - step_angle, by = step_angle)) {
      for (end in seq(start + step_angle, angle_max, by = step_angle)) {
        for (density in seq(density_min, density_max, by = step_density)) {
          params[[length(params) + 1]] <- list(start = start, end = end, density = density)
        }
      }
    }
  }

  # Remove duplicates
  unique_params <- list()
  seen_keys <- character()
  for (p in params) {
    key <- paste(p$start, p$end, p$density, sep = "_")
    if (!(key %in% seen_keys)) {
      seen_keys <- c(seen_keys, key)
      unique_params[[length(unique_params) + 1]] <- p
    }
  }

  message(sprintf("Generated %d unique parameter combinations", length(unique_params)))
  unique_params
}

# Compute and cache all parameter combinations
build_cache <- function(mode = "standard",
                        step_angle = NULL,
                        step_density = NULL,
                        format = "rds",
                        compress = TRUE,
                        parallel = TRUE,
                        n_cores = NULL,
                        output_dir = here("inst/app/data")) {

  params_list <- generate_cache_params(mode, step_angle, step_density)

  message(sprintf("Pre-computing %d spiral configurations...", length(params_list)))

  # Ensure output directory exists
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  if (format == "duckdb") {
    build_cache_duckdb(params_list, output_dir, parallel, n_cores)
  } else {
    build_cache_rds(params_list, output_dir, compress, parallel, n_cores)
  }
}

# Compute a single spiral (worker function)
compute_single_spiral <- function(p) {
  cache_key <- paste(p$start, p$end, p$density, sep = "_")
  tryCatch({
    points <- generate_fermat_spiral(p$start, p$end, p$density)
    voronoi_result <- compute_voronoi(points)
    list(
      key = cache_key,
      data = list(
        points = points,
        voronoi = voronoi_result$voronoi,
        bounded_count = voronoi_result$bounded_count,
        elapsed_ms = 0
      )
    )
  }, error = function(e) {
    list(key = cache_key, data = NULL, error = e$message)
  })
}

# Build cache as compressed RDS (with optional parallel processing)
build_cache_rds <- function(params_list, output_dir, compress = TRUE, parallel = TRUE, n_cores = NULL) {

  # Detect cores
  if (is.null(n_cores)) {
    n_cores <- parallel::detectCores() - 1
    n_cores <- max(1, n_cores)
  }

  message(sprintf("Using %d CPU cores", n_cores))

  if (parallel && n_cores > 1) {
    # Parallel processing
    message("Starting parallel computation...")
    start_time <- Sys.time()

    # Windows uses parLapply (PSOCK cluster), Unix uses mclapply
    if (.Platform$OS.type == "windows") {
      cl <- parallel::makeCluster(n_cores)

      # Export required functions and packages to workers
      # Workers need to source the R files since they're separate processes
      spiral_math_file <- here::here("R/utils/spiral_math.R")
      constants_file <- here::here("R/utils/constants.R")

      parallel::clusterExport(cl, c("spiral_math_file", "constants_file"), envir = environment())
      parallel::clusterEvalQ(cl, {
        library(tessellation)
        library(here)
        # Source constants first (defines SPIRAL_MIN_POINTS etc)
        source(constants_file)
        # Then source spiral_math
        source(spiral_math_file)
      })
      parallel::clusterExport(cl, c("compute_single_spiral"), envir = environment())

      results <- parallel::parLapply(cl, params_list, compute_single_spiral)
      parallel::stopCluster(cl)
    } else {
      # Unix/Mac - use fork-based parallelism
      results <- parallel::mclapply(params_list, compute_single_spiral,
                                     mc.cores = n_cores)
    }

    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    message(sprintf("Parallel computation done in %.1f seconds", elapsed))

  } else {
    # Sequential processing with progress bar
    results <- list()
    pb <- txtProgressBar(min = 0, max = length(params_list), style = 3)

    for (i in seq_along(params_list)) {
      results[[i]] <- compute_single_spiral(params_list[[i]])
      setTxtProgressBar(pb, i)
    }
    close(pb)
  }

  # Convert results list to named cache
  cache <- list()
  errors <- 0
  for (r in results) {
    if (!is.null(r$data)) {
      cache[[r$key]] <- r$data
    } else {
      errors <- errors + 1
    }
  }

  if (errors > 0) {
    message(sprintf("Warning: %d entries failed to compute", errors))
  }

  # Save with compression
  output_file <- file.path(output_dir, "spiral_cache.rds")
  compress_type <- if (compress) "xz" else FALSE

  message("Compressing and saving (this may take a moment)...")
  saveRDS(cache, output_file, compress = compress_type)

  message(sprintf("\nCache saved to: %s", output_file))
  message(sprintf("Cache size: %.2f MB", file.size(output_file) / 1024^2))
  message(sprintf("Entries: %d", length(cache)))

  invisible(cache)
}

# Build cache using DuckDB for indexed lookups
build_cache_duckdb <- function(params_list, output_dir, parallel = TRUE, n_cores = NULL) {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("Install duckdb: install.packages('duckdb')")
  }
  if (!requireNamespace("DBI", quietly = TRUE)) {
    stop("Install DBI: install.packages('DBI')")
  }

  # Detect cores
  if (is.null(n_cores)) {
    n_cores <- parallel::detectCores() - 1
    n_cores <- max(1, n_cores)
  }

  message(sprintf("Using %d CPU cores for computation", n_cores))

  # Step 1: Compute all spirals in parallel
  if (parallel && n_cores > 1) {
    message("Starting parallel computation...")
    start_time <- Sys.time()

    if (.Platform$OS.type == "windows") {
      cl <- parallel::makeCluster(n_cores)

      spiral_math_file <- here::here("R/utils/spiral_math.R")
      constants_file <- here::here("R/utils/constants.R")

      parallel::clusterExport(cl, c("spiral_math_file", "constants_file"), envir = environment())
      parallel::clusterEvalQ(cl, {
        library(tessellation)
        library(here)
        source(constants_file)
        source(spiral_math_file)
      })
      parallel::clusterExport(cl, c("compute_single_spiral"), envir = environment())

      results <- parallel::parLapply(cl, params_list, compute_single_spiral)
      parallel::stopCluster(cl)
    } else {
      results <- parallel::mclapply(params_list, compute_single_spiral, mc.cores = n_cores)
    }

    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    message(sprintf("Parallel computation done in %.1f seconds", elapsed))
  } else {
    results <- lapply(params_list, compute_single_spiral)
  }

  # Step 2: Insert into DuckDB sequentially
  message("Inserting into DuckDB...")
  db_file <- file.path(output_dir, "spiral_cache.duckdb")
  unlink(db_file)

  con <- DBI::dbConnect(duckdb::duckdb(), db_file)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  DBI::dbExecute(con, "
    CREATE TABLE spiral_cache (
      cache_key VARCHAR PRIMARY KEY,
      angle_start INTEGER,
      angle_end INTEGER,
      point_density INTEGER,
      bounded_count INTEGER,
      data BLOB
    )
  ")

  errors <- 0
  for (i in seq_along(results)) {
    r <- results[[i]]
    if (!is.null(r$data)) {
      p <- params_list[[i]]
      data_blob <- serialize(r$data, NULL, xdr = FALSE)

      tryCatch({
        DBI::dbExecute(con,
          "INSERT INTO spiral_cache VALUES (?, ?, ?, ?, ?, ?)",
          params = list(r$key, p$start, p$end, p$density, r$data$bounded_count, list(data_blob))
        )
      }, error = function(e) {
        errors <<- errors + 1
      })
    } else {
      errors <- errors + 1
    }
  }

  DBI::dbExecute(con, "CREATE INDEX idx_params ON spiral_cache(angle_start, angle_end, point_density)")

  message(sprintf("\nDuckDB cache saved to: %s", db_file))
  message(sprintf("Cache size: %.2f MB", file.size(db_file) / 1024^2))
  message(sprintf("Entries: %d", length(params_list)))
}

# Run if sourced directly
if (interactive()) {
  message("Usage:")
  message('  build_cache("standard")              # Compressed RDS')
  message('  build_cache("standard", format="duckdb")  # DuckDB')
}
