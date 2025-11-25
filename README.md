# PG&E Data Visualizer

[![CI Status](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions)
[![Coverage](https://codecov.io/gh/SumedhSankhe/PG-E-Data-Visualizer/branch/master/graph/badge.svg)](https://codecov.io/gh/SumedhSankhe/PG-E-Data-Visualizer)
[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> A production-ready R Shiny web application that transforms smart meter data into actionable insights through statistical quality control, machine learning-based anomaly detection, pattern recognition, and cost optimization algorithms.

**[Live Demo](https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/)** | [Documentation](#documentation) | [Quick Start](#quick-start)

---

## At a Glance

**What it does:** Analyzes Pacific Gas & Electric (PG&E) smart meter energy consumption data through four specialized analysis engines: data quality validation, statistical anomaly detection (IQR, Z-Score, STL decomposition, Moving Average), usage pattern recognition with k-means clustering, and rate plan cost optimization.

**Tech Stack:** R, Shiny, shinydashboard, ggplot2, plotly, data.table, logger, DT, openxlsx

**Key Features:**
- Real-time data quality control with outlier detection
- Four anomaly detection algorithms with configurable sensitivity
- Load curve clustering for pattern identification
- Multi-plan cost comparison (TOU, Tiered, EV rates)
- Comprehensive Excel export with 5-sheet analysis reports

---

## Table of Contents

- [Overview](#overview)
- [What I Built](#what-i-built)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Data Format](#data-format)
- [Architecture](#architecture)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

The **PG&E Data Visualizer** is a web-based application built with R Shiny that transforms raw smart meter data into actionable insights through four specialized analysis modules. The application provides a complete analytical pipeline from data quality validation through anomaly detection, pattern recognition, and cost optimization.

**[Try the live application](https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/)**

### Analysis Capabilities

- **Quality Control**: Statistical validation with IQR-based outlier detection, missing value analysis, and automated quality scoring
- **Anomaly Detection**: Four configurable algorithms (IQR, Z-Score, STL decomposition, Moving Average) with adjustable sensitivity
- **Pattern Recognition**: Daily, weekly, and seasonal pattern analysis with k-means load curve clustering
- **Cost Optimization**: Rate plan comparison across Time of Use, Tiered, and EV plans with peak/off-peak cost breakdown

### Use Cases

- **Energy Analysts**: Identify consumption anomalies and compare rate plans to recommend cost-saving strategies
- **Homeowners**: Understand peak usage hours, detect unusual consumption, and evaluate switching rate plans
- **Utilities**: Validate meter data quality and support customer decision-making with data-driven insights
- **Researchers**: Study energy usage patterns and behavioral trends with statistical rigor

---

## What I Built

This project demonstrates full-stack data science application development, from statistical algorithms through production deployment. Here are the key technical achievements:

### Technical Complexity

**Multi-Algorithm Anomaly Detection**: Implemented four distinct anomaly detection methods (IQR, Z-Score, STL seasonal decomposition, Moving Average), each with configurable sensitivity parameters. The STL implementation handles seasonal patterns in time series data, while the Moving Average approach detects trend deviations.

**Pattern Recognition Engine**: Built a clustering system that groups similar consumption profiles using k-means, enabling automatic identification of usage patterns (weekday vs weekend, seasonal variations, behavior changes). The system generates load curves and compares them across multiple dimensions.

**Real-Time Reactivity**: Architected a modular Shiny application where changes to the global date filter instantly propagate through all four analysis modules. Used data.table for high-performance operations on large datasets and reactive programming patterns to maintain UI responsiveness.

**Comprehensive Export System**: Developed an automated report generator that produces formatted Excel workbooks with five analysis sheets (Overview, Quality Control, Anomalies, Pattern Analysis, Cost Analysis), complete with calculated metrics, conditional formatting, and summary statistics.

### Design Decisions

**Why Shiny Modules**: Chose the module pattern to isolate each analysis engine's logic and UI, making the codebase maintainable and testable. Each module (qc, anomaly, pattern, cost) operates independently but shares a common filtered dataset.

**Why data.table**: Selected data.table over dplyr for its superior performance with large time series datasets. The reference semantics and efficient grouping operations were critical for real-time filtering and aggregation.

**Why Multiple Anomaly Methods**: Different anomaly detection algorithms excel in different scenarios. IQR handles non-normal distributions, Z-Score works for normally distributed data, STL extracts seasonal components, and Moving Average detects trend changes. Giving users all four options maximizes the tool's utility.

### Challenges Solved

- **Performance**: Optimized reactive chains to prevent redundant calculations when the global date filter changes
- **State Management**: Coordinated state across six independent modules while maintaining data consistency
- **User Experience**: Designed collapsible help sections and real-time validation to make statistical analysis accessible to non-technical users
- **Production Deployment**: Configured for shinyapps.io with proper dependency management via renv and structured logging

---

## Features

### Core Functionality

- **Modular Architecture**: Six independent Shiny modules (`home`, `loadData`, `qc`, `anomaly`, `pattern`, `cost`)
- **Flexible Data Input**: Upload CSV/TSV files or use bundled sample data with automatic validation
- **Interactive Visualizations**:
  - Time series plots with anomaly highlighting and trend overlays
  - Box plots and histograms showing statistical distributions
  - Heatmaps for hourly consumption patterns
  - Daily cost trends and rate plan comparison charts
  - All built with ggplot2 and plotly for rich interactivity
- **Quality Control Module**:
  - Automated outlier detection using IQR method
  - Missing value analysis and time gap detection
  - Quality score calculation and flag generation
  - Distribution analysis with statistical summaries
- **Anomaly Detection Module**:
  - Four detection algorithms: IQR, Z-Score, STL, Moving Average
  - Configurable sensitivity (1-10 scale)
  - Severity classification (Critical, High, Medium, Low)
  - Time series visualization with anomaly highlighting
- **Pattern Recognition Module**:
  - Daily, weekly, and day-type pattern analysis
  - K-means load curve clustering (2-7 clusters)
  - Hourly consumption heatmaps
  - Pattern consistency scoring
- **Cost Optimization Module**:
  - Time of Use (TOU) rate plans with configurable peak hours
  - Tiered rate plans with usage-based pricing
  - Electric Vehicle (EV) rate plans
  - Custom flat rate option
  - Peak vs off-peak cost breakdown and savings recommendations
- **Global Date Filtering**: Single date range control that updates all analysis modules in real-time
- **Comprehensive Export**: One-click Excel download with all analyses in formatted sheets
- **Comprehensive Logging**: Daily rotating logs with structured logging via `logger` package
- **Responsive Design**: Clean, professional UI with shinydashboard and custom CSS

### Quality Assurance

- **Automated Testing**: Unit tests with `testthat`, CI/CD with GitHub Actions
- **Code Quality**: Automated linting and style checks with `.lintr` configuration
- **Dependency Management**: Reproducible environments with `renv`
- **Production Ready**: Deployed on shinyapps.io with monitoring and structured logging

---

## Quick Start

### Prerequisites

- **R** >= 4.0.0
- **RStudio** (recommended) or any R environment
- Git (for cloning the repository)

### Run the Application

```r
# Clone the repository
git clone https://github.com/SumedhSankhe/PG-E-Data-Visualizer.git
cd PG-E-Data-Visualizer

# Open R or RStudio in this directory, then:
renv::restore()        # Install dependencies
shiny::runApp('.')     # Launch the app

# The app will open in your browser at http://localhost:####
# Logs are written to logs/app-YYYY-MM-DD.log
```

---

## Installation

### Standard Installation

```r
# 1. Install renv if you don't have it
install.packages("renv")

# 2. Clone and navigate to the repository
git clone https://github.com/SumedhSankhe/PG-E-Data-Visualizer.git
cd PG-E-Data-Visualizer

# 3. Restore dependencies (this creates an isolated R library)
renv::restore()

# 4. Launch the app
shiny::runApp('.')
```

### Key Dependencies

The application uses the following major packages:

- **shiny** - Web application framework
- **shinydashboard** - Dashboard layout and styling
- **data.table** - High-performance data manipulation
- **ggplot2** - Grammar of graphics for plotting
- **plotly** - Interactive web-based visualizations
- **logger** - Structured logging
- **DT** - Interactive data tables
- **shinyjs** - JavaScript interface for dynamic UI
- **shinycssloaders** - Loading spinners

See `renv.lock` for complete dependency list with versions.

---

## Usage

### 1. Load Your Data

Navigate to the **Data** tab and:
- Upload a CSV or TSV file with your smart meter data, OR
- Use the pre-loaded sample dataset (`data/meterData.rds`)
- View the interactive data table to verify your upload

### 2. Set Global Date Range

Use the **Global Date Filter** in the sidebar to:
- Select the date range you want to analyze
- Changes apply to all analysis modules instantly
- Download button becomes available once dates are selected

### 3. Quality Control

Go to the **Quality Control** tab to:
- Review automated quality metrics (total records, missing values, outliers, quality score)
- Examine data completeness by hour
- Identify problematic time periods with highlighted issues
- Check value distribution and outlier flags

### 4. Anomaly Detection

Navigate to the **Anomaly Detection** tab and:
- Select a detection method (IQR, Z-Score, STL, or Moving Average)
- Adjust sensitivity (1 = strict, 10 = lenient)
- Review anomaly counts and severity distribution
- Examine the time series with anomalies highlighted
- Export detected anomalies for further investigation

### 5. Pattern Recognition

Go to the **Pattern Recognition** tab to:
- Choose pattern type (Daily, Weekly, Day Type, or Load Curve Clustering)
- For clustering, select number of clusters (2-7)
- View hourly consumption heatmaps
- Identify peak hours and usage consistency patterns
- Compare weekday vs weekend consumption

### 6. Cost Optimization

Navigate to the **Cost Optimization** tab and:
- Select rate plan (TOU, Tiered, EV, or Custom)
- Configure plan parameters (peak hours, rates, tier limits)
- Review total cost, daily average, and peak cost percentage
- Examine cost trends and hourly breakdowns
- Read recommendations for cost savings
- Compare different rate plans to find the best option

### 7. Export Complete Report

Click **Download All Reports** in the sidebar to:
- Generate a comprehensive Excel workbook
- Includes 5 sheets: Overview, Quality Control, Anomalies, Pattern Analysis, Cost Analysis
- All metrics and visualizations summarized in one file

### Example Workflow

```r
# 1. Start the app (or use the live demo)
shiny::runApp('.')

# 2. Load data
#    - Navigate to Data tab
#    - Upload your_meter_data.csv or use sample data

# 3. Set date range
#    - Use sidebar Global Date Filter
#    - Select: 2024-01-01 to 2024-01-31

# 4. Quality check
#    - Go to Quality Control tab
#    - Verify quality score > 90%

# 5. Find anomalies
#    - Go to Anomaly Detection tab
#    - Select "IQR" method, sensitivity = 5
#    - Review 15 detected anomalies

# 6. Identify patterns
#    - Go to Pattern Recognition tab
#    - Select "Load Curve Clustering", 3 clusters
#    - Observe weekday/weekend/holiday patterns

# 7. Optimize costs
#    - Go to Cost Optimization tab
#    - Compare TOU vs Tiered plans
#    - Identify 18% potential savings by shifting peak usage

# 8. Export report
#    - Click "Download All Reports" in sidebar
#    - Open Excel file to review all analyses
```

---

## Data Format

### Required Columns

Your uploaded file must include these columns:

| Column | Type | Description |
|--------|------|-------------|
| `dttm_start` | POSIXct/DateTime | Timestamp of meter reading (YYYY-MM-DD HH:MM:SS) |
| `hour` | Numeric | Hour of day (0-23) |
| `value` | Numeric | Energy consumption in kilowatt-hours (kWh) |
| `day` | Numeric | Day identifier for grouping |
| `day2` | Numeric | Secondary day identifier |

### Optional Columns

- `day_of_week` - Day of week (0-6 or Mon-Sun)
- `month` - Month (1-12)
- `year` - Year (YYYY)
- `season` - Season identifier

### Supported Formats

- CSV (Comma-Separated Values)
- TSV (Tab-Separated Values)

### Example Data

```csv
dttm_start,hour,value,day,day2
2024-01-01 00:00:00,0,0.523,1,1
2024-01-01 01:00:00,1,0.412,1,1
2024-01-01 02:00:00,2,0.389,1,1
...
```

### Sample Data

The repository includes sample data at `data/meterData.rds` which loads automatically if no file is uploaded.

---

## Architecture

### Project Structure

```
PG-E-Data-Visualizer/
├── ui.R                    # Main Shiny UI definition
├── server.R                # Main Shiny server logic
├── global.R                # Global variables, constants, logging
├── config.R                # Configuration and constants
├── helpers.R               # Utility functions
├── home.R                  # Home module (UI & server)
├── loadData.R              # Data loading module
├── qc.R                    # Quality Control module
├── anomaly.R               # Anomaly Detection module
├── pattern.R               # Pattern Recognition module
├── cost.R                  # Cost Optimization module
├── .gitignore              # Git ignore rules
├── .lintr                  # Linting configuration
├── DESCRIPTION             # Package metadata
├── README.md               # This file
├── renv.lock               # Dependency lock file
├── PG-E-Data-Visualizer.Rproj  # RStudio project
│
├── data/
│   └── meterData.rds      # Sample dataset
│
├── docs/
│   ├── AGENTS.md          # Development workflow documentation
│   └── CODE_REVIEW_CHECKLIST.md  # PR review guidelines
│
├── www/
│   ├── custom.css         # Custom CSS styling
│   └── custom.js          # Custom JavaScript
│
├── scripts/
│   ├── lint.R             # Linting script
│   ├── style.R            # Code styling script
│   ├── test.R             # Test runner
│   └── coverage.R         # Code coverage analysis
│
├── tests/
│   ├── testthat.R         # Test bootstrap
│   └── testthat/
│       └── test_modules.R # Module unit tests
│
├── logs/                  # Application runtime logs (gitignored)
│
├── .github/
│   └── workflows/
│       └── ci-tests.yml   # GitHub Actions CI pipeline
│
└── renv/                  # renv library directory
```

### Module Architecture

The application follows the **Shiny Module pattern** for modularity and maintainability. Each module is self-contained with its own UI and server logic:

1. **Home Module** (`home.R`)
   - Landing page with application overview
   - Quick start guide and feature descriptions
   - Static content, no reactive logic

2. **Load Data Module** (`loadData.R`)
   - File upload interface with drag-and-drop support
   - CSV/TSV parsing with data.table
   - Data validation and error handling
   - Interactive data table display with DT
   - Returns reactive dataset for downstream modules

3. **Quality Control Module** (`qc.R`)
   - Automated quality metrics (missing values, outliers, quality score)
   - IQR-based outlier detection
   - Time series with data quality issues highlighted
   - Completeness analysis by hour
   - Distribution plots with statistical summaries

4. **Anomaly Detection Module** (`anomaly.R`)
   - Four detection algorithms: IQR, Z-Score, STL decomposition, Moving Average
   - Configurable sensitivity parameter (1-10)
   - Severity classification (Critical/High/Medium/Low)
   - Time series visualization with anomaly highlighting
   - Anomaly distribution by hour and severity
   - Downloadable anomaly table

5. **Pattern Recognition Module** (`pattern.R`)
   - Daily pattern analysis (average hourly profile)
   - Weekly pattern comparison (Monday-Sunday)
   - Day type analysis (weekday vs weekend)
   - K-means load curve clustering (2-7 clusters)
   - Hourly consumption heatmaps
   - Pattern consistency scoring

6. **Cost Optimization Module** (`cost.R`)
   - Multi-plan support: Time of Use, Tiered, EV, Custom
   - Configurable peak hours and rate parameters
   - Cost calculations with peak/off-peak breakdown
   - Daily cost trends and hourly cost analysis
   - Rate plan comparison visualizations
   - Savings recommendations based on usage patterns

### Data Flow

```
User Upload → loadDataServer → Raw Reactive Data
                                      ↓
                            Global Date Filter (server.R)
                                      ↓
                           Filtered Reactive Data
                      ↙        ↓        ↓        ↘
                    qc     anomaly  pattern    cost
                  Module    Module   Module   Module
                    ↓         ↓        ↓        ↓
                   QC     Anomaly   Pattern   Cost
                Visuals   Visuals   Visuals  Visuals
                                      ↓
                          Excel Report Generator
                                      ↓
                        5-Sheet Workbook Download
```

### Key Design Patterns

- **Reactive Programming**: Global date filter propagates changes to all modules instantly
- **Module Isolation**: Each analysis module operates independently with clean interfaces
- **Lazy Evaluation**: Computations only trigger when data or inputs change
- **Defensive Programming**: Extensive use of `req()` and `validate(need())` for robust error handling
- **Structured Logging**: All operations logged with context via `logger` package

---

## Development

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Implement Changes**
   - Follow Shiny module pattern (`modNameUI`, `modNameServer`)
   - Use `req()` and `validate(need())` for error handling
   - Add logging with `logger::log_info()`, `logger::log_warn()`, etc.
   - Keep functions focused and readable

3. **Code Quality Checks**
   ```r
   source('scripts/style.R')  # Apply tidyverse style
   source('scripts/lint.R')   # Check for issues
   ```

4. **Run Tests**
   ```r
   source('scripts/test.R')    # Run unit tests
   source('scripts/coverage.R') # Check coverage
   ```

5. **Commit and Push**
   - Write clear commit messages
   - Push to your feature branch
   - Open a pull request with description of changes

### Coding Standards

#### Style Guide

- **Naming**: `snake_case` for variables/functions, `UPPER_SNAKE_CASE` for constants
- **Indentation**: 2 spaces (no tabs)
- **Line Length**: ≤ 120 characters
- **Spacing**: Spaces around operators (`<-`, `=`, `+`, etc.)

#### Best Practices

```r
# ✓ Good
qcServer <- function(id, dt) {
  moduleServer(id, function(input, output, session) {
    req(dt())                            # Guard against NULL
    validate(need(                       # User-friendly error
      nrow(dt()) > 0,
      "No data available for quality control"
    ))

    logger::log_info("Quality control analysis started")  # Logging

    # Reactive logic here
  })
}

# ✗ Bad
qcServer<-function(id,dt){  # No spaces, no validation, poor readability
  moduleServer(id,function(input,output,session){plot(dt()$value)})
}
```

### Linting Configuration

The project uses `lintr` with the following rules (`.lintr`):

```r
linters: linters_with_defaults(
  line_length_linter(120),
  object_length_linter(40),
  cyclocomp_linter(15),
  commented_code_linter = NULL
)
exclude: "renv"
```

### Git Workflow

- **Main Branch**: `master` (protected)
- **Feature Branches**: `feature/feature-name`
- **Bugfix Branches**: `bugfix/issue-description`
- **Hotfix Branches**: `hotfix/critical-fix`

---

## Testing

### Running Tests

```r
# Run all tests
source('scripts/test.R')

# Run specific test file
testthat::test_file('tests/testthat/test_modules.R')

# Run with coverage
source('scripts/coverage.R')
```

### Test Structure

```r
# tests/testthat/test_modules.R
library(testthat)
library(shiny)

test_that("loadServer returns reactive data", {
  testServer(loadServer, {
    # Test logic here
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

### Current Test Coverage

- Module initialization tests
- Reactive return value tests
- Basic edge case handling

### Future Testing

- [ ] Add `shinytest2` snapshot tests for UI regression
- [ ] Performance regression tests
- [ ] Integration tests across modules
- [ ] Increase coverage to >80% for critical paths

---

## Contributing

We welcome contributions! Please follow these guidelines:

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch** from `master`
3. **Follow the development workflow** (see [Development](#development))
4. **Ensure all tests pass** and code is linted
5. **Submit a pull request** with a clear description

### Contribution Areas

- **Features**: New visualizations, rate plans, export functionality
- **Bug Fixes**: Report and fix issues
- **Documentation**: Improve README, add user guides, create tutorials
- **Testing**: Add test coverage, create snapshot tests
- **Performance**: Optimize rendering, caching, data processing

### Code Review Standards

All pull requests should meet these requirements:

- Code follows style guidelines (run `scripts/lint.R`)
- Tests pass and coverage is maintained (run `scripts/test.R`)
- Changes are documented in code comments
- No security vulnerabilities introduced
- Commit messages are clear and descriptive

See `docs/CODE_REVIEW_CHECKLIST.md` for the complete checklist.

---

## Documentation

### Available Documentation

- **README.md** (this file) - Complete project documentation and user guide
- **Live Demo** - [Interactive application](https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/) with sample data
- **docs/CODE_REVIEW_CHECKLIST.md** - Pull request review requirements
- **Code Comments** - Inline documentation throughout the codebase

### Getting Help

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/discussions)
- **Live Demo**: Try the application at https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/

---

## Troubleshooting

### Common Issues

#### App Won't Start

```r
# Issue: Missing dependencies
# Solution:
renv::restore()

# Issue: Port already in use
# Solution: Specify a different port
shiny::runApp('.', port = 8888)
```

#### Data Upload Fails

```r
# Issue: Missing required columns
# Solution: Ensure your data has: dttm_start, hour, value, day, day2

# Issue: Date format incorrect
# Solution: Use format YYYY-MM-DD HH:MM:SS for dttm_start
```

#### Visualizations Not Rendering

```r
# Issue: Empty data after filtering
# Solution: Check date range selection and data availability

# Issue: Missing ggplot2 or plotly
# Solution:
renv::restore()
```

#### Logs Not Appearing

```r
# Issue: logs/ directory doesn't exist
# Solution: Create it manually
dir.create("logs", showWarnings = FALSE)
```

### Performance Tips

- **Large Datasets**: Filter data to specific date ranges before visualization
- **Slow Rendering**: Consider caching expensive computations with `bindCache()`
- **Memory Usage**: Use `data.table` for large data operations

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **PG&E** for smart meter data standards
- **R Shiny Community** for excellent packages and support
- **Contributors** who help improve this project

---

## Contact

- **Author**: Sumedh Sankhe
- **GitHub**: [@SumedhSankhe](https://github.com/SumedhSankhe)
- **Repository**: [PG-E-Data-Visualizer](https://github.com/SumedhSankhe/PG-E-Data-Visualizer)
- **Live Demo**: https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/
