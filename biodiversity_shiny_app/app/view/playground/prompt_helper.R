box::use(
  xtable[xtable, ],
)

#' @export
system_prompt <- function(df, name, categorical_threshold = 10) {
  schema <- df_to_schema(df, name, categorical_threshold)

  # Read the prompt file
  prompt_path <- "app/view/playground/prompt.md"
  prompt_content <- readLines(prompt_path, warn = FALSE)
  prompt_text <- paste(prompt_content, collapse = "\n")

  # Replace the placeholder with the schema
  prompt_text <- gsub("\\$\\{SCHEMA\\}", schema, prompt_text)

  prompt_text
}

df_to_schema <- function(df, name, categorical_threshold) {
  schema <- c(paste("Table:", name), "Columns:")

  column_info <- lapply(names(df), function(column) {
    # Map R classes to SQL-like types
    sql_type <- if (is.integer(df[[column]])) {
      "INTEGER"
    } else if (is.numeric(df[[column]])) {
      "FLOAT"
    } else if (is.logical(df[[column]])) {
      "BOOLEAN"
    } else if (inherits(df[[column]], "POSIXt")) {
      "DATETIME"
    } else {
      "TEXT"
    }

    info <- paste0("- ", column, " (", sql_type, ")")

    # For TEXT columns, check if they're categorical
    if (sql_type == "TEXT") {
      unique_values <- length(unique(df[[column]]))
      if (unique_values <= categorical_threshold) {
        categories <- unique(df[[column]])
        categories_str <- paste0("'", categories, "'", collapse = ", ")
        info <- c(info, paste0("  Categorical values: ", categories_str))
      }
    }

    return(info)
  })

  schema <- c(schema, unlist(column_info))
  return(paste(schema, collapse = "\n"))
}

#' @export
df_to_html <- function(df, maxrows = 5) {
  df_short <- if (nrow(df) > 10) head(df, maxrows) else df

  tbl_html <- capture.output(
    df_short |>
      xtable() |>
      print(type = "html", include.rownames = FALSE, html.table.attributes = NULL)
  ) |>
    paste(collapse = "\n")

  if (nrow(df_short) != nrow(df)) {
    rows_notice <- sprintf("\n\n(Showing only the first %s rows out of %s.)\n", maxrows, nrow(df))
  } else {
    rows_notice <- ""
  }

  paste0(tbl_html, "\n", rows_notice)
}
