# PG&E Data Visualizer

[![CI Status](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions)
[![Coverage](https://codecov.io/gh/SumedhSankhe/PG-E-Data-Visualizer/branch/master/graph/badge.svg)](https://codecov.io/gh/SumedhSankhe/PG-E-Data-Visualizer)
[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> An interactive R Shiny dashboard for exploring and analyzing Pacific Gas & Electric (PG&E) smart meter energy consumption data with powerful visualizations and rate plan comparisons.

![PG&E Data Visualizer](docs/screenshot.png)

---

## Table of Contents

- [Overview](#overview)
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
- [Roadmap](#roadmap)
- [License](#license)

---

## Overview

The **PG&E Data Visualizer** is a web-based application built with R Shiny that helps utilities, energy customers, and analysts understand energy consumption patterns through interactive visualizations. The application provides:

- **Time Series Analysis**: Visualize hourly consumption patterns across multiple days
- **Distribution Analysis**: Understand usage variability with box plots and statistical summaries
- **Rate Plan Comparison**: Evaluate different PG&E pricing structures (Time of Use, Tiered, EV Plans)
- **Interactive Exploration**: Zoom, pan, and hover for detailed insights

### Use Cases

- **Energy Analysts**: Compare rate plans and identify cost-saving opportunities
- **Homeowners**: Understand peak usage hours and optimize consumption
- **Utilities**: Analyze consumption patterns and support customer decision-making
- **Researchers**: Study energy usage trends and behavioral patterns

---

## Features

### Core Functionality

- **Modular Architecture**: Clean Shiny module pattern (`home`, `loadData`, `analyse`)
- **Flexible Data Input**: Upload CSV/TSV files or use bundled sample data
- **Interactive Visualizations**:
  - Time series plots with overlaid daily patterns and trend lines
  - Box plots showing hourly distribution with quartiles and outliers
  - Built with ggplot2 and plotly for rich interactivity
- **Rate Plan Support**:
  - Time of Use (E-TOU-C, E-TOU-D) with configurable peak hours
  - Tiered Rate Plans (T1, T2, T3)
  - Electric Vehicle Plans (EV2-A, EV-B)
  - Solar & Renewable Energy Plans (coming soon)
- **Comprehensive Logging**: Daily rotating logs with structured logging via `logger` package
- **Responsive Design**: Clean, professional UI with shinydashboard

### Quality Assurance

- **Automated Testing**: Unit tests with `testthat`, CI/CD with GitHub Actions
- **Code Quality**: Automated linting and style checks
- **Dependency Management**: Reproducible environments with `renv`
- **Documentation**: Comprehensive inline comments and agent-based development guides

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

### 2. Configure Analysis

Go to the **Analyse** tab and:
- Select your **rate plan type** (Time of Use, Tiered, EV Plan, etc.)
- Choose specific **tier options** based on your plan
- Set your **date range** to analyze specific periods
- For Time of Use plans, configure peak hours and pricing

### 3. Explore Visualizations

- **Time Series Plot**: See how consumption varies by hour across multiple days
- **Distribution Box Plot**: Identify typical usage ranges and outliers for each hour

### Example Workflow

```r
# 1. Start the app
shiny::runApp('.')

# 2. Navigate to Data tab
#    - Upload your_meter_data.csv

# 3. Navigate to Analyse tab
#    - Select "Time of Use" plan
#    - Choose "E-TOU-C" tier
#    - Set date range: 2024-01-01 to 2024-01-31
#    - Configure peak hours: 16-21 (4 PM - 9 PM)
#    - Set peak rate: $0.45/kWh, off-peak: $0.25/kWh

# 4. Explore the visualizations
#    - Hover over plots for details
#    - Zoom and pan to focus on specific periods
#    - Identify peak usage hours
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
├── home.R                  # Home module (UI & server)
├── loadData.R              # Data loading module
├── analyse.R               # Analysis module (visualizations)
├── .gitignore              # Git ignore rules
├── .lintr                  # Linting configuration
├── README.md               # This file
├── renv.lock               # Dependency lock file
├── PG-E-Data-Visualizer.Rproj  # RStudio project
│
├── data/
│   └── meterData.rds      # Sample dataset
│
├── docs/
│   ├── AGENTS.md          # Sub-agent responsibilities (20 agents)
│   ├── CODE_REVIEW_CHECKLIST.md  # PR review guidelines
│   ├── STYLE.md           # CSS and design guidelines (future)
│   └── USER_GUIDE.md      # Detailed user manual (future)
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

The application follows the **Shiny Module pattern** for modularity and maintainability:

1. **Home Module** (`home.R`)
   - Landing page with application overview
   - User guide and documentation
   - No reactive server logic (static content)

2. **Load Data Module** (`loadData.R`)
   - File upload interface
   - Data validation and error handling
   - Interactive data table display
   - Returns reactive data for downstream modules

3. **Analyse Module** (`analyse.R`)
   - Rate plan selection controls
   - Date range filtering
   - Peak hour configuration (Time of Use plans)
   - Time series and distribution visualizations

### Data Flow

```
User Upload → loadDataServer → Reactive Data → analyseServer → Visualizations
     ↓              ↓                                    ↓
Sample Data    Validation                         Time Series Plot
               Error Handling                     Distribution Plot
               Logging
```

---

## Development

### Development Workflow

Following the agent-based development lifecycle defined in `docs/AGENTS.md`:

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Implement Changes**
   - Follow Shiny module pattern (`modNameUI`, `modNameServer`)
   - Use `req()` and `validate(need())` for error handling
   - Add logging with `logger::log_info()`, `logger::log_warn()`, etc.
   - Keep functions under 60 lines

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

5. **Update Documentation**
   - Update README if user-facing changes
   - Update CHANGELOG (future)
   - Add roxygen comments for new functions

6. **Open Pull Request**
   - Reference related issue
   - Attach lint and test outputs
   - Follow PR template (future)

7. **Code Review**
   - Address feedback from `docs/CODE_REVIEW_CHECKLIST.md`
   - Ensure CI passes

8. **Merge**
   - Squash and merge after approvals

### Coding Standards

#### Style Guide

- **Naming**: `snake_case` for variables/functions, `UPPER_SNAKE_CASE` for constants
- **Indentation**: 2 spaces (no tabs)
- **Line Length**: ≤ 120 characters
- **Spacing**: Spaces around operators (`<-`, `=`, `+`, etc.)

#### Best Practices

```r
# ✓ Good
analyseServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    req(data())                          # Guard against NULL
    validate(need(                       # User-friendly error
      nrow(data()) > 0,
      "No data available for analysis"
    ))

    logger::log_info("Analysis started")  # Logging

    # Reactive logic here
  })
}

# ✗ Bad
analyseServer<-function(id,data){  # No spaces, long line, no validation
  moduleServer(id,function(input,output,session){plot(data()$value)})
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

### Code Review Process

All contributions are reviewed by specialized agents defined in `docs/AGENTS.md`:

1. **Linting & Style Agent** - Code formatting and standards
2. **Code Review Agent** - Quality, security, maintainability
3. **Testing Agent** - Test coverage and quality
4. **Documentation Agent** - Documentation updates
5. **Security Agent** - Security vulnerabilities

See `docs/CODE_REVIEW_CHECKLIST.md` for detailed requirements.

---

## Documentation

### Available Documentation

- **README.md** (this file) - Project overview and quick start
- **docs/AGENTS.md** - Complete lifecycle management with 20 specialized agents
- **docs/CODE_REVIEW_CHECKLIST.md** - PR review requirements

### Future Documentation

- [ ] **docs/USER_GUIDE.md** - Detailed user manual with screenshots
- [ ] **docs/DEPLOYMENT.md** - Deployment instructions for production
- [ ] **docs/CONTRIBUTING.md** - Contributor guidelines
- [ ] **docs/CHANGELOG.md** - Version history and release notes
- [ ] **docs/API.md** - Function reference with roxygen docs

### Getting Help

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/discussions)

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

## Roadmap

### Short-term (1-3 months)

- [ ] Implement `shinytest2` snapshot tests
- [ ] Add performance metrics instrumentation
- [ ] Create user guide with screenshots
- [ ] Set up automated dependency scanning
- [ ] Add CHANGELOG.md with version history

### Medium-term (3-6 months)

- [ ] Introduce accessibility scanning with `pa11y`
- [ ] Implement A/B testing framework
- [ ] Add export functionality (PDF reports, CSV downloads)
- [ ] Create admin dashboard for monitoring
- [ ] Side-by-side rate plan comparison view

### Long-term (6-12 months)

- [ ] Multi-language support (i18n)
- [ ] API for programmatic access
- [ ] Mobile-responsive redesign
- [ ] Real-time data streaming support
- [ ] Machine learning predictions for usage patterns
- [ ] Integration with other utility data sources

See `docs/AGENTS.md` for complete enhancement roadmap.

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

---

**Built with ❤️ using R Shiny**
