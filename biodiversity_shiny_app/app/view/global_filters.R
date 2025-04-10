box::use(
  bsicons[bs_icon],
  bslib[accordion, accordion_panel, tooltip],
  DBI[dbDisconnect, dbGetQuery],
  logger[log_info],
  shiny[isolate, moduleServer, NS, observeEvent, onStop, reactiveValues, span],
  shinyWidgets[pickerInput, updatePickerInput],
)

box::use(
  app/data/data_transformations[db_connection],
  app/logic/constants[main_query, summary_query, unique_options_query],
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
          `virtual-scroll` = 10,
          `size` = 6,
          `max-options` = 20
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- reactiveValues(
      data = NULL,
      conn = db_connection(table_name = "occurence.duckdb"),
      table_name = "occurence"
    )

    filter_choices <- dbGetQuery(
      isolate(rv$conn),
      sprintf(
        unique_options_query,
        isolate(rv$table_name),
        isolate(rv$table_name)
      )
    )

    updatePickerInput(
      inputId = "species_names",
      choices = filter_choices,
      # selected = NULL
      selected = c(
        "Wild Onion", # plantae
        "Blackstart", # animal
        "Exidia truncata", # fungi
        "Borago officinalis"
      )
    )

    observeEvent(
      input$species_names,
      {
        log_info("An update in global filters")
        placeholders <- paste(rep("?", length(input$species_names)), collapse = ", ")
        rv$data <- dbGetQuery(
          rv$conn,
          sprintf(
            main_query,
            isolate(rv$table_name),
            placeholders,
            placeholders
          ),
          params = c(input$species_names, input$species_names)
        )

        rv$summary_data <- dbGetQuery(
          rv$conn,
          sprintf(
            summary_query,
            isolate(rv$table_name),
            placeholders,
            placeholders
          ),
          params = c(input$species_names, input$species_names)
        )
      },
      ignoreInit = TRUE,
      ignoreNULL = TRUE
    )

    onStop(function() {
      cat("Doing application cleanup!")
      dbDisconnect(isolate(rv$conn))
    })

    return(rv)
  })
}
