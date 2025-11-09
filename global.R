
library(shiny)
library(data.table)
library(ggplot2)
library(logger) # lightweight logging
# Optional deferred libraries loaded in modules (shinydashboard, plotly, DT, shinycssloaders, shinyjs)

# Initialize logging -------------------------------------------------------
# Create log directory if missing (fails silently if exists)
if (!dir.exists("logs")) {
  dir.create("logs")
}

log_file <- file.path("logs", sprintf("app-%s.log", format(Sys.Date(), "%Y-%m-%d")))

# Set global log threshold (INFO default; can raise to WARN/ERROR in production)
log_threshold(INFO)

# Define layout with timestamp, level, namespace, message
log_layout(layout_glue_generator(format = "[{format(Sys.time(), '%Y-%m-%d %H:%M:%S')}] {toupper(level)} {namespace} - {msg}"))

# File appender + console (so messages visible interactively)
log_appender(appender_tee(log_file))

log_info("Logger initialized: {log_file}")

# Helper: safely read RDS with logging
read_rds_safely <- function(path) {
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

source('home.R')
source('loadData.R')
source('analyse.R')
source('qc.R')
source("anomaly.R")
source("pattern.R")
source("cost.R")
log_debug("Core modules sourced")


PLANS <- c("Time of Use", "Tiered Rate Plan", "Solar & Renewable Energy Plan",
           "Electric Vehicle Base Plan", "SmartRate Add-on")

TIER <- list(
  "Time of Use" = c("E-TOU-C", "E-TOU-D"),
  "Tiered Rate Plan" = c("T1 (100% baseline)", "T2 (101%-400% baseline)",
                         "T3 (> 400% baseline)"),
  "Electric Vehicle Base Plan" = c('EV2-A', 'EV-B'),
  "Solar & Renewable Energy Plan" = c("COMING-SOON"),
  "SmartRate Add-on" = c("COMING-SOON")
)

HOUR <- list(
  "E-TOU-C" = c(16,21),
  "E-TOU-D" = c(17,20)
)


AGGCHOICE <- c('Day', 'Week','Month', 'Year')
