# Contributing to PG&E Data Visualizer

We welcome contributions! This guide covers the development setup, coding standards, and contribution workflow.

---

## Table of Contents

- [Development Setup](#development-setup)
- [Architecture](#architecture)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Contribution Workflow](#contribution-workflow)
- [Troubleshooting](#troubleshooting)

---

## Development Setup

### Prerequisites

- **R** >= 4.0.0
- **RStudio** (recommended)
- Git

### Installation

```bash
git clone https://github.com/SumedhSankhe/PG-E-Data-Visualizer.git
cd PG-E-Data-Visualizer
```

```r
renv::restore()        # Install dependencies
shiny::runApp('.')     # Launch the app
```

Logs are written to `logs/app-YYYY-MM-DD.log`.

---

## Architecture

### Project Structure

```
PG-E-Data-Visualizer/
├── ui.R                    # Main Shiny UI
├── server.R                # Main Shiny server
├── global.R                # Global variables, logging
├── config.R                # Configuration constants
├── helpers.R               # Utility functions
├── home.R                  # Home module
├── loadData.R              # Data loading module
├── qc.R                    # Quality Control module
├── anomaly.R               # Anomaly Detection module
├── pattern.R               # Pattern Recognition module
├── cost.R                  # Cost Optimization module
├── data/                   # Sample data
├── tests/                  # Unit tests
├── scripts/                # Dev scripts (lint, test, coverage)
└── www/                    # Custom CSS/JS
```

### Module Architecture

The application uses the **Shiny Module pattern**. Each module is self-contained:

1. **Home** (`home.R`) - Landing page
2. **Load Data** (`loadData.R`) - File upload, validation, returns reactive dataset
3. **Quality Control** (`qc.R`) - IQR outlier detection, quality metrics
4. **Anomaly Detection** (`anomaly.R`) - Four algorithms with configurable sensitivity
5. **Pattern Recognition** (`pattern.R`) - Daily/weekly patterns, k-means clustering
6. **Cost Optimization** (`cost.R`) - Rate plan comparison, savings recommendations

### Data Flow

```
User Upload → loadDataServer → Raw Reactive Data
                                      ↓
                            Global Date Filter
                                      ↓
                           Filtered Reactive Data
                      ↙        ↓        ↓        ↘
                    qc     anomaly  pattern    cost
                  Module    Module   Module   Module
```

---

## Coding Standards

### Style Guide

- **Naming**: `snake_case` for variables/functions, `UPPER_SNAKE_CASE` for constants
- **Indentation**: 2 spaces (no tabs)
- **Line Length**: ≤ 120 characters
- **Spacing**: Spaces around operators (`<-`, `=`, `+`)

### Best Practices

```r
# Good
qcServer <- function(id, dt) {
  moduleServer(id, function(input, output, session) {
    req(dt())                            # Guard against NULL
    validate(need(                       # User-friendly error
      nrow(dt()) > 0,
      "No data available for quality control"
    ))
    logger::log_info("Quality control analysis started")
  })
}

# Bad
qcServer<-function(id,dt){
  moduleServer(id,function(input,output,session){plot(dt()$value)})
}
```

### Code Quality

```r
source('scripts/style.R')   # Apply tidyverse style
source('scripts/lint.R')    # Check for issues
```

### Linting Configuration (`.lintr`)

```r
linters: linters_with_defaults(
  line_length_linter(120),
  object_length_linter(40),
  cyclocomp_linter(15),
  commented_code_linter = NULL
)
exclude: "renv"
```

---

## Testing

### Running Tests

```r
source('scripts/test.R')     # Run all tests
source('scripts/coverage.R') # Check coverage

# Run specific test file
testthat::test_file('tests/testthat/test_modules.R')
```

### Test Structure

```r
library(testthat)
library(shiny)

test_that("loadServer returns reactive data", {
  testServer(loadServer, {
    expect_true(is.reactive(data))
  })
})

test_that("module handles empty data gracefully", {
  testServer(analyseServer, {
    session$setInputs(data = data.frame())
    expect_true(is.null(output$plot))
  })
})
```

---

## Contribution Workflow

### Git Branches

- **Main**: `master` (protected)
- **Features**: `feature/feature-name`
- **Bugfixes**: `bugfix/issue-description`
- **Hotfixes**: `hotfix/critical-fix`

### Steps

1. **Fork and clone** the repository

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Implement changes**
   - Follow Shiny module pattern
   - Use `req()` and `validate(need())` for error handling
   - Add logging with `logger::log_info()`

4. **Run quality checks**
   ```r
   source('scripts/style.R')
   source('scripts/lint.R')
   source('scripts/test.R')
   ```

5. **Commit and push**
   ```bash
   git add .
   git commit -m "Add feature description"
   git push origin feature/your-feature-name
   ```

6. **Open a pull request**

### Code Review Requirements

- Code follows style guidelines
- Tests pass and coverage is maintained
- No security vulnerabilities
- Clear commit messages

See `docs/CODE_REVIEW_CHECKLIST.md` for the complete checklist.

---

## Troubleshooting

### App Won't Start

```r
# Missing dependencies
renv::restore()

# Port already in use
shiny::runApp('.', port = 8888)
```

### Data Upload Fails

- Ensure required columns: `dttm_start`, `hour`, `value`, `day`, `day2`
- Use date format: `YYYY-MM-DD HH:MM:SS`

### Logs Not Appearing

```r
dir.create("logs", showWarnings = FALSE)
```

### Performance Tips

- Filter to specific date ranges for large datasets
- Use `bindCache()` for expensive computations

---

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/discussions)
