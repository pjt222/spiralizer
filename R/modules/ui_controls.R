# ui_controls.R - Zen Control Panel Module
#
# Provides spiral parameter controls using bslib cards.
# Minimal, focused interface with all essential controls visible.

library(shiny)
library(bslib)

# ═══════════════════════════════════════════════════════════════════════
# UI MODULE
# ═══════════════════════════════════════════════════════════════════════

#' Zen Control Panel UI
#'
#' Creates the control panel interface with sliders, palette selector,
#' presets, and export options organized in bslib cards.
#'
#' @param id Module namespace ID
#' @return Shiny tagList
#' @export
zen_controls_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ─────────────────────────────────────────────────────────────────
    # SPIRAL SHAPE CARD
    # ─────────────────────────────────────────────────────────────────
    card(
      class = "mb-3",
      card_header(
        class = "py-2 border-0",
        span("Spiral Shape", class = "small text-uppercase text-muted")
      ),
      card_body(
        class = "pt-0",

        # Start Angle
        sliderInput(
          ns("angle_start"),
          label = "Start",
          min = 0,
          max = 1000,
          value = 0,
          step = 1,
          width = "100%"
        ),

        # End Angle
        sliderInput(
          ns("angle_end"),
          label = "End",
          min = 0,
          max = 1000,
          value = 100,
          step = 1,
          width = "100%"
        ),

        # Point Density
        sliderInput(
          ns("point_density"),
          label = "Density",
          min = 3,
          max = 2000,
          value = 300,
          step = 1,
          width = "100%"
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
          selected = "turbo",
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

#' Zen Control Panel Server
#'
#' Handles control panel logic including parameter updates,
#' preset application, and debounced input processing.
#'
#' @param id Module namespace ID
#' @return Reactive values with current parameters
#' @export
zen_controls_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Reactive values for parameters
    params <- reactiveValues(
      angle_start = 0,
      angle_end = 100,
      point_density = 300,
      color_palette = "turbo",
      invert_palette = FALSE
    )

    # ─────────────────────────────────────────────────────────────────
    # DEBOUNCED PARAMETER UPDATES
    # ─────────────────────────────────────────────────────────────────

    # Create debounced reactive for each input
    angle_start_d <- reactive({ input$angle_start }) |> debounce(300)
    angle_end_d <- reactive({ input$angle_end }) |> debounce(300)
    point_density_d <- reactive({ input$point_density }) |> debounce(300)

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
