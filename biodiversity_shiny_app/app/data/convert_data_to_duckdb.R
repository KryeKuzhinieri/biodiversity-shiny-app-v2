box::use(
  DBI[dbConnect, dbDisconnect, ],
  duckdb[duckdb, duckdb_read_csv, ],
  logger[log_info, ],
  vroom[vroom, vroom_write, ],
)

box::use(
  app / logic / constants[db_data_location, ],
)


convert_data_to_duckdb <- function(csv_file_path, filename) {
  if (!file.exists(csv_file_path)) {
    stop(paste0("Data does not exit in the path ", csv_file_path))
  }

  db_path <- file.path(db_data_location, paste0(filename, ".duckdb"))
  conn <- dbConnect(duckdb(), dbdir = db_path)
  tryCatch(
    {
      log_info("Starting convertion to duckdb...")

      # dataset is 1,000,000 rows.
      dataset <- vroom(
        file = csv_file_path,
        n_max = 200000L,
        show_col_types = FALSE
      )

      tmp_dir <- file.path(tempdir(), "dataset.csv")
      vroom_write(dataset, tmp_dir, delim = "\t")
      log_info("Data saved in ", tmp_dir)
      duckdb_read_csv(
        conn,
        name = db_path,
        files = tmp_dir,
        delim = "\t"
      )
      log_info("Conversion completed!")
    },
    error = function(e) {
      log_info(e)
      log_info("Failed to convert data to duckdb.")
    }
  )
  dbDisconnect(conn)
}

convert_data_to_duckdb(
  csv_file_path = "/media/kryekuzhinieri/Projects/Biodiversity Shiny App Version 2/biodiversity-data/occurence.csv",
  filename = "occurence"
)
