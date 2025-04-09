box::use(
  ggplot2[
    ggplot, element_blank, theme, annotate,
  ],
)


#' @export
show_no_data_plot <- function(label = "No meaningful data available!") {
  plt <- ggplot() +
    annotate("text", x = 4, y = 25, size = 7, label = label) +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
    )

  return(plt)
}
