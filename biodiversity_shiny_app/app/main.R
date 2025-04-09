box::use(
  bslib[input_dark_mode, nav_item, nav_panel, nav_spacer, page_navbar, ],
  shiny[moduleServer, NS, observeEvent, tags, isolate, onStop, ],
  shinyjs[runjs, useShinyjs],
  thematic[thematic_shiny, ],
)

box::use(
  app / logic / theming[set_theme, ],
  app / view / global_filters,
  app / view / leaflet_map,
)

# helps convert ggplot to dark/light mode.
thematic_shiny(font = "auto")

#' @export
ui <- function(id) {
  ns <- NS(id)
  page_navbar(
    title = "Biodiversity Application",
    sidebar = NULL,
    theme = set_theme(mode = "light"),
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
      "Biodiversity",
      global_filters$ui(id = ns("global_filters")),
      leaflet_map$ui(id = ns("leaflet_map")),
    ),
    nav_spacer(),
    nav_item(input_dark_mode(id = ns("theme_switch"), mode = "light"))
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    state <- global_filters$server(id = "global_filters")
    leaflet_map$server(id = "leaflet_map", state = state)
    observeEvent(input$theme_switch,
      {
        # show the logo to hide some design issues when
        # the css files get changed.
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
