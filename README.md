# PG&E Data Visualizer

[![CI Status](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions)
[![Coverage](https://codecov.io/gh/SumedhSankhe/PG-E-Data-Visualizer/branch/master/graph/badge.svg)](https://codecov.io/gh/SumedhSankhe/PG-E-Data-Visualizer)

An R Shiny dashboard for exploring and analyzing PG&E smart meter data with interactive time series and distribution insights.

## Features
- Modular Shiny architecture (`home`, `loadData`, `analyse` modules)
- Data upload or fallback to bundled `data/meterData.rds`
- Time series visualization with ggplot2 + plotly
- Hourly distribution box/jitter plots
- Dynamic tier & plan controls (TOU plans, etc.)

## Quick Start
```r
# Inside R
renv::restore()        # if using renv to install dependencies
shiny::runApp('.')     # launches the app
# Logs written to logs/app-YYYY-MM-DD.log
```

## Data & Logging
- Place persistent data files in `data/` (default sample: `data/meterData.rds`).
- Runtime log files rotate daily by date: `logs/app-YYYY-MM-DD.log`.
- Logging uses the `logger` package with INFO threshold; adjust in `global.R`.
- Fallback data is loaded via `read_rds_safely()` with warnings if missing.
```

## Repository Sub-Agents
Specialized contributor roles are defined in `docs/AGENTS.md`:
- Shiny Development
- UI/UX
- Documentation
- Code Review
- Linting & Style
 - Testing

Each PR should pass through these agent checklists prior to merge.

## Tests
Basic test scaffolding is included (see `tests/`):
```r
source('scripts/test.R')   # runs unit/module tests (skips gracefully if deps missing)
```
Add `shinytest2` for snapshot tests:
```r
install.packages('shinytest2')
```
Then record snapshots (example):
```r
shinytest2::record_test('.')
```

## Lint & Style
```r
source('scripts/lint.R')   # prints lint results
source('scripts/style.R')  # applies styler formatting
```
Integrate into CI (example GitHub Action step):
```yaml
- name: Lint
  run: Rscript scripts/lint.R
- name: Style Check (dry-run)
  run: Rscript -e "styler::style_dir('.', filetype = c('R'), exclude_dirs = c('renv'))"
```

## Code Review Checklist
See `docs/CODE_REVIEW_CHECKLIST.md` for required review gates.

## Suggested Development Workflow
1. Create feature branch.
2. Implement module changes (follow naming & reactive best practices).
3. Run `scripts/style.R` then `scripts/lint.R`.
4. Run `scripts/test.R` and ensure passing.
5. Update README & CHANGELOG (future).
6. Open PR referencing issue; attach lint & test outputs.
7. Address agent feedback (including Testing Agent).
8. Merge after approvals.

## Future Enhancements
- Add `shinytest2` snapshots
- Performance profiling & caching
- Accessibility audits
 - Code coverage via `covr` & badge
 - Visual regression of plots (PNG diff)
 - Log rotation + size limits (custom appender)
 - Structured logging (JSON) for analytics

## License
Add license information here (MIT / Apache-2.0 / etc.).
