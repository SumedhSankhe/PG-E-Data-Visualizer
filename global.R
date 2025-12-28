
library(shiny)
library(data.table)
library(ggplot2)
library(logger) # lightweight logging
# Optional deferred libraries loaded in modules (shinydashboard, plotly, DT, shinycssloaders, shinyjs)

# Load Configuration and Helpers -------------------------------------------
source('config.R')
source('helpers.R')

# Initialize logging -------------------------------------------------------
# Create log directory if missing (fails silently if exists)
if (!dir.exists(LOG_DIR)) {
  dir.create(LOG_DIR)
}

log_file <- file.path(LOG_DIR, sprintf("app-%s.log", format(Sys.Date(), "%Y-%m-%d")))

# Set global log threshold based on environment
log_threshold(get_log_level())

# Define layout with timestamp, level, namespace, message
log_layout(layout_glue_generator(format = "[{format(Sys.time(), '%Y-%m-%d %H:%M:%S')}] {toupper(level)} {namespace} - {msg}"))

# File appender + console (so messages visible interactively)
log_appender(appender_tee(log_file))

log_info("Logger initialized: {log_file}")
log_info("Environment: {get_environment()}")
log_info("Log level: {get_log_level()}")

# Helper: safely read RDS with logging and path validation
read_rds_safely <- function(path) {
  # Validate path is within expected directory
  if (!startsWith(path, DATA_DIR) && !startsWith(path, "data")) {
    log_error("Attempted to read file outside data directory: {path}")
    return(NULL)
  }

  if (!file.exists(path)) {
    log_warn("RDS file not found at {path}")
    return(NULL)
  }

  tryCatch({
    obj <- readRDS(path)
    log_info("Loaded RDS: {path} (size={format(object.size(obj), units='auto')})")
    obj
  }, error = function(e) {
    log_error("Failed reading {path}: {e$message}")
    NULL
  })
}

# Helper: safely read meter data from SQLite or RDS fallback
read_meter_data_safely <- function(sqlite_path = "data/pge_meter_data.sqlite", rds_path = "data/meterData.rds") {
  # Try SQLite first
  if (file.exists(sqlite_path)) {
    log_info("Attempting to load data from SQLite: {sqlite_path}")
    tryCatch({
      con <- DBI::dbConnect(RSQLite::SQLite(), sqlite_path)
      on.exit(DBI::dbDisconnect(con), add = TRUE)

      # Check if table exists
      if (DBI::dbExistsTable(con, "meter_data")) {
        dt <- data.table::as.data.table(DBI::dbReadTable(con, "meter_data"))

        # Convert dttm_start from character to POSIXct
        dt[, dttm_start := as.POSIXct(dttm_start)]

        # Select only required columns
        required_cols <- c("dttm_start", "hour", "value", "day", "day2")
        available_cols <- intersect(required_cols, names(dt))
        dt <- dt[, ..available_cols]

        log_info("Loaded {nrow(dt)} rows from SQLite database")
        log_info("Date range: {min(dt$dttm_start)} to {max(dt$dttm_start)}")
        return(dt)
      } else {
        log_warn("Table 'meter_data' not found in SQLite database")
      }
    }, error = function(e) {
      log_error("Failed to read from SQLite: {e$message}")
    })
  } else {
    log_info("SQLite database not found at {sqlite_path}")
  }

  # Fallback to RDS
  log_info("Falling back to RDS file: {rds_path}")
  return(read_rds_safely(rds_path))
}

# Source modules
source('home.R')
source('loadData.R')
source('qc.R')
source("anomaly.R")
source("pattern.R")
source("cost.R")
log_debug("Core modules sourced")

# Legacy constants (maintained for backward compatibility - use config.R values instead)
PLANS <- RATE_PLANS
TIER <- RATE_TIERS
HOUR <- RATE_HOURS
AGGCHOICE <- AGG_CHOICES
