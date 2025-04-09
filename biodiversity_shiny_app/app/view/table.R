box::use(
  bsicons[bs_icon, ],
  bslib[as_fill_carrier, card, card_header, popover, tooltip, ],
  DT[DTOutput, renderDT, ],
  shiny[downloadButton, downloadHandler, moduleServer, NS, span, ],
  shinycssloaders[withSpinner, ],
  utils[write.csv2, ],
)


#' @export
ui <- function(id, card_title, tooltip_info) {
  ns <- NS(id)
  card(
    full_screen = TRUE,
    max_height = 350,
    card_header(
      class = "d-flex justify-content-between align-items-center",
      span(
        card_title,
        tooltip(
          bs_icon("info-circle"),
          tooltip_info,
          placement = "bottom"
        )
      ),
      popover(
        id = ns("data-popover"),
        trigger = bs_icon("gear"),
        title = "Options",
        downloadButton(ns("download_data"), label = "Download Data"),
      ),
    ),
    as_fill_carrier(
      withSpinner(
        DTOutput(ns("table")),
        color = "#25443B"
      )
    )
  )
}

#' @export
server <- function(id, state, data = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$table <- renderDT(
      if (is.null(data)) state$data else data,
      fillContainer = TRUE,
    )

    output$download_data <- downloadHandler(
      filename = function() {
        "data.csv"
      },
      content = function(file) {
        write.csv2(if (is.null(data)) state$data else data, file, row.names = FALSE)
      }
    )
  })
}
