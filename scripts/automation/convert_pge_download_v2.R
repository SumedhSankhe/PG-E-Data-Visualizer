#!/usr/bin/env Rscript
#
# Convert PGE Downloaded CSV to Shiny App Format - Simple Version
# Handles PGE's Green Button Download format with 15-minute intervals
#

library(data.table)
library(DBI)
library(RSQLite)

cat("========================================\n")
cat("Converting PGE Download Data\n")
cat("========================================\n\n")

# Find the PGE CSV file
pge_files <- list.files("data", pattern = "pge_electric_usage.*\\.csv$", full.names = TRUE)

if (length(pge_files) == 0) {
  stop("No PGE CSV file found in data/ directory")
}

pge_file <- pge_files[1]
cat(sprintf("Processing: %s\n\n", basename(pge_file)))

# Read CSV, skipping header rows
raw_data <- fread(pge_file, skip = 5, fill = TRUE)
cat(sprintf("Loaded %d rows\n", nrow(raw_data)))

# Rename columns
setnames(raw_data,
         old = c("DATE", "START TIME", "USAGE (kWh)"),
         new = c("date", "start_time", "usage_kwh"),
         skip_absent = TRUE)

# Create datetime
raw_data[, dttm_start := as.POSIXct(paste(date, start_time), format = "%Y-%m-%d %H:%M")]
raw_data <- raw_data[!is.na(dttm_start)]

cat(sprintf("Date range: %s to %s\n\n", min(raw_data$dttm_start), max(raw_data$dttm_start)))

# Aggregate to hourly
hourly_data <- raw_data[, .(
  value = sum(usage_kwh, na.rm = TRUE)
), by = .(
  dttm_start = as.POSIXct(format(dttm_start, "%Y-%m-%d %H:00:00"))
)]

hourly_data[, hour := as.integer(format(dttm_start, "%H"))]
hourly_data[, day := as.integer(as.Date(dttm_start) - min(as.Date(dttm_start)) + 1)]
hourly_data[, day2 := day]
setorder(hourly_data, dttm_start)

cat(sprintf("Aggregated to %d hours\n", nrow(hourly_data)))
cat(sprintf("Total consumption: %.2f kWh\n\n", sum(hourly_data$value)))

# Save CSV
csv_file <- "data/pge_latest.csv"
fwrite(hourly_data, csv_file)
cat(sprintf("✓ Saved CSV: %s\n\n", csv_file))

# Save RDS first (before database complications)
rds_file <- "data/meterData.rds"
backup_dt <- hourly_data[, .(dttm_start, hour, value, day, day2)]
saveRDS(backup_dt, rds_file)
cat(sprintf("✓ Saved RDS: %s\n\n", rds_file))

# Now try SQLite database
cat("Creating SQLite database...\n")
db_file <- "data/pge_meter_data.sqlite"

tryCatch({
  # Remove old database if exists
  if (file.exists(db_file)) {
    unlink(db_file)
    cat("  Removed old database\n")
  }

  # Create new connection
  con <- dbConnect(RSQLite::SQLite(), db_file)
  cat("  ✓ Connected to database\n")

  # Create table
  dbExecute(con, "
    CREATE TABLE meter_data (
      dttm_start TEXT NOT NULL,
      hour INTEGER NOT NULL,
      value REAL NOT NULL,
      day INTEGER,
      day2 INTEGER,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (dttm_start, hour)
    )
  ")
  cat("  ✓ Created table\n")

  # Create indexes
  dbExecute(con, "CREATE INDEX idx_dttm_start ON meter_data(dttm_start)")
  dbExecute(con, "CREATE INDEX idx_hour ON meter_data(hour)")
  cat("  ✓ Created indexes\n")

  # Insert data
  insert_data <- copy(hourly_data)
  insert_data[, dttm_start := as.character(dttm_start)]
  dbWriteTable(con, "meter_data", insert_data, append = TRUE, overwrite = FALSE)
  cat("  ✓ Inserted data\n")

  # Verify
  count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM meter_data")$n
  cat(sprintf("  ✓ Database contains %d rows\n", count))

  # Disconnect
  dbDisconnect(con)
  cat("  ✓ Closed connection\n")

  cat(sprintf("\n✓ Saved SQLite: %s\n", db_file))

}, error = function(e) {
  cat(sprintf("\n✗ Database error: %s\n", e$message))
  cat("  RDS file was saved successfully, Shiny app will use that as fallback\n")
})

cat("\n========================================\n")
cat("Conversion Complete!\n")
cat("========================================\n")
cat(sprintf("Total hours: %d\n", nrow(hourly_data)))
cat(sprintf("Date range: %s to %s\n", min(hourly_data$dttm_start), max(hourly_data$dttm_start)))
cat(sprintf("Total consumption: %.2f kWh\n", sum(hourly_data$value)))
cat("\nFiles created:\n")
cat(sprintf("  - %s (RDS - always works)\n", rds_file))
if (file.exists(db_file)) {
  cat(sprintf("  - %s (SQLite)\n", db_file))
}
cat(sprintf("  - %s (CSV)\n", csv_file))
cat("\n✓ Ready to run Shiny app!\n")
cat("========================================\n")
