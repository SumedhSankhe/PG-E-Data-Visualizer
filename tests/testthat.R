# testthat bootstrap
if (!requireNamespace("testthat", quietly = TRUE)) {
  message("testthat not installed; skipping tests.")
  quit(save = "no")
}

library(testthat)
# shinytest2 optional snapshot tests
if (requireNamespace("shinytest2", quietly = TRUE)) {
  message("shinytest2 available: snapshot tests can run.")
}

# Run all tests
testthat::test_dir("tests/testthat")
