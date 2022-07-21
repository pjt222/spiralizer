library(shiny)
library(shiny.semantic)
library(tessellation)
library(viridisLite)

draw_voronoi_fermat_spiral <- function(from = 0, to = 111L, length = 333L) {
  theta <- seq(from, to, length.out = length)
  x <- sqrt(theta) * cos(theta)
  y <- sqrt(theta) * sin(theta)
  pts <- cbind(x, y)
  opar <- par(
    mar = c(0, 0, 0, 0)# , bg = "black"
  )
  
  plot(NULL,
       asp = 1, xlim = c(-20, 20), ylim = c(-20, 20),
       xlab = NA, ylab = NA, axes = FALSE
  )
  
  del <- delaunay(pts)
  v <- voronoi(del)
  l <- length(Filter(isBoundedCell, v))
  
  suppressMessages(plotVoronoiDiagram(v, colors = turbo(l)))
}

ui <- semanticPage(
  tags$br(),
  div(
    class = "ui grid",
    div(
      class = "two column row",
      # input
      div(
        class = "column",
        segment(
          form(
            field(
              numeric_input("from", "from", value = 0, min = 0, max = 1000)
            ),
            field(
              numeric_input("to", "to", value = 111, min = 0, max = 1000)
            ),
            field(
              numeric_input("length", "length", value = 333, min = 0, max = 1000)
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
        plotOutput("plot")
      )
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
  output$plot <- renderPlot({
    if (is.null(v$from) & is.null(v$to) & is.null(v$flength)) {
      return()
    }
    draw_voronoi_fermat_spiral(from = v$from,
                               to = v$to,
                               length = v$length)
  })
}

shinyApp(ui, server)
