if (file.exists(".env")) {
  library(dotenv)
  load_dot_env(".env")
  message("Loaded environment variables in server.R")
} else {
  message("No .env file found in server.R")
}


if (file.exists("renv")) {
  source("renv/activate.R")
} else {
  # The `renv` directory is automatically skipped when deploying with rsconnect.
  message("No 'renv' directory found; renv won't be activated.")
}

# Allow absolute module imports (relative to the app root).
options(box.path = getwd())
