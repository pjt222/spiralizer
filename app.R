library(shiny)
library(shiny.semantic)
library(tessellation)
library(viridisLite)

get_plot_limits <- function(v) {
  res <- lapply(v, function(a) {
    res <- lapply(a[["cell"]], function(b) {
      rbind(
        b[["A"]],
        b[["B"]]
      )
    })
  })

  res <- abs(unlist(res))

  c(ceiling(max(res)) * -1, ceiling(max(res)))
}


draw_voronoi_fermat_spiral <- function(from = 0, to = 100L, length = 300L) {
  theta <- seq(from, to, length.out = length)
  x <- sqrt(theta) * cos(theta)
  y <- sqrt(theta) * sin(theta)
  pts <- cbind(x, y)
  opar <- par(
    mar = c(0, 0, 0, 0), bg = "black"
  )

  del <- delaunay(pts)
  v <- voronoi(del)
  l <- length(Filter(isBoundedCell, v))

  plot(NULL,
    asp = 1, xlim = get_plot_limits(v), ylim = get_plot_limits(v),
    xlab = NA, ylab = NA, axes = FALSE
  )

  suppressMessages(
    plotVoronoiDiagram(
      v,
      colors = turbo(l),
      alpha = .5
    )
  )
}

ui <- semanticPage(
  tags$br(),
  tags$head(tags$style("body {background-color: #000000; }")),
  div(
    class = "ui grid",
    div(
      class = "two column row",
      # input
      div(
        class = "column",
        style = "width:20%!important",
        segment(
          form(
            field(
              numeric_input("from", "from", value = 0, min = 0, max = 1000)
            ),
            field(
              numeric_input("to", "to", value = 100, min = 0, max = 1000)
            ),
            field(
              numeric_input("length", "length", value = 300, min = 0, max = 1000)
            ),
            field(
              actionButton("goButton", "Go!", class = "btn-success")
            )
          )
        )
      ),
      # plot
      div(
        class = "column",
        style = "width:70%!important;justify-content:center!important;align-items:center!important;",
        plotOutput("plot", 
                   width = "80%",
                   height = "600px")
      )
    )
  ),
  br(),
  div(
    class = "row",
    style = "color:white",
    a(
      href = "https://stla.github.io/tessellation/reference/plotVoronoiDiagram.html",
      "Kudos to Stéphane Laurent | tessellation"
    )
  )
)

server <- function(input, output) {
  v <- reactiveValues(data = NULL)
  observeEvent(input$goButton, {
    v$from <- input$from
    v$to <- input$to
    v$length <- input$length
  })

  output$plot <- renderPlot(execOnResize = FALSE, {
    if (is.null(v$from) & is.null(v$to) & is.null(v$flength)) {
      return({
        opar <- par(
          mar = c(0, 0, 0, 0), bg = "grey"
        )
        plot(NULL, xlim = c(-2, 2), ylim = c(-2, 2))
        text(0, 1, substitute(paste("Welcome to ", bold("spiralizer!"))))
        text(0, 0, substitute(
          paste(
            "This app wraps the 2D example of ", italic("plotVoronoiDiagram"), 
            " of the tessellation package. "
          )
        ))
        text(0, -1, "Choose your values on the left and click Go!")
      })
    }
    draw_voronoi_fermat_spiral(
      from = v$from,
      to = v$to,
      length = v$length
    )
  })
}

shinyApp(ui, server)
