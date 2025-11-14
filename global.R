
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
