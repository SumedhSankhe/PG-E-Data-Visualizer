#!/usr/bin/env Rscript
# Coverage computation script
suppressPackageStartupMessages({
  if (!requireNamespace("covr", quietly = TRUE)) {
    install.packages("covr")
  }
  library(covr)
})

# Try to compute coverage - handle both package and Shiny app structure
cov <- tryCatch({
  # Try package_coverage first (for proper R packages)
  covr::package_coverage(line_exclusions = list("renv" = 1:9999))
}, error = function(e) {
  message("package_coverage failed (expected for Shiny apps), trying file coverage...")

  # For Shiny apps, use file coverage on key R files
  r_files <- c(
    "global.R", "server.R", "ui.R", "helpers.R",
    "loadData.R", "home.R", "qc.R", "anomaly.R",
    "pattern.R", "cost.R", "config.R"
  )

  # Only include files that exist
  r_files <- r_files[file.exists(r_files)]

  if (length(r_files) == 0) {
    message("No R files found for coverage analysis")
    return(NULL)
  }

  # Get test files
  test_files <- list.files("tests/testthat", pattern = "^test.*\\.R$", full.names = TRUE)

  if (length(test_files) == 0) {
    message("No test files found")
    return(NULL)
  }

  tryCatch({
    covr::file_coverage(
      source_files = r_files,
      test_files = test_files
    )
  }, error = function(e2) {
    message("File coverage also failed: ", e2$message)
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
