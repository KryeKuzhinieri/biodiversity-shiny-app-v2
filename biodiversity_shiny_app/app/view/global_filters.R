box::use(
  bsicons[bs_icon, ],
  bslib[accordion, accordion_panel, tooltip, ],
  DBI[dbDisconnect, dbGetQuery, ],
  shiny[reactiveValues, observeEvent, moduleServer, NS, span, onStop, ],
  shinyWidgets[pickerInput, updatePickerInput, ],
)

box::use(
  app / logic / data_transformations[db_connection, ],
)


#' @export
ui <- function(id) {
  ns <- NS(id)
  accordion(
    open = FALSE,
    class = "bslib-mb-spacing",
    accordion_panel(
      title = span(
        "Global Filters",
        tooltip(
          bs_icon("info-circle"),
          "Global filters enable you to refine the data displayed across the entire ",
          "dashboard, including both charts and tables. Any changes to the filters ",
          "will automatically update the dashboard to reflect the new data state.",
          placement = "bottom"
        )
      ),
      icon = bs_icon("gear"),
      value = "global_filters",
      pickerInput(
        inputId = ns("species_names"),
        label = "Vernacular or Scientific Name",
        choices = NULL,
        multiple = TRUE,
        options = list(
          `live-search` = TRUE,
          `live-search-placeholder` = "Search",
          `none-selected-text` = "Select Fields",
          `tick-icon` = "",
          `virtual-scroll` = 10,
          `size` = 6,
          `max-options` = 100
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    table_name <- "app/data/occurence.duckdb"

    rv <- reactiveValues(
      data = NULL,
    )

    conn <- db_connection(table_name = "occurence.duckdb")
    all_options_query <- paste(
      "SELECT DISTINCT vernacularName FROM 'app/data/occurence.duckdb'",
      "UNION",
      "SELECT DISTINCT scientificName FROM 'app/data/occurence.duckdb'",
      sep = " "
    )

    filter_choices <- dbGetQuery(conn, all_options_query)

    updatePickerInput(
      inputId = "species_names",
      choices = filter_choices,
      selected = c(
        "Wild Onion",
        "Blackstart"
      )
    )

    observeEvent(
      input$species_names,
      {
        placeholders <- paste(rep("?", length(input$species_names)), collapse = ", ")
        query <- sprintf("SELECT * FROM '%s' WHERE vernacularName IN (%s)
        OR scientificName IN (%s)", table_name, placeholders, placeholders)
        rv$data <- dbGetQuery(conn, query, params = c(input$species_names, input$species_names))
      },
      ignoreInit = TRUE,
      ignoreNULL = TRUE
    )

    onStop(function() {
      cat("Doing application cleanup!")
      dbDisconnect(conn)
    })

    return(rv)
  })
}
