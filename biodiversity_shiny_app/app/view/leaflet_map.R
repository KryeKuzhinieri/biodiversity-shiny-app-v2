box::use(
  bsicons[bs_icon],
  DBI[dbDisconnect, dbGetQuery, ],
  bslib[as_fill_carrier, card, card_header, tooltip, bs_get_variables, ],
  leaflet[
    leaflet, leafletOutput, renderLeaflet, addTiles, addAwesomeMarkers,
    awesomeIcons,
    setView, leafletProxy, clearShapes, clearMarkers, clearMarkerClusters,
    addProviderTiles, providers,
  ],
  shiny[showModal, span, modalDialog, moduleServer, NS, observe, req, observeEvent, onStop, div, isolate, ],
  shinycssloaders[withSpinner, ],
)


box::use(
  app / logic / data_transformations[db_connection, ],
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  card(
    full_screen = TRUE,
    card_header(
      span(
        "My title",
        tooltip(
          bs_icon("info-circle"),
          "My tooltip",
          placement = "bottom"
        )
      )
    ),
    as_fill_carrier(
      withSpinner(
        leafletOutput(ns("map"), height = 400),
        color = "#25443B"
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    conn <- db_connection(table_name = "multimedia.duckdb")
    table_name <- "app/data/multimedia.duckdb"

    output$map <- renderLeaflet({
      leaflet() |>
        addProviderTiles(providers$CartoDB.DarkMatter) |>
        setView(
          lat = 52.237049,
          lng = 21.017532,
          zoom = 4
        )
    })

    observeEvent(input$map_marker_click,
      {
        print(input$map_marker_click)
        cols <- c(
          "id", "scientificName", "taxonRank", "kingdom",
          "continent", "country", "countryCode", "eventDate"
        )
        filtered_data <- state$data[input$map_marker_click$id, cols]
        # filtered_data <- state$data[input$map_marker_click$id, ]
        query <- sprintf(
          "SELECT * FROM '%s' WHERE CoreId = '%s'",
          table_name,
          filtered_data[1, "id"]
        )
        print(query)
        my_data <- dbGetQuery(conn, query)
        print(filtered_data)
        print("-----")
        print(my_data)
        showModal(
          modalDialog(
            title = filtered_data$cro.name,
            size = "l",
            easyClose = TRUE,
            lapply(names(filtered_data), function(col_name) {
              div(
                class = "more-info-title", col_name,
                div(class = "more-info-value", filtered_data[[col_name]])
              )
            })
          )
        )
      },
      ignoreNULL = TRUE
    )

    observe({
      req(state$data)
      current_theme <- bs_get_variables(
        session$getCurrentTheme(),
        varnames = c("theme_mode")
      )
      tile_provider <- if (current_theme[["theme_mode"]] == "light") {
        providers$CartoDB.Positron
      } else {
        providers$CartoDB.DarkMatter
      }

      leafletProxy(ns("map")) |>
        addProviderTiles(tile_provider)
    })

    observe({
      req(state$data)
      leafletProxy(ns("map")) |>
        clearShapes() |>
        clearMarkers() |>
        clearMarkerClusters() |>
        addAwesomeMarkers(
          lat = state$data$latitudeDecimal,
          lng = state$data$longitudeDecimal,
          label = state$data$scientificName,
          icon = awesomeIcons(
            library = "fa",
            icon = ifelse(
              state$data$kingdom == "Animalia", "paw",
              ifelse(state$data$kingdom == "Fungi", "globe", "pagelines")
            ),
            markerColor = ifelse(
              state$data$kingdom == "Animalia", "lightred",
              ifelse(state$data$kingdom == "Fungi", "lightblue", "lightgreen")
            )
          ),
          layerId = seq_len(nrow(state$data))
        )
    })

    onStop(function() {
      cat("Doing application cleanup!")
      dbDisconnect(conn)
    })
  })
}
