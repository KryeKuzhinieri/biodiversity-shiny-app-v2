box::use(
  bsicons[bs_icon, ],
  bslib[as_fill_carrier, card, card_body, card_header, tooltip, ],
  DT[DTOutput, renderDT, ],
  shiny[moduleServer, NS, span, ],
  shinycssloaders[withSpinner, ],
)


#' @export
ui <- function(id) {
  ns <- NS(id)
  card(
    full_screen = TRUE,
    card_header(
      span(
        "Data used for generated graphs",
        tooltip(
          bs_icon("info-circle"),
          "some tooltip",
          placement = "bottom"
        )
      )
    ),
    card_body(
      as_fill_carrier(
        withSpinner(DTOutput(outputId = ns("table"), width = "100%"), color = "#25443B")
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$table <- renderDT(
      state$data,
      fillContainer = TRUE,
    )
  })
}
