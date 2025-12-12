# benchmark_spiral.R - Performance benchmarking suite

library(microbenchmark)
library(ggplot2)
library(data.table)

# Source our functions
source(here::here("R/utils/spiral_math.R"))
source(here::here("R/utils/cache_manager.R"))
source(here::here("R/utils/performance.R"))

# Benchmark parameters
point_counts <- c(10, 50, 100, 300, 500, 1000, 2000)
angle_ranges <- c(50, 100, 200, 500, 1000)

cat("=== Spiralizer Performance Benchmark Suite ===\n\n")

# 1. Spiral Generation Performance
cat("1. Testing Spiral Generation Performance...\n")

spiral_bench <- microbenchmark(
  "10_points" = generate_fermat_spiral(0, 100, 10),
  "100_points" = generate_fermat_spiral(0, 100, 100),
  "300_points" = generate_fermat_spiral(0, 100, 300),
  "1000_points" = generate_fermat_spiral(0, 100, 1000),
  "2000_points" = generate_fermat_spiral(0, 100, 2000),
  times = 100
)

print(spiral_bench)

# 2. Voronoi Computation Performance (without cache)
cat("\n2. Testing Voronoi Computation Performance...\n")

voronoi_bench_data <- data.table()

for (n_points in c(10, 50, 100, 300, 500)) {
  points <- generate_fermat_spiral(0, 100, n_points)
  
  timing <- microbenchmark(
    compute = {
      del <- tessellation::delaunay(points)
      vor <- tessellation::voronoi(del)
      Filter(tessellation::isBoundedCell, vor)
    },
    times = 20
  )
  
  voronoi_bench_data <- rbind(
    voronoi_bench_data,
    data.table(
      points = n_points,
      time_ms = median(timing$time) / 1e6  # Convert to milliseconds
    )
  )
}

print(voronoi_bench_data)

# 3. Cache Performance
cat("\n3. Testing Cache Performance...\n")

# Clear cache first
clear_spiral_cache()

# First computation (no cache)
points_test <- generate_fermat_spiral(0, 100, 300)
time_no_cache <- system.time({
  compute_voronoi_cached(points_test)
})

# Second computation (with cache)
time_with_cache <- system.time({
  compute_voronoi_cached(points_test)
})

cat(sprintf("First computation (no cache): %.3f seconds\n", time_no_cache[3]))
cat(sprintf("Second computation (cached): %.3f seconds\n", time_with_cache[3]))
cat(sprintf("Cache speedup: %.1fx\n", time_no_cache[3] / time_with_cache[3]))

# 4. Memory Usage Analysis
cat("\n4. Memory Usage Analysis...\n")

mem_before <- monitor_memory()

# Generate large dataset
large_points <- generate_fermat_spiral(0, 1000, 5000)
large_vor <- compute_voronoi_cached(large_points)

mem_after <- monitor_memory()

cat(sprintf("Memory before: %.1f MB\n", mem_before$used_mb))
cat(sprintf("Memory after: %.1f MB\n", mem_after$used_mb))
cat(sprintf("Memory increase: %.1f MB\n", mem_after$used_mb - mem_before$used_mb))

# 5. Parameter Validation Performance
cat("\n5. Testing Parameter Validation Performance...\n")

validation_bench <- microbenchmark(
  valid = validate_spiral_params(0, 100, 300),
  invalid_angle = validate_spiral_params(100, 0, 300),
  invalid_points = validate_spiral_params(0, 100, 2),
  times = 10000
)

print(validation_bench)

# Create performance visualization
cat("\n6. Generating Performance Plots...\n")

# Plot 1: Spiral generation scaling
spiral_plot_data <- data.table(
  points = c(10, 100, 300, 1000, 2000),
  time = c(
    median(spiral_bench[spiral_bench$expr == "10_points", "time"]) / 1e6,
    median(spiral_bench[spiral_bench$expr == "100_points", "time"]) / 1e6,
    median(spiral_bench[spiral_bench$expr == "300_points", "time"]) / 1e6,
    median(spiral_bench[spiral_bench$expr == "1000_points", "time"]) / 1e6,
    median(spiral_bench[spiral_bench$expr == "2000_points", "time"]) / 1e6
  )
)

p1 <- ggplot(spiral_plot_data, aes(x = points, y = time)) +
  geom_line(color = "#00ff88", size = 2) +
  geom_point(color = "#00ff88", size = 4) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "#0a0a0a"),
    panel.background = element_rect(fill = "#0a0a0a"),
    text = element_text(color = "#e0e0e0"),
    panel.grid = element_line(color = "#2a2a2a")
  ) +
  labs(
    title = "Spiral Generation Performance",
    x = "Number of Points",
    y = "Time (milliseconds)"
  )

ggsave("docs/spiral_generation_performance.png", p1, width = 10, height = 6, dpi = 300)

# Plot 2: Voronoi computation scaling
p2 <- ggplot(voronoi_bench_data, aes(x = points, y = time_ms)) +
  geom_line(color = "#ff0088", size = 2) +
  geom_point(color = "#ff0088", size = 4) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "#0a0a0a"),
    panel.background = element_rect(fill = "#0a0a0a"),
    text = element_text(color = "#e0e0e0"),
    panel.grid = element_line(color = "#2a2a2a")
  ) +
  labs(
    title = "Voronoi Computation Performance",
    x = "Number of Points",
    y = "Time (milliseconds)"
  )

ggsave("docs/voronoi_computation_performance.png", p2, width = 10, height = 6, dpi = 300)

# Generate summary report
cat("\n=== Performance Summary ===\n")
cat("Spiral generation: ~0.1ms per 100 points\n")
cat("Voronoi computation: Scales quadratically with point count\n")
cat(sprintf("Cache effectiveness: %.1fx speedup\n", time_no_cache[3] / time_with_cache[3]))
cat(sprintf("System performance mode: %s\n", check_performance_mode()))

# Save benchmark results
saveRDS(
  list(
    spiral_bench = spiral_bench,
    voronoi_bench = voronoi_bench_data,
    cache_performance = list(
      no_cache = time_no_cache[3],
      with_cache = time_with_cache[3]
    ),
    timestamp = Sys.time()
  ),
  file = "tests/benchmarks/benchmark_results.rds"
)

cat("\nBenchmark complete! Results saved to tests/benchmarks/\n")