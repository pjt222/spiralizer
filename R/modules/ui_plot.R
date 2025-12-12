# ui_plot.R - Zen Plot Output Module
#
# Handles the spiral visualization rendering and export functionality.
# The plot fills the available viewport space.

library(shiny)
library(bslib)

# ═══════════════════════════════════════════════════════════════════════
# UI MODULE
# ═══════════════════════════════════════════════════════════════════════

#' Zen Plot UI
#'
#' Creates the plot output container that fills available space.
#' Includes loading overlay for visual feedback during computation.
#'
#' @param id Module namespace ID
#' @return Shiny tagList
#' @export
zen_plot_ui <- function(id) {
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

#' Zen Plot Server
#'
#' Handles spiral computation, caching, rendering, and export.
#' Returns computation statistics for performance monitoring.
#'
#' @param id Module namespace ID
#' @param params Reactive values from controls module
#' @return Reactive with computation statistics
#' @export
zen_plot_server <- function(id, params) {
  moduleServer(id, function(input, output, session) {

    # ─────────────────────────────────────────────────────────────────
    # REACTIVE COMPUTATION
    # ─────────────────────────────────────────────────────────────────

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

      # Time the computation
      start_time <- Sys.time()

      tryCatch({
        # Generate spiral points (vectorized)
        points <- generate_fermat_spiral(
          params$angle_start,
          params$angle_end,
          params$point_density
        )

        # Compute Voronoi
        voronoi_result <- compute_voronoi(points)

        # Calculate elapsed time
        elapsed_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

        list(
          points = points,
          voronoi = voronoi_result$voronoi,
          bounded_count = voronoi_result$bounded_count,
          elapsed_ms = elapsed_ms
        )

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
        bg = zen_colors$black,
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
            border = zen_colors$gray_mid,
            lwd = 0.5
          )
        )
      }, error = function(e) {
        text(0, 0, "Error rendering", col = zen_colors$error, cex = 1.5)
      })

    }, bg = zen_colors$black, execOnResize = TRUE)

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
      par(mar = c(0, 0, 0, 0), bg = zen_colors$black)

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
          border = zen_colors$gray_mid,
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
            width = EXPORT_PNG_SIZE,
            height = EXPORT_PNG_SIZE,
            res = EXPORT_PNG_RES,
            bg = zen_colors$black)
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
            width = EXPORT_SVG_SIZE,
            height = EXPORT_SVG_SIZE,
            bg = zen_colors$black)
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
