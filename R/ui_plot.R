# ui_plot.R - Plot Output Module
#
# Handles the spiral visualization rendering and export functionality.
# The plot fills the available viewport space.
#
#' @import shiny
#' @import bslib
#' @importFrom grDevices dev.off png svg colorRampPalette

# ═══════════════════════════════════════════════════════════════════════
# UI MODULE
# ═══════════════════════════════════════════════════════════════════════

#' Plot UI
#'
#' Creates the plot output container that fills available space.
#' Includes loading overlay for visual feedback during computation.
#'
#' @param id Module namespace ID
#' @return Shiny tagList
#' @export
plot_ui <- function(id) {
  ns <- NS(id)

  div(
    class = "plot-container position-relative h-100 w-100",

    # Main plot output - fills container
    plotOutput(
      ns("spiral_plot"),
      width = "100%",
      height = "100%"
    ),

    # Export buttons - floating at bottom right
    div(
      class = "export-controls position-absolute d-flex gap-2",
      style = "bottom: 20px; right: 20px; z-index: 50;",
      downloadButton(
        ns("export_png"),
        tagList(icon("image"), " PNG"),
        class = "btn-outline-light btn-sm"
      ),
      downloadButton(
        ns("export_svg"),
        tagList(icon("file-code"), " SVG"),
        class = "btn-outline-light btn-sm"
      )
    )
  )
}

# ═══════════════════════════════════════════════════════════════════════
# SERVER MODULE
# ═══════════════════════════════════════════════════════════════════════

#' Plot Server
#'
#' Handles spiral computation, caching, rendering, and export.
#' Returns computation statistics for performance monitoring.
#'
#' @param id Module namespace ID
#' @param params Reactive values from controls module
#' @return Reactive with computation statistics
#' @export
plot_server <- function(id, params) {
  moduleServer(id, function(input, output, session) {

    # ─────────────────────────────────────────────────────────────────
    # REACTIVE COMPUTATION
    # ─────────────────────────────────────────────────────────────────

    # Load pre-computed cache if available (RDS or DuckDB)
    cache_config <- local({
      # Check for DuckDB first (preferred for large caches)
      db_paths <- c(
        here::here("inst", "app", "data", "spiral_cache.duckdb"),
        system.file("app", "data", "spiral_cache.duckdb", package = "spiralizer")
      )
      for (path in db_paths) {
        if (nzchar(path) && file.exists(path) && requireNamespace("duckdb", quietly = TRUE)) {
          message(sprintf("[Cache] Using DuckDB cache: %s", path))
          return(list(type = "duckdb", path = path, data = NULL))
        }
      }

      # Fall back to RDS
      rds_paths <- c(
        here::here("inst", "app", "data", "spiral_cache.rds"),
        system.file("app", "data", "spiral_cache.rds", package = "spiralizer")
      )
      for (path in rds_paths) {
        if (nzchar(path) && file.exists(path)) {
          message(sprintf("[Cache] Loading RDS cache: %s", path))
          cache <- tryCatch(readRDS(path), error = function(e) list())
          message(sprintf("[Cache] Loaded %d pre-computed entries", length(cache)))
          return(list(type = "rds", path = path, data = cache))
        }
      }

      list(type = "none", path = NULL, data = list())
    })

    # DuckDB connection (lazy, kept open for session)
    duckdb_con <- if (cache_config$type == "duckdb") {
      DBI::dbConnect(duckdb::duckdb(), cache_config$path, read_only = TRUE)
    } else {
      NULL
    }

    # Clean up DuckDB connection on session end
    if (!is.null(duckdb_con)) {
      session$onSessionEnded(function() {
        tryCatch(DBI::dbDisconnect(duckdb_con), error = function(e) NULL)
      })
    }

    # Helper to lookup from DuckDB
    lookup_duckdb <- function(cache_key) {
      if (is.null(duckdb_con)) return(NULL)
      tryCatch({
        result <- DBI::dbGetQuery(duckdb_con,
          "SELECT data FROM spiral_cache WHERE cache_key = ?",
          params = list(cache_key)
        )
        if (nrow(result) > 0) {
          unserialize(result$data[[1]])
        } else {
          NULL
        }
      }, error = function(e) NULL)
    }

    # Session-level cache (starts with RDS entries if available)
    precomputed_cache <- if (cache_config$type == "rds") cache_config$data else list()
    session_cache <- reactiveVal(precomputed_cache)

    spiral_data <- reactive({
      # Require all parameters
      req(params$angle_start, params$angle_end, params$point_density)

      # Validate parameters
      validation <- validate_spiral_params(
        params$angle_start,
        params$angle_end,
        params$point_density
      )

      if (!validation$valid) {
        showNotification(
          validation$message,
          type = "error",
          duration = 3
        )
        return(NULL)
      }

      # Get truncation settings
      truncate_enabled <- isTRUE(params$truncate_enabled)
      truncate_factor <- params$truncate_factor %||% get_setting("truncation", "factor_default")

      # Create cache key from parameters (include truncation settings)
      cache_key <- if (truncate_enabled) {
        paste(params$angle_start, params$angle_end, params$point_density,
              "trunc", truncate_factor, sep = "_")
      } else {
        paste(params$angle_start, params$angle_end, params$point_density, sep = "_")
      }

      # Check session cache first (includes pre-loaded RDS)
      cache <- session_cache()
      if (cache_key %in% names(cache)) {
        message(sprintf("[Cache HIT] %s", cache_key))
        return(cache[[cache_key]])
      }

      # Check DuckDB if available
      if (cache_config$type == "duckdb") {
        db_result <- lookup_duckdb(cache_key)
        if (!is.null(db_result)) {
          message(sprintf("[DuckDB HIT] %s", cache_key))
          # Add to session cache for faster subsequent access
          cache[[cache_key]] <- db_result
          session_cache(cache)
          return(db_result)
        }
      }

      message(sprintf("[Cache MISS] Computing %s", cache_key))

      # Time the computation
      start_time <- Sys.time()

      tryCatch({
        # Generate spiral points (vectorized)
        points <- generate_fermat_spiral(
          params$angle_start,
          params$angle_end,
          params$point_density
        )

        # Apply truncation if enabled
        if (truncate_enabled) {
          points <- truncate_spiral_points(points, factor = truncate_factor)
        }

        # Compute Voronoi
        voronoi_result <- compute_voronoi(points)

        # Calculate elapsed time
        elapsed_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

        result <- list(
          points = points,
          voronoi = voronoi_result$voronoi,
          bounded_count = voronoi_result$bounded_count,
          elapsed_ms = elapsed_ms
        )

        # Store in session cache
        cache[[cache_key]] <- result
        session_cache(cache)

        result

      }, error = function(e) {
        showNotification(
          paste("Computation error:", e$message),
          type = "error",
          duration = 5
        )
        NULL
      })
    })

    # ─────────────────────────────────────────────────────────────────
    # MAIN PLOT OUTPUT
    # ─────────────────────────────────────────────────────────────────

    output$spiral_plot <- renderPlot({
      data <- spiral_data()
      req(data)

      # Set up plot parameters - zen black background
      par(
        mar = c(0, 0, 0, 0),
        bg = theme_colors$black,
        xaxs = "i",
        yaxs = "i"
      )

      # Calculate plot limits
      plot_limits <- calculate_plot_limits(data$voronoi)

      # Initialize empty plot
      plot(
        NULL,
        xlim = plot_limits,
        ylim = plot_limits,
        asp = 1,
        axes = FALSE,
        xlab = "",
        ylab = ""
      )

      # Get color palette (centralized in color_utils.R)
      colors <- get_color_palette(
        params$color_palette,
        data$bounded_count,
        params$invert_palette
      )

      # Draw Voronoi diagram
      tryCatch({
        suppressMessages(
          tessellation::plotVoronoiDiagram(
            data$voronoi,
            colors = colors,
            alpha = 0.8,
            border = theme_colors$gray_mid,
            lwd = 0.5
          )
        )
      }, error = function(e) {
        text(0, 0, "Error rendering", col = theme_colors$error, cex = 1.5)
      })

    }, bg = theme_colors$black, execOnResize = TRUE)

    # ─────────────────────────────────────────────────────────────────
    # EXPORT HANDLERS
    # ─────────────────────────────────────────────────────────────────

    # Helper function to generate filename
    make_filename <- function(extension) {
      paste0(
        "spiral_",
        params$angle_start, "_",
        params$angle_end, "_",
        params$point_density, "_",
        format(Sys.time(), "%Y%m%d_%H%M%S"),
        ".", extension
      )
    }

    # Helper function to render plot to device
    render_plot <- function(data) {
      par(mar = c(0, 0, 0, 0), bg = theme_colors$black)

      plot_limits <- calculate_plot_limits(data$voronoi)
      plot(NULL, xlim = plot_limits, ylim = plot_limits,
           asp = 1, axes = FALSE, xlab = "", ylab = "")

      # Get color palette (centralized in color_utils.R)
      colors <- get_color_palette(
        params$color_palette,
        data$bounded_count,
        params$invert_palette
      )

      suppressMessages(
        tessellation::plotVoronoiDiagram(
          data$voronoi,
          colors = colors,
          alpha = 0.8,
          border = theme_colors$gray_mid,
          lwd = 1
        )
      )
    }

    # PNG export - high resolution
    output$export_png <- downloadHandler(
      filename = function() { make_filename("png") },
      content = function(file) {
        data <- spiral_data()
        req(data)

        png(file,
            width = get_setting("export", "png_size"),
            height = get_setting("export", "png_size"),
            res = get_setting("export", "png_resolution"),
            bg = theme_colors$black)
        render_plot(data)
        dev.off()
      }
    )

    # SVG export - vector format
    output$export_svg <- downloadHandler(
      filename = function() { make_filename("svg") },
      content = function(file) {
        data <- spiral_data()
        req(data)

        svg(file,
            width = get_setting("export", "svg_size"),
            height = get_setting("export", "svg_size"),
            bg = theme_colors$black)
        render_plot(data)
        dev.off()
      }
    )

    # ─────────────────────────────────────────────────────────────────
    # RETURN STATISTICS
    # ─────────────────────────────────────────────────────────────────

    return(
      reactive({
        data <- spiral_data()
        if (is.null(data)) return(NULL)

        list(
          computation_time = data$elapsed_ms %||% 0,
          point_count = params$point_density,
          cell_count = data$bounded_count %||% 0
        )
      })
    )
  })
}
