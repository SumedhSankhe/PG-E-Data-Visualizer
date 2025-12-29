#!/usr/bin/env Rscript
#
# Process PGE Data from CSV to SQLite Database
# Auto-detects data interval (15-min, hourly, daily) and aggregates to hourly
# Merges new data with existing database
# Removes duplicates and sorts by timestamp
#

library(data.table)
library(DBI)
library(RSQLite)
library(logger)

# Configuration
NEW_CSV <- "data/pge_latest.csv"
DB_FILE <- "data/pge_meter_data.sqlite"
BACKUP_RDS <- "data/meterData.rds"  # Keep RDS as backup
LOG_FILE <- "logs/data-processing.log"

# Setup logging
dir.create("logs", showWarnings = FALSE, recursive = TRUE)
log_appender(appender_tee(appender_console(), appender_file(LOG_FILE)))
log_info("=" , rep("=", 58))
log_info("PGE Data Processing Script")
log_info("=" , rep("=", 58))

# Validate input file exists
if (!file.exists(NEW_CSV)) {
  log_error("New CSV file not found: {NEW_CSV}")
  stop("CSV file not found")
}

# Load new CSV data
log_info("Loading new CSV data from {NEW_CSV}")
new_dt <- fread(NEW_CSV)
log_info("Loaded {nrow(new_dt)} rows from CSV")

# Check if we need to detect and aggregate intervals
# Expected columns from PGE API might vary
if ("dttm_start" %in% names(new_dt) && "value" %in% names(new_dt)) {
  log_info("CSV has standard format (dttm_start, value)")

  # Data type conversions
  log_info("Converting data types")
  new_dt[, dttm_start := as.POSIXct(dttm_start)]
  new_dt[, value := as.numeric(value)]

  # Auto-detect interval
  if (nrow(new_dt) >= 2) {
    time_diffs <- diff(as.numeric(new_dt$dttm_start[1:min(100, nrow(new_dt))]))
    median_diff_minutes <- median(time_diffs, na.rm = TRUE) / 60

    log_info("Detected interval: {round(median_diff_minutes)} minutes")

    # If data is sub-hourly (15-min or 30-min), aggregate to hourly
    if (median_diff_minutes < 60) {
      log_info("Aggregating {round(median_diff_minutes)}-minute data to hourly")

      # Round timestamps to nearest hour
      new_dt[, hour_timestamp := as.POSIXct(format(dttm_start, "%Y-%m-%d %H:00:00"))]

      # Aggregate by hour (sum values)
      aggregated <- new_dt[, .(
        value = sum(value, na.rm = TRUE),
        count = .N
      ), by = hour_timestamp]

      # Rename hour_timestamp back to dttm_start
      setnames(aggregated, "hour_timestamp", "dttm_start")

      log_info("Aggregated {nrow(new_dt)} rows to {nrow(aggregated)} hourly rows")
      log_info("Average intervals per hour: {round(mean(aggregated$count), 1)}")

      new_dt <- aggregated[, .(dttm_start, value)]
    }
  }

  # Add hour column
  if (!"hour" %in% names(new_dt)) {
    new_dt[, hour := as.integer(format(dttm_start, "%H"))]
    log_info("Added 'hour' column")
  } else {
    new_dt[, hour := as.integer(hour)]
  }

} else {
  # Try to handle other formats (like PGE Green Button CSV)
  log_warn("Non-standard CSV format detected, attempting to parse...")

  # Check for common PGE column names
  possible_timestamp_cols <- c("DATE", "START TIME", "TIMESTAMP", "datetime", "timestamp")
  possible_value_cols <- c("USAGE (kWh)", "USAGE", "value", "consumption", "kwh")

  timestamp_col <- NULL
  value_col <- NULL

  for (col in possible_timestamp_cols) {
    if (col %in% names(new_dt)) {
      timestamp_col <- col
      break
    }
  }

  for (col in possible_value_cols) {
    if (col %in% names(new_dt)) {
      value_col <- col
      break
    }
  }

  if (is.null(timestamp_col) || is.null(value_col)) {
    log_error("Could not identify timestamp and value columns")
    log_error("Available columns: {paste(names(new_dt), collapse=', ')}")
    stop("Unknown CSV format")
  }

  log_info("Using timestamp column: {timestamp_col}")
  log_info("Using value column: {value_col}")

  # Parse and convert
  # ... (rest of parsing logic)
  stop("Custom parsing not yet implemented - please use standard format")
}

# Validate required columns after processing
required_cols <- c("dttm_start", "hour", "value")
missing <- setdiff(required_cols, names(new_dt))
if (length(missing) > 0) {
  log_error("Missing required columns after processing: {paste(missing, collapse=', ')}")
  stop("Missing required columns")
}

# Ensure correct data types
new_dt[, dttm_start := as.POSIXct(dttm_start)]
new_dt[, hour := as.integer(hour)]
new_dt[, value := as.numeric(value)]

# Add derived columns if missing
if (!"day" %in% names(new_dt)) {
  new_dt[, day := as.integer(as.Date(dttm_start) - min(as.Date(dttm_start)) + 1)]
  log_info("Added 'day' column")
}
if (!"day2" %in% names(new_dt)) {
  new_dt[, day2 := day]
  log_info("Added 'day2' column")
}

# Connect to SQLite database
log_info("Connecting to SQLite database: {DB_FILE}")
con <- dbConnect(RSQLite::SQLite(), DB_FILE)

# Ensure proper cleanup on exit
on.exit({
  if (exists("con") && !is.null(con)) {
    dbDisconnect(con)
    log_info("Database connection closed")
  }
})

# Create table if it doesn't exist
log_info("Ensuring meter_data table exists")
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS meter_data (
    dttm_start TEXT NOT NULL,
    hour INTEGER NOT NULL,
    value REAL NOT NULL,
    day INTEGER,
    day2 INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (dttm_start, hour)
  )
")

# Create index for faster queries
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_dttm_start ON meter_data(dttm_start)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_hour ON meter_data(hour)")

# Load existing data from database
existing_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM meter_data")$count
log_info("Existing database contains {existing_count} rows")

if (existing_count > 0) {
  existing_range <- dbGetQuery(con, "
    SELECT MIN(dttm_start) as min_date, MAX(dttm_start) as max_date
    FROM meter_data
  ")
  log_info("Existing date range: {existing_range$min_date} to {existing_range$max_date}")
}

# Insert new data (using INSERT OR REPLACE to handle duplicates)
log_info("Inserting new data into database")

# Convert POSIXct to character for SQLite storage
new_dt[, dttm_start := as.character(dttm_start)]

# Write to database (will replace duplicates)
rows_before <- dbGetQuery(con, "SELECT COUNT(*) as count FROM meter_data")$count
dbWriteTable(con, "meter_data", new_dt, append = TRUE, overwrite = FALSE)

# Remove duplicates (keep most recent)
log_info("Removing duplicate entries")
dbExecute(con, "
  DELETE FROM meter_data
  WHERE rowid NOT IN (
    SELECT MAX(rowid)
    FROM meter_data
    GROUP BY dttm_start, hour
  )
")

rows_after <- dbGetQuery(con, "SELECT COUNT(*) as count FROM meter_data")$count
new_rows_added <- rows_after - rows_before

log_info("Database updated: {new_rows_added} new rows added")
log_info("Total rows in database: {rows_after}")

# Read all data back for validation and RDS backup
log_info("Reading data from database for validation")
combined_dt <- as.data.table(dbReadTable(con, "meter_data"))

# Convert dttm_start back to POSIXct
combined_dt[, dttm_start := as.POSIXct(dttm_start)]

# Sort by timestamp
setorder(combined_dt, dttm_start)

# Validation
if (nrow(combined_dt) == 0) {
  log_error("Database is empty after processing")
  stop("No data in database")
}

# Save backup RDS file (for fallback compatibility)
log_info("Saving backup RDS file: {BACKUP_RDS}")
# Select only essential columns for RDS backup
backup_dt <- combined_dt[, .(dttm_start, hour, value, day, day2)]
saveRDS(backup_dt, BACKUP_RDS)
log_info("Backup RDS saved with {nrow(backup_dt)} rows")

# Summary statistics
log_info("=" , rep("=", 58))
log_info("Processing Summary")
log_info("=" , rep("=", 58))
log_info("Total rows: {nrow(combined_dt)}")
log_info("Date range: {min(combined_dt$dttm_start)} to {max(combined_dt$dttm_start)}")
log_info("Total days: {length(unique(as.Date(combined_dt$dttm_start)))}")
log_info("Total consumption: {round(sum(combined_dt$value, na.rm = TRUE), 2)} kWh")
log_info("Average hourly consumption: {round(mean(combined_dt$value, na.rm = TRUE), 2)} kWh")
log_info("=" , rep("=", 58))
log_info("Processing complete!")
log_info("=" , rep("=", 58))

# Exit successfully
quit(status = 0)
