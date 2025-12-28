# Comprehensive module tests

skip_if_not_installed <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    testthat::skip(paste("Package", pkg, "not installed"))
  }
}

skip_if_not_installed("shiny")
skip_if_not_installed("data.table")

library(shiny)
library(data.table)

# Helper function to create test data
create_test_data <- function(n_rows = 100, include_issues = FALSE) {
  dt <- data.table(
    dttm_start = as.POSIXct(Sys.Date()) + 3600 * 0:(n_rows - 1),
    hour = rep(0:23, length.out = n_rows),
    value = runif(n_rows, 0.1, 2.5),
    day = rep(1:ceiling(n_rows/24), each = 24, length.out = n_rows),
    day2 = rep(1:ceiling(n_rows/24), each = 24, length.out = n_rows)
  )

  if (include_issues) {
    # Add some data quality issues
    dt$value[c(10, 11)] <- NA  # Missing values
    dt$value[15] <- -1         # Negative value
    dt$value[90:95] <- runif(6, 10, 20)  # Outliers
  }

  return(dt)
}

# Test loadServer ---------------------------------------------------------
testthat::test_that("loadServer returns reactive dataset", {
  testthat::skip_if_not(file.exists("data/meterData.rds"), "data/meterData.rds missing")
  shiny::testServer(loadServer, {
    dat <- session$returned()
    testthat::expect_true(is.reactive(dat))
    testthat::expect_true(is.data.frame(dat()))
  })
})

# Test helper functions ---------------------------------------------------
testthat::test_that("safe_divide prevents division by zero", {
  source("helpers.R")
  testthat::expect_equal(safe_divide(10, 2), 5)
  testthat::expect_equal(safe_divide(10, 0), 0)
  testthat::expect_equal(safe_divide(10, 0, default = NA), NA)
  testthat::expect_equal(safe_divide(10, NULL), 0)
})

testthat::test_that("safe_percentage calculates correctly", {
  source("helpers.R")
  testthat::expect_equal(safe_percentage(25, 100), 25)
  testthat::expect_equal(safe_percentage(10, 0), 0)
  testthat::expect_equal(safe_percentage(5, 20), 25)
})

testthat::test_that("validate_upload_file rejects invalid files", {
  source("config.R")
  source("helpers.R")

  # Test invalid extension
  invalid_file <- list(
    name = "test.txt",
    datapath = tempfile()
  )
  file.create(invalid_file$datapath)
  result <- validate_upload_file(invalid_file)
  testthat::expect_false(result$valid)
  testthat::expect_match(result$message, "Invalid file type")
  unlink(invalid_file$datapath)

  # Test valid extension
  valid_file <- list(
    name = "test.csv",
    datapath = tempfile(fileext = ".csv")
  )
  writeLines("col1,col2\n1,2", valid_file$datapath)
  result <- validate_upload_file(valid_file)
  testthat::expect_true(result$valid)
  unlink(valid_file$datapath)
})

testthat::test_that("validate_required_columns checks columns", {
  source("config.R")
  source("helpers.R")

  # Valid data
  valid_data <- data.table(
    dttm_start = as.POSIXct(Sys.Date()),
    hour = 1,
    value = 1.5
  )
  result <- validate_required_columns(valid_data)
  testthat::expect_true(result$valid)

  # Missing columns
  invalid_data <- data.table(
    dttm_start = as.POSIXct(Sys.Date()),
    hour = 1
  )
  result <- validate_required_columns(invalid_data)
  testthat::expect_false(result$valid)
  testthat::expect_match(result$message, "value")
})

# Test QC calculations ----------------------------------------------------
testthat::test_that("calculate_qc_metrics works correctly", {
  source("config.R")
  source("helpers.R")

  dt <- create_test_data(100, include_issues = TRUE)
  qc <- calculate_qc_metrics(dt)

  testthat::expect_equal(qc$total_records, 100)
  testthat::expect_equal(qc$missing_values, 2)
  testthat::expect_equal(qc$negative_values, 1)
  testthat::expect_true(qc$quality_score >= 0 && qc$quality_score <= 100)
  testthat::expect_true(!is.na(qc$mean_value))
  testthat::expect_true(!is.na(qc$median_value))
})

# Test QC Server ----------------------------------------------------------
testthat::test_that("qcServer calculates quality metrics", {
  dt_test <- create_test_data(100, include_issues = TRUE)

  shiny::testServer(qcServer, args = list(dt = reactive(dt_test)), {
    qc <- qc_results()

    testthat::expect_true(is.list(qc))
    testthat::expect_equal(qc$total_records, 100)
    testthat::expect_equal(qc$missing_values, 2)
    testthat::expect_equal(qc$negative_values, 1)
    testthat::expect_true(qc$quality_score <= 100)
    testthat::expect_true(qc$outliers >= 0)
  })
})

# Test anomaly detection --------------------------------------------------
testthat::test_that("detect_anomalies_iqr identifies outliers", {
  source("config.R")
  source("helpers.R")

  dt <- create_test_data(100)
  dt$value[c(50, 51, 52)] <- c(100, 105, 110)  # Add clear outliers

  result <- detect_anomalies_iqr(dt, sensitivity = 5)

  testthat::expect_true("is_anomaly" %in% names(result))
  testthat::expect_true("anomaly_score" %in% names(result))
  testthat::expect_true(sum(result$is_anomaly) > 0)
})

# Test anomalyServer ------------------------------------------------------
testthat::test_that("anomalyServer detects anomalies", {
  dt_test <- create_test_data(100)
  dt_test$value[50:55] <- c(100, 105, 110, 95, 102, 108)  # Add outliers

  shiny::testServer(anomalyServer, args = list(dt = reactive(dt_test)), {
    session$setInputs(detection_method = "iqr", sensitivity = 5)

    results <- anomaly_results()

    testthat::expect_true(is.list(results))
    testthat::expect_true(results$anomaly_count >= 0)
    testthat::expect_true(results$anomaly_pct >= 0 && results$anomaly_pct <= 100)
    testthat::expect_equal(results$method, "iqr")
  })
})

# Test rate plan comparison -----------------------------------------------
testthat::test_that("compare_rate_plans returns valid comparisons", {
  source("config.R")
  source("helpers.R")

  dt <- create_test_data(100)
  dt[, start_date := as.Date(dttm_start)]

  comparisons <- compare_rate_plans(dt)

  testthat::expect_true(is.data.table(comparisons))
  testthat::expect_true(nrow(comparisons) >= 3)
  testthat::expect_true("Plan" %in% names(comparisons))
  testthat::expect_true("Total_Cost" %in% names(comparisons))
  testthat::expect_true(all(comparisons$Total_Cost >= 0))
})

# Test input validation ---------------------------------------------------
testthat::test_that("validate_peak_hours catches invalid inputs", {
  source("config.R")
  source("helpers.R")

  # Valid hours
  result <- validate_peak_hours(16, 21)
  testthat::expect_true(result$valid)

  # Invalid: start >= end
  result <- validate_peak_hours(21, 16)
  testthat::expect_false(result$valid)

  # Invalid: out of range
  result <- validate_peak_hours(25, 30)
  testthat::expect_false(result$valid)
})

testthat::test_that("validate_rate catches invalid rates", {
  source("config.R")
  source("helpers.R")

  # Valid rate
  result <- validate_rate(0.45, "Test rate")
  testthat::expect_true(result$valid)

  # Invalid: negative
  result <- validate_rate(-0.5, "Test rate")
  testthat::expect_false(result$valid)

  # Invalid: too high
  result <- validate_rate(5.0, "Test rate")
  testthat::expect_false(result$valid)
})
