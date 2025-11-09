#!/usr/bin/env Rscript
# Linting helper script
suppressPackageStartupMessages({
  library(lintr)
})

# Exclude the renv directory
results <- lint_dir(path = '.', exclusions = c('renv'))
print(results)

# Fail (non-zero) if there are errors of type 'error'
errors <- vapply(results, function(x) inherits(x, 'lint') && x$type == 'error', logical(1))
if (any(errors)) {
  quit(status = 1)
}
