box::use(
  bsicons[bs_icon, ],
  bslib[as_fill_carrier, card, card_header, tooltip, ],
  ggplot2[
    aes, element_text, geom_line, geom_point, geom_col, geom_area,
    ggplot, labs, theme, facet_wrap,
  ],
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
        "Plot",
        tooltip(
          bs_icon("info-circle"),
          "some tooltip",
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
