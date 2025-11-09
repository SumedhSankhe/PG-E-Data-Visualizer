#!/usr/bin/env Rscript
# Coverage computation script
suppressPackageStartupMessages({
  if (!requireNamespace("covr", quietly = TRUE)) {
    install.packages("covr")
  }
  library(covr)
})

# Exclude renv for speed and relevance
cov <- covr::package_coverage(exclusions = c("renv"))
# Write summary text
cat("Total Coverage:", covr::percent_coverage(cov), "\n")
writeLines(paste("Total Coverage:", covr::percent_coverage(cov)), "coverage-summary.txt")
# Write JSON for artifact or upload
json <- jsonlite::toJSON(list(total = covr::percent_coverage(cov), files = covr::shine(cov)$files), pretty = TRUE, auto_unbox = TRUE)
writeLines(json, "coverage.json")
