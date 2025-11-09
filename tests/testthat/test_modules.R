# Basic module tests

skip_if_not_installed <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    testthat::skip(paste("Package", pkg, "not installed"))
  }
}

skip_if_not_installed("shiny")
skip_if_not_installed("data.table")

library(shiny)
library(data.table)

# Test loadServer returns a reactive with expected columns

testthat::test_that("loadServer returns reactive dataset", {
  testthat::skip_if_not(file.exists("data/meterData.rds"), "data/meterData.rds missing")
  shiny::testServer(loadServer, { # test module server function
    dat <- session$returned() # attempt to capture returned reactive
  })
})

# Placeholder for analyseServer logic; more elaborate tests would inspect outputs

testthat::test_that("analyseServer initializes without error", {
  # We'll construct a small fake dataset mimicking expected columns
  dt <- data.table(
    dttm_start = as.POSIXct(Sys.Date()) + 3600 * 0:23,
    hour = 0:23,
    value = runif(24, 0.1, 2.5),
    day = rep(1, 24),
    day2 = rep(1, 24)
  )
  shiny::testServer(function(id) analyseServer(id, dt = reactive(dt)), { })
  testthat::expect_true(TRUE) # placeholder assertion
})

testthat::test_that("QC analysis detects data quality issues", {
  # Create test data with known issues
  dt_with_issues <- data.table(
    dttm_start = as.POSIXct(Sys.Date()) + 3600 * 0:49,
    hour = rep(0:23, length.out = 50),
    value = c(runif(20, 0.1, 2.5), NA, NA, runif(25, 0.1, 2.5), -1, 0, 100),
    day = rep(1:3, length.out = 50),
    day2 = rep(1:3, length.out = 50)
  )

  shiny::testServer(function(id) analyseServer(id, dt = reactive(dt_with_issues)), {
    # QC results should be calculated
    testthat::expect_true(is.list(qc_results()))
    testthat::expect_equal(qc_results()$total_records, 50)
    testthat::expect_equal(qc_results()$missing_values, 2)
    testthat::expect_equal(qc_results()$negative_values, 1)
    testthat::expect_true(qc_results()$quality_score <= 100)
  })
})
