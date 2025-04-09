box::use(
  bslib[input_dark_mode, nav_item, nav_panel, nav_spacer, page_navbar],
  shiny[moduleServer, NS, observeEvent, tags],
  shinyjs[runjs, useShinyjs],
  thematic[thematic_shiny],
  logger[log_info],
)

box::use(
  app / logic / theming[set_theme],
  app / view / countries_plot,
  app / view / global_filters,
  app / view / leaflet_map,
  app / view / playground / playground_main,
  app / view / table,
)

# helps convert ggplot to dark/light mode.
thematic_shiny(font = "auto")

#' @export
ui <- function(id) {
  ns <- NS(id)
  page_navbar(
    title = "Biodiversity Application",
    sidebar = NULL,
    theme = set_theme(mode = "dark"),
    fillable = FALSE,
    inverse = FALSE,
    header = tags$head(
      useShinyjs(),
      tags$div(
        id = "splash_screen",
        tags$div(
          class = "splash_screen_icons",
          tags$img(src = "static/logo.svg", class = "splash_logo"),
        )
      )
    ),
    nav_panel(
      "Overview",
      global_filters$ui(id = ns("global_filters")),
      leaflet_map$ui(id = ns("leaflet_map")),
      countries_plot$ui(id = ns("countries_plot")),
      table$ui(
        id = ns("table"),
        card_title = "Species Observation Records",
        tooltip_info = paste0(
          "This table lists individual records of species observations. ",
          "Each row includes details such as the scientific and common names, ",
          "taxonomic classification, geographic location (continent and region), ",
          "and the date and coordinates of the observation. The table supports ",
          "sorting, searching, and pagination for easy navigation through the dataset."
        )
      ),
    ),
    playground_main$ui(ns("playground_main")),
    nav_spacer(),
    nav_item(input_dark_mode(id = ns("theme_switch"), mode = "dark"))
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    log_info("Starting server...")
    state <- global_filters$server(id = "global_filters")
    leaflet_map$server(id = "leaflet_map", state = state)
    countries_plot$server(id = "countries_plot", state = state)
    table$server(id = "table", state = state)
    playground_main$server("playground_main", state = state)
    observeEvent(input$theme_switch,
      {
        # show the logo to hide some design issues when
        # the css files get changed.

        log_info("Switching theme to ", input$theme_switch)
        runjs("App.showSplash()")
        session$setCurrentTheme(set_theme(mode = input$theme_switch))
        runjs("App.removeSplash()")
      },
      ignoreInit = TRUE,
      ignoreNULL = TRUE
    )

    runjs("App.removeSplash()")
  })
}
