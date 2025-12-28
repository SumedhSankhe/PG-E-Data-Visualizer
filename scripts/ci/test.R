#!/usr/bin/env Rscript
# Unified test runner

run_tests <- function() {
  if (!requireNamespace("testthat", quietly = TRUE)) {
    message("testthat not installed. Install with: install.packages('testthat') or via renv.")
    quit(status = 0)
  }
  if (!requireNamespace("shiny", quietly = TRUE)) {
    message("shiny not installed; tests skipped.")
    quit(status = 0)
  }

  message("Running unit/module tests...")
  testthat::test_dir("tests/testthat")

  if (requireNamespace("shinytest2", quietly = TRUE)) {
    message("(Optional) Add shinytest2 snapshots under tests/testthat/__snapshots__")
  } else {
    message("shinytest2 not installed; snapshot tests skipped.")
  }
}

run_tests()
