#!/usr/bin/env Rscript
# Styling helper script
suppressPackageStartupMessages({
  library(styler)
})

style_dir(path = '.', filetype = c('R'), exclude_dirs = c('renv'))
