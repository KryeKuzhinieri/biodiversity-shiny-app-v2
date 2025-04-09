box::use(
  bsicons[bs_icon],
  bslib[as_fill_carrier, bs_get_variables, card, card_header, tooltip],
  leaflet[
    addAwesomeMarkers,
    addProviderTiles,
    awesomeIcons,
    clearMarkerClusters,
    clearMarkers,
    clearShapes,
    leaflet,
    leafletOptions,
    leafletOutput,
    leafletProxy,
    providers,
    renderLeaflet,
    setView
  ],
  shiny[div, modalDialog, moduleServer, NS, observe, observeEvent, req, span, showModal],
  shinycssloaders[withSpinner],
)


#' @export
ui <- function(id) {
  ns <- NS(id)
  card(
    full_screen = TRUE,
    card_header(
      span(
        "Species Sightings ",
        tooltip(
          bs_icon("info-circle"),
          "This map displays the geographic locations where different species ",
          "have been observed. Each marker represents a species sighting, ",
          "color-coded by type: red for animals, blue for fungi, and light ",
          "green for other organisms.",
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

    output$map <- renderLeaflet({
      leaflet(options = leafletOptions(scrollWheelZoom = FALSE)) |>
        addProviderTiles(providers$CartoDB.DarkMatter) |>
        setView(
          lat = 52.237049,
          lng = 21.017532,
          zoom = 3
        )
    })

    observeEvent(input$map_marker_click,
      {
        filtered_data <- state$data[input$map_marker_click$id, ]
        showModal(
          modalDialog(
            title = filtered_data$scientificName,
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
  })
}
