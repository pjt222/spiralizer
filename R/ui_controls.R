# ui_controls.R - Control Panel Module
#
# Provides spiral parameter controls using bslib cards.
# Minimal, focused interface with all essential controls visible.
#
#' @import shiny
#' @import bslib

# ═══════════════════════════════════════════════════════════════════════
# UI MODULE
# ═══════════════════════════════════════════════════════════════════════

#' Control Panel UI
#'
#' Creates the control panel interface with sliders, palette selector,
#' presets, and export options organized in bslib cards.
#'
#' @param id Module namespace ID
#' @return Shiny tagList
#' @export
controls_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ─────────────────────────────────────────────────────────────────
    # ANGLE CARD
    # ─────────────────────────────────────────────────────────────────
    card(
      class = "mb-3",
      card_header(
        class = "py-2 border-0",
        span("Angle", class = "small text-uppercase text-muted")
      ),
      card_body(
        class = "pt-0",

        # Start Angle
        sliderInput(
          ns("angle_start"),
          label = "Start",
          min = SLIDER_ANGLE_MIN,
          max = SLIDER_ANGLE_MAX,
          value = SLIDER_ANGLE_MIN,
          step = 1,
          ticks = FALSE,
          width = "100%",
          animate = animationOptions(interval = 2000, loop = TRUE)
        ),

        # End Angle
        sliderInput(
          ns("angle_end"),
          label = "End",
          min = SLIDER_ANGLE_MIN,
          max = SLIDER_ANGLE_MAX,
          value = 100,
          step = 1,
          ticks = FALSE,
          width = "100%",
          animate = animationOptions(interval = 2000, loop = TRUE)
        )
      )
    ),

    # ─────────────────────────────────────────────────────────────────
    # POINTS CARD
    # ─────────────────────────────────────────────────────────────────
    card(
      class = "mb-3",
      card_header(
        class = "py-2 border-0",
        span("Points", class = "small text-uppercase text-muted")
      ),
      card_body(
        class = "pt-0",

        # Point count (min 50, step 50 for better UX)
        sliderInput(
          ns("point_density"),
          label = NULL,
          min = SLIDER_DENSITY_MIN,
          max = SLIDER_DENSITY_MAX,
          value = SPIRAL_DEFAULT_POINTS,
          step = 50,
          ticks = FALSE,
          width = "100%",
          animate = animationOptions(interval = 2000, loop = TRUE)
        )
      )
    ),

    # ─────────────────────────────────────────────────────────────────
    # COLOR PALETTE CARD
    # ─────────────────────────────────────────────────────────────────
    card(
      class = "mb-3 overflow-visible",
      card_header(
        class = "py-2 border-0",
        span("Color", class = "small text-uppercase text-muted")
      ),
      card_body(
        class = "pt-0 overflow-visible",
        selectInput(
          ns("color_palette"),
          label = NULL,
          choices = palette_choices,
          selected = DEFAULT_PALETTE,
          width = "100%"
        ),
        input_switch(
          ns("invert_palette"),
          label = "Invert palette",
          value = FALSE
        )
      )
    )
  )
}

# ═══════════════════════════════════════════════════════════════════════
# SERVER MODULE
# ═══════════════════════════════════════════════════════════════════════

#' Control Panel Server
#'
#' Handles control panel logic including parameter updates,
#' preset application, and debounced input processing.
#'
#' @param id Module namespace ID
#' @return Reactive values with current parameters
#' @export
controls_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Reactive values for parameters
    params <- reactiveValues(
      angle_start = SLIDER_ANGLE_MIN,
      angle_end = 100,
      point_density = SPIRAL_DEFAULT_POINTS,
      color_palette = DEFAULT_PALETTE,
      invert_palette = FALSE
    )

    # ─────────────────────────────────────────────────────────────────
    # DEBOUNCED PARAMETER UPDATES
    # ─────────────────────────────────────────────────────────────────

    # Create debounced reactive for each input
    angle_start_d <- reactive({ input$angle_start }) |> debounce(DEBOUNCE_MS)
    angle_end_d <- reactive({ input$angle_end }) |> debounce(DEBOUNCE_MS)
    point_density_d <- reactive({ input$point_density }) |> debounce(DEBOUNCE_MS)

    # Update params from debounced inputs
    observe({
      req(angle_start_d())
      params$angle_start <- angle_start_d()
    })

    observe({
      req(angle_end_d())
      params$angle_end <- angle_end_d()
    })

    observe({
      req(point_density_d())
      params$point_density <- point_density_d()
    })

    # Color palette updates immediately (no computation triggered)
    observe({
      req(input$color_palette)
      params$color_palette <- input$color_palette
    })

    # Invert palette switch
    observe({
      params$invert_palette <- isTRUE(input$invert_palette)
    })

    # ─────────────────────────────────────────────────────────────────
    # RETURN PARAMETERS
    # ─────────────────────────────────────────────────────────────────

    return(params)
  })
}
