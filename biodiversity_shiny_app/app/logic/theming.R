box::use(
  bslib[bs_add_rules, bs_theme, font_face, ],
  shiny[addResourcePath, ],
)


theme_tweaks <- list(
  # variables can be found here:
  # https://rstudio.github.io/bslib/articles/bs5-variables/index.html#font-weight-bold
  ".card-header { font-weight: $font-weight-bold !important }",
  ".navbar-brand { font-weight: $font-weight-bolder !important }",

  # Custom theming
  ".sidebar-right .dropdown-menu .show { max-width: 230px !important}",
  ".notify { color: red !important; }",
  ".modal { z-index: 10000; }"
)

#' @export
set_theme <- function(mode = "dark", ...) {
  # In order to avoid long wait times for fonts, we need to pre-download them
  # and tell shiny to find them in the custom_fonts directory.
  addResourcePath("custom_fonts", "app/static/fonts")

  base_font <- font_face(
    family = "Inter",
    src = "url('/custom_fonts/inter_font.woff') format('truetype')"
  )
  preset <- if (mode == "dark") "darkly" else "flatly"

  bs_theme(
    version = 5,
    preset = preset,
    base_font = base_font,
    theme_mode = mode,
    "navbar-light-active-color" = "#18bc9c !important;",
    "nav-link-hover-color" = "#18bc9c !important;",
    "navbar-light-color" = "#FFFFFF !important;",
    ...
  ) |>
    bs_add_rules(theme_tweaks)
}
