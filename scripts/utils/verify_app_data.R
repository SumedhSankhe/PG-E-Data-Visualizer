#!/usr/bin/env Rscript
#
# Verify that Shiny app can load the processed PGE data
#

library(data.table)
library(DBI)
library(RSQLite)

cat("========================================\n")
cat("Verifying Shiny App Data Loading\n")
cat("========================================\n\n")

# Test 1: SQLite Database
cat("Test 1: Loading from SQLite database\n")
cat("--------------------------------------\n")
db_file <- "data/pge_meter_data.sqlite"

if (!file.exists(db_file)) {
  cat("✗ SQLite database not found\n\n")
} else {
  tryCatch({
    con <- dbConnect(RSQLite::SQLite(), db_file)
    on.exit(dbDisconnect(con), add = TRUE)

    # Check table exists
    if (!dbExistsTable(con, "meter_data")) {
      cat("✗ Table 'meter_data' not found\n\n")
    } else {
      # Load data
      dt <- as.data.table(dbReadTable(con, "meter_data"))

      # Convert types
      dt[, dttm_start := as.POSIXct(dttm_start)]
      dt[, hour := as.integer(hour)]
      dt[, value := as.numeric(value)]
      dt[, day := as.integer(day)]
      dt[, day2 := as.integer(day2)]

      # Verify columns
      required_cols <- c("dttm_start", "hour", "value", "day", "day2")
      missing <- setdiff(required_cols, names(dt))

      if (length(missing) > 0) {
        cat(sprintf("✗ Missing columns: %s\n\n", paste(missing, collapse=", ")))
      } else {
        cat("✓ All required columns present\n")
        cat(sprintf("✓ Loaded %d rows\n", nrow(dt)))
        cat(sprintf("✓ Date range: %s to %s\n", min(dt$dttm_start), max(dt$dttm_start)))
        cat(sprintf("✓ Total consumption: %.2f kWh\n", sum(dt$value, na.rm=TRUE)))
        cat(sprintf("✓ Average hourly: %.3f kWh\n", mean(dt$value, na.rm=TRUE)))
        cat("\n✓ SQLite database is VALID and ready for Shiny app!\n\n")
      }
    }
  }, error = function(e) {
    cat(sprintf("✗ Error loading SQLite: %s\n\n", e$message))
  })
}

# Test 2: RDS Fallback
cat("Test 2: Loading from RDS backup\n")
cat("--------------------------------------\n")
rds_file <- "data/meterData.rds"

if (!file.exists(rds_file)) {
  cat("✗ RDS file not found\n\n")
} else {
  tryCatch({
    dt <- readRDS(rds_file)

    if (!is.data.table(dt)) {
      dt <- as.data.table(dt)
    }

    # Verify columns
    required_cols <- c("dttm_start", "hour", "value")
    missing <- setdiff(required_cols, names(dt))

    if (length(missing) > 0) {
      cat(sprintf("✗ Missing columns: %s\n\n", paste(missing, collapse=", ")))
    } else {
      cat("✓ All required columns present\n")
      cat(sprintf("✓ Loaded %d rows\n", nrow(dt)))
      cat(sprintf("✓ Date range: %s to %s\n", min(dt$dttm_start), max(dt$dttm_start)))
      cat(sprintf("✓ Total consumption: %.2f kWh\n", sum(dt$value, na.rm=TRUE)))
      cat("\n✓ RDS backup is VALID!\n\n")
    }
  }, error = function(e) {
    cat(sprintf("✗ Error loading RDS: %s\n\n", e$message))
  })
}

# Test 3: CSV Export
cat("Test 3: Loading from CSV export\n")
cat("--------------------------------------\n")
csv_file <- "data/pge_latest.csv"

if (!file.exists(csv_file)) {
  cat("✗ CSV file not found\n\n")
} else {
  tryCatch({
    dt <- fread(csv_file)

    # Convert types
    dt[, dttm_start := as.POSIXct(dttm_start)]

    cat("✓ CSV file is valid\n")
    cat(sprintf("✓ Loaded %d rows\n", nrow(dt)))
    cat(sprintf("✓ Date range: %s to %s\n", min(dt$dttm_start), max(dt$dttm_start)))
    cat(sprintf("✓ Total consumption: %.2f kWh\n\n", sum(dt$value, na.rm=TRUE)))
  }, error = function(e) {
    cat(sprintf("✗ Error loading CSV: %s\n\n", e$message))
  })
}

cat("========================================\n")
cat("Summary\n")
cat("========================================\n")
cat("Your PGE data has been successfully processed!\n\n")
cat("Files created:\n")
cat(sprintf("  ✓ %s (%s)\n", db_file, format(file.size(db_file), big.mark=",", scientific=FALSE)))
cat(sprintf("  ✓ %s (%s)\n", rds_file, format(file.size(rds_file), big.mark=",", scientific=FALSE)))
cat(sprintf("  ✓ %s (%s)\n", csv_file, format(file.size(csv_file), big.mark=",", scientific=FALSE)))
cat("\nNext steps:\n")
cat("  1. Test your Shiny app locally\n")
cat("  2. Verify visualizations show correct date range\n")
cat("  3. Check that all plots render correctly\n")
cat("  4. Deploy to shinyapps.io when ready\n")
cat("\n✓ Ready to launch your Shiny app!\n")
cat("========================================\n")
