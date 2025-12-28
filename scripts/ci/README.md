# CI/CD Scripts

These scripts are used in the GitHub Actions continuous integration pipeline (`.github/workflows/ci-tests.yml`).

They run automatically on **every pull request** to ensure code quality and test coverage.

---

## Scripts

### `lint.R` - Code Quality Checks

**What it does**: Checks R code for style issues, errors, and best practices violations

**When it runs**: On every pull request (GitHub Actions)

**Configuration**: Uses `.lintr` configuration file in root directory

**Usage**:
```r
Rscript scripts/ci/lint.R
```

**Output**: `lint-output.txt` (uploaded as GitHub Actions artifact)

**Fails if**: Code has errors (type = 'error')

---

### `coverage.R` - Test Coverage Measurement

**What it does**:
- Measures what percentage of your code is covered by tests
- Generates coverage reports
- Uploads to Codecov for tracking over time

**When it runs**: After unit tests pass in GitHub Actions

**Usage**:
```r
Rscript scripts/ci/coverage.R
```

**Output**:
- `coverage.json` - Full coverage data
- `coverage-summary.txt` - Human-readable summary

**Integration**: Uploads to [Codecov](https://codecov.io/) (see badge in README)

**Requirements**: `covr` package

---

### `test.R` - Unit Tests Runner

**What it does**: Runs all unit tests in `tests/testthat/` directory

**When it runs**: On every pull request, before coverage

**Usage**:
```r
Rscript scripts/ci/test.R
```

**Test framework**: `testthat`

**Optional**: Also supports `shinytest2` snapshot tests

**Output**: Test results printed to console (saved as artifact)

---

### `style.R` - Auto-formatting

**What it does**: Automatically formats R code to consistent style

**When it runs**:
- Can run manually for auto-formatting
- CI runs a dry-run check (doesn't modify files)

**Usage**:
```r
# Auto-format all R files (modifies in-place)
Rscript scripts/ci/style.R

# Or check only (no changes):
R -q -e 'styler::style_dir(".", filetype = c("R"), exclude_dirs = c("renv"))'
```

**Style guide**: Uses `styler` package defaults (tidyverse style)

**Excludes**: `renv/` directory

---

## GitHub Actions Integration

These scripts are called in `.github/workflows/ci-tests.yml`:

```yaml
jobs:
  lint:
    steps:
      - name: Run lintr
        run: Rscript scripts/ci/lint.R

      - name: Style check (dry run)
        run: styler::style_dir(...)

  tests:
    needs: lint
    steps:
      - name: Run tests
        run: Rscript scripts/ci/test.R

      - name: Compute coverage
        run: Rscript scripts/ci/coverage.R

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
```

## Running Locally

You can run these scripts locally before pushing:

```r
# 1. Check code style
Rscript scripts/ci/lint.R

# 2. Auto-format code
Rscript scripts/ci/style.R

# 3. Run tests
Rscript scripts/ci/test.R

# 4. Check coverage
Rscript scripts/ci/coverage.R
```

**Tip**: Run lint and tests before creating a pull request to catch issues early!

---

## Required Packages

These scripts require:
- `lintr` - Code linting
- `styler` - Code styling
- `testthat` - Unit testing
- `covr` - Coverage measurement
- `jsonlite` - JSON output (used by coverage.R)

All are included in `renv.lock` and will be installed automatically via `renv::restore()`.

---

## CI Badge

Your README shows the CI status:

[![CI Status](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions)

- ✅ Green = All tests passing, linting clean
- ❌ Red = Tests failing or lint errors

---

## Troubleshooting

### Lint errors in CI
Check `lint-output.txt` artifact in GitHub Actions for details

**Fix**: Run `Rscript scripts/ci/lint.R` locally to see errors

### Tests failing
**Fix**: Run `Rscript scripts/ci/test.R` locally to debug

### Coverage not uploading
**Check**: `CODECOV_TOKEN` secret is set in GitHub repository settings

### Style check failing
**Fix**: Run `Rscript scripts/ci/style.R` to auto-format, then commit changes

---

See [scripts/README.md](../README.md) for all scripts documentation.
