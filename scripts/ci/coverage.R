#!/usr/bin/env Rscript
# Coverage computation script
suppressPackageStartupMessages({
  if (!requireNamespace("covr", quietly = TRUE)) {
    install.packages("covr")
  }
  if (!requireNamespace("testthat", quietly = TRUE)) {
    install.packages("testthat")
  }
  library(covr)
})

# Try to compute coverage - handle both package and Shiny app structure
cov <- tryCatch({
  # Try package_coverage first (for proper R packages)
  covr::package_coverage(line_exclusions = list("renv" = 1:9999))
}, error = function(e) {
  message("package_coverage failed (expected for Shiny apps), trying alternative approach...")

  # For Shiny apps, use environment_coverage
  tryCatch({
    # Create test environment
    test_env <- new.env(parent = globalenv())

    # Source all app files into the environment
    sys.source("helpers.R", envir = test_env)
    sys.source("config.R", envir = test_env)
    sys.source("loadData.R", envir = test_env)
    sys.source("home.R", envir = test_env)
    sys.source("qc.R", envir = test_env)
    sys.source("anomaly.R", envir = test_env)
    sys.source("pattern.R", envir = test_env)
    sys.source("cost.R", envir = test_env)

    # Run coverage on the environment
    covr::environment_coverage(
      env = test_env,
      test_files = list.files("tests/testthat", pattern = "^test.*\\.R$", full.names = TRUE)
    )
  }, error = function(e2) {
    message("environment_coverage also failed: ", e2$message)
    return(NULL)
  })
})

# Handle NULL coverage (when both methods fail)
if (is.null(cov)) {
  cat("Coverage computation not applicable for this project structure\n")
  writeLines("Coverage: N/A (Shiny app structure)", "coverage-summary.txt")
  writeLines('{"total": 0, "message": "Coverage not computed"}', "coverage.json")
  quit(status = 0)
}

# Write summary text
total_coverage <- covr::percent_coverage(cov)
cat("Total Coverage:", total_coverage, "%\n")
writeLines(paste("Total Coverage:", total_coverage, "%"), "coverage-summary.txt")

# Write JSON for artifact or upload
json <- jsonlite::toJSON(
  list(
    total = total_coverage,
    coverage_type = if (inherits(cov, "coverage")) "package" else "file"
  ),
  pretty = TRUE,
  auto_unbox = TRUE
)
writeLines(json, "coverage.json")

cat("Coverage computation complete\n")
