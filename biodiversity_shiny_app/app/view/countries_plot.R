box::use(
  bsicons[bs_icon, ],
  bslib[as_fill_carrier, card, card_header, tooltip, ],
  ggplot2[aes, facet_wrap, geom_area, ggplot, labs, ],
  plotly[ggplotly, plotlyOutput, renderPlotly, ],
  shiny[moduleServer, NS, span, ],
  shinycssloaders[withSpinner, ],
)

box::use(
  app / logic / utils[show_no_data_plot, ],
)


#' @export
ui <- function(id) {
  ns <- NS(id)
  card(
    full_screen = TRUE,
    card_header(
      span(
        "Monthly Species Observations by Country",
        tooltip(
          bs_icon("info-circle"),
          "This plot displays the number of species observations recorded over ",
          "time, broken down by month. Each panel represents a different ",
          "species based on its common name. Observations are grouped and ",
          "color-coded by region to highlight differences in reporting ",
          "trends across areas.",
          placement = "bottom"
        )
      )
    ),
    as_fill_carrier(
      withSpinner(
        plotlyOutput(outputId = ns("plot")),
        color = "#25443B"
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$plot <- renderPlotly({
      dataset <- state$summary_data

      if (is.null(dataset)) {
        return(ggplotly(show_no_data_plot(), tooltip = NULL))
      }
      p <- ggplot(dataset, aes(x = event_month, y = observation_count, fill = country)) +
        geom_area(position = "stack") +
        facet_wrap(~vernacularName, scales = "free_y") +
        labs(
          title = "",
          x = "Month",
          y = "Number of Observations"
        )

      ggplotly(p)
    })
  })
}
