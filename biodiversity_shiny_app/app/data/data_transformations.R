box::use(
  DBI[dbConnect],
  duckdb[duckdb],
)

#' @export
db_connection <- function(table_name) {
  conn <- dbConnect(
    duckdb(),
    dbdir = box::file(table_name),
    read_only = TRUE
  )

  conn
}
