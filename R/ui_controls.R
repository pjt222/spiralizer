# ui_controls.R - Control Panel Module
#
# Provides spiral parameter controls using bslib cards.
# Minimal, focused interface with all essential controls visible.
#
#' @import shiny
#' @import bslib

# ═══════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════

#' Create Slider with Numeric Input
#'
#' Helper function that creates a slider input paired with a numeric input.
#' Both inputs sync bidirectionally via server-side observers.
#'
#' @param ns Namespace function from module
#' @param id Base input ID (numeric input will be id_num)
#' @param label Label text (NULL for no label)
#' @param min Minimum value
#' @param max Maximum value
#' @param value Initial value
#' @param step Step increment
#' @param animate Animation options (NULL for no animation)
#' @return Shiny tagList with slider and numeric input
slider_with_numeric <- function(ns, id, label, min, max, value, step = 1, animate = NULL) {
  tagList(
    # Label above the inputs
    if (!is.null(label)) {
      tags$label(label, class = "form-label mb-1")
    },
    # Flex container: slider + numeric input
    div(
      class = "slider-numeric-group d-flex align-items-start gap-2",
      # Slider takes remaining space
      div(
        class = "flex-grow-1",
        sliderInput(
          ns(id),
          label = NULL,
          min = min,
          max = max,
          value = value,
          step = step,
          ticks = FALSE,
          width = "100%",
          animate = animate
        )
      ),
      # Compact numeric input
      numericInput(
        ns(paste0(id, "_num")),
        label = NULL,
        value = value,
        min = min,
        max = max,
        step = step,
        width = "80px"
      )
    )
  )
}

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

        # Start Angle (slider + numeric)
        slider_with_numeric(
          ns = ns,
          id = "angle_start",
          label = "Start",
          min = get_setting("sliders", "angle_min"),
          max = get_setting("sliders", "angle_max"),
          value = get_setting("sliders", "angle_min"),
          step = 1,
          animate = animationOptions(
            interval = get_setting("ui", "animation_interval_ms"),
            loop = TRUE
          )
        ),

        # End Angle (slider + numeric)
        slider_with_numeric(
          ns = ns,
          id = "angle_end",
          label = "End",
          min = get_setting("sliders", "angle_min"),
          max = get_setting("sliders", "angle_max"),
          value = get_setting("ui", "default_angle_end"),
          step = 1,
          animate = animationOptions(
            interval = get_setting("ui", "animation_interval_ms"),
            loop = TRUE
          )
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

        # Point count (slider + numeric)
        slider_with_numeric(
          ns = ns,
          id = "point_density",
          label = NULL,
          min = get_setting("sliders", "density_min"),
          max = get_setting("sliders", "density_max"),
          value = get_setting("spiral", "default_points"),
          step = get_setting("ui", "slider_step_points"),
          animate = animationOptions(
            interval = get_setting("ui", "animation_interval_ms"),
            loop = TRUE
          )
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
          selected = get_setting("palette", "default"),
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
      angle_start = get_setting("sliders", "angle_min"),
      angle_end = get_setting("ui", "default_angle_end"),
      point_density = get_setting("spiral", "default_points"),
      color_palette = get_setting("palette", "default"),
      invert_palette = FALSE
    )

    # ─────────────────────────────────────────────────────────────────
    # BIDIRECTIONAL SYNC: SLIDER <-> NUMERIC INPUT
    # ─────────────────────────────────────────────────────────────────

    # Helper to sync slider and numeric input (avoids infinite loops)
    sync_slider_numeric <- function(slider_id, numeric_id) {
      # Slider → Numeric
      observeEvent(input[[slider_id]], {
        slider_val <- input[[slider_id]]
        numeric_val <- input[[numeric_id]]
        if (!is.null(slider_val) && (is.null(numeric_val) || is.na(numeric_val) || slider_val != numeric_val)) {
          updateNumericInput(session, numeric_id, value = slider_val)
        }
      }, ignoreInit = TRUE)

      # Numeric → Slider
      observeEvent(input[[numeric_id]], {
        numeric_val <- input[[numeric_id]]
        slider_val <- input[[slider_id]]
        # Skip if numeric is NA or NULL (user cleared the input)
        if (!is.null(numeric_val) && !is.na(numeric_val) && (is.null(slider_val) || numeric_val != slider_val)) {
          updateSliderInput(session, slider_id, value = numeric_val)
        }
      }, ignoreInit = TRUE)
    }

    # Set up sync for each slider-numeric pair
    sync_slider_numeric("angle_start", "angle_start_num")
    sync_slider_numeric("angle_end", "angle_end_num")
    sync_slider_numeric("point_density", "point_density_num")

    # ─────────────────────────────────────────────────────────────────
    # DEBOUNCED PARAMETER UPDATES
    # ─────────────────────────────────────────────────────────────────

    # Create debounced reactive for each input
    debounce_ms <- get_setting("reactive", "debounce_ms")
    angle_start_d <- reactive({ input$angle_start }) |> debounce(debounce_ms)
    angle_end_d <- reactive({ input$angle_end }) |> debounce(debounce_ms)
    point_density_d <- reactive({ input$point_density }) |> debounce(debounce_ms)

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
