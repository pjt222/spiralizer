# app_zen.R - Spiralizer Zen Mode Application
#
# Minimalist Voronoi spiral generator with bslib/Bootstrap 5 UI.
# The spiral visualization is the focus; UI disappears when not needed.
#
#' @import shiny
#' @import bslib
#' @import here

# ═══════════════════════════════════════════════════════════════════════
# UI DEFINITION
# ═══════════════════════════════════════════════════════════════════════

#' Zen UI
#'
#' Creates the main application UI using bslib components.
#' Features a collapsible sidebar and full-viewport spiral display.
#'
#' @return Shiny UI object
zen_ui <- function() {
  page_navbar(
    # App title with icon
    title = tags$span(
      class = "d-flex align-items-center gap-2",
      icon("infinity"),
      "Spiralizer"
    ),

    # Theme
    theme = spiralizer_theme,

    # Fill available space
    fillable = TRUE,
    fillable_mobile = TRUE,

    # Window title
    window_title = "Spiralizer | Zen Mode",

    # Navbar spacer (keeps title left-aligned)
    nav_spacer(),

    # Main content panel (no title, single panel app)
    nav_panel(
      title = NULL,
      value = "main",

      # Sidebar layout with collapsible controls
      layout_sidebar(
        fillable = TRUE,

        sidebar = sidebar(
          id = "controls_sidebar",
          title = NULL,  # Clean header
          open = "desktop",  # Collapsed on mobile, open on desktop
          width = 320,
          class = "zen-sidebar",

          # Controls module
          zen_controls_ui("controls")
        ),

        # Main plot area fills remaining space
        zen_plot_ui("plot")
      )
    ),

    # ─────────────────────────────────────────────────────────────────
    # HEAD ELEMENTS
    # ─────────────────────────────────────────────────────────────────
    header = tags$head(
      # Meta tags
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      tags$meta(name = "theme-color", content = "#0a0a0a"),
      tags$meta(name = "description", content = "Create beautiful Voronoi diagrams from Fermat spirals"),

      # Custom zen CSS overlay (minimal, no JS)
      tags$link(rel = "stylesheet", href = "css/zen-overlay.css")
    )
  )
}

# ═══════════════════════════════════════════════════════════════════════
# SERVER DEFINITION
# ═══════════════════════════════════════════════════════════════════════

#' Zen Server
#'
#' Main server function handling module initialization,
#' performance monitoring, and user interactions.
#'
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session
zen_server <- function(input, output, session) {

  # ─────────────────────────────────────────────────────────────────
  # PERFORMANCE SETUP
  # ─────────────────────────────────────────────────────────────────
  perf_mode <- check_performance_mode()
  perf_recommendations <- get_performance_recommendations(perf_mode)

  message(sprintf(
    "[Spiralizer] Starting in %s performance mode (max %d points, %d MB cache)",
    perf_mode,
    perf_recommendations$max_points,
    perf_recommendations$cache_size_mb
  ))

  # ─────────────────────────────────────────────────────────────────
  # MODULE INITIALIZATION
  # ─────────────────────────────────────────────────────────────────
  params <- zen_controls_server("controls")
  zen_plot_server("plot", params)

  # ─────────────────────────────────────────────────────────────────
  # SESSION LIFECYCLE
  # ─────────────────────────────────────────────────────────────────
  session$onSessionEnded(function() {
    message("[Spiralizer] Session ended")
  })
}

# ═══════════════════════════════════════════════════════════════════════
# APPLICATION OBJECT
# ═══════════════════════════════════════════════════════════════════════

#' Create Spiralizer App Object
#'
#' Returns a Shiny app object that can be run with \code{shiny::runApp()}.
#'
#' @return A Shiny app object
#' @export
spiralizer_app <- function() {
  shinyApp(ui = zen_ui(), server = zen_server)
}
