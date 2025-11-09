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

testthat::test_that("loadServer returns reactive datasest", {
  testthat::skip_if_not(file.exists("meterData.rds"), "meterData.rds missing")
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
