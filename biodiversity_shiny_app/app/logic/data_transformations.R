box::use(
  DBI[dbConnect, ],
  duckdb[duckdb, ],
)

box::use(
  app / logic / constants[db_data_location, ],
)

#' @export
db_connection <- function(table_name) {
  conn <- dbConnect(
    duckdb(),
    dbdir = file.path(db_data_location, table_name),
    read_only = TRUE
  )

  conn
}
