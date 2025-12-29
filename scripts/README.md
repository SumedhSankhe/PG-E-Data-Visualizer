# Scripts Directory

This directory contains all scripts for the PG&E Data Visualizer project.

## 📁 Directory Structure

```
scripts/
├── automation/          # PGE data automation scripts
│   ├── fetch_pge_data.py              # Fetch data from PGE API
│   ├── process_pge_data.R             # Process API data to SQLite
│   └── convert_pge_download_v2.R      # Convert manual PGE downloads
├── ci/                  # CI/CD pipeline scripts
│   ├── lint.R                         # Code linting
│   ├── coverage.R                     # Code coverage testing
│   ├── test.R                         # Unit tests runner
│   └── style.R                        # Code styling
└── utils/               # Testing and verification utilities
    ├── verify_app_data.R              # Verify database integrity
    ├── verify_app_data.bat            # Windows batch wrapper
    ├── test_sqlite.R                  # SQLite database tests
    ├── test_local.bat                 # Local testing batch file
    └── process_pge_data.bat           # Process data batch file
```

## 🤖 Automation Scripts

### `automation/fetch_pge_data.py`
**Purpose**: Fetch energy usage data from PGE Share My Data API

**Usage**:
```bash
python scripts/automation/fetch_pge_data.py
```

**Requirements**:
- Environment variables: `PGE_CLIENT_ID`, `PGE_CLIENT_SECRET`, `PGE_ACCESS_TOKEN`
- Python package: `pgesmd-self-access`

**Output**: `data/pge_latest.csv`

---

### `automation/process_pge_data.R`
**Purpose**: Process CSV data into SQLite database with automatic interval detection

**Usage**:
```r
Rscript scripts/automation/process_pge_data.R
```

**Features**:
- Auto-detects data interval (15-min, hourly, daily)
- Aggregates sub-hourly data to hourly
- Merges with existing database
- Removes duplicates

**Input**: `data/pge_latest.csv`
**Output**:
- `data/pge_meter_data.sqlite` (primary)
- `data/meterData.rds` (backup)

---

### `automation/convert_pge_download_v2.R`
**Purpose**: Convert manually downloaded PGE Green Button CSV to app format

**Usage**:
```r
Rscript scripts/automation/convert_pge_download_v2.R
```

**Features**:
- Handles PGE's CSV format (5 header rows)
- Auto-detects and aggregates 15-minute intervals
- Creates SQLite database + RDS + CSV
- Robust error handling

**Input**: `data/pge_electric_usage_*.csv`
**Output**:
- `data/pge_meter_data.sqlite`
- `data/meterData.rds`
- `data/pge_latest.csv`

## 🛠️ Utility Scripts

### `utils/verify_app_data.R`
**Purpose**: Verify that processed data is valid for Shiny app

**Usage**:
```r
source("scripts/utils/verify_app_data.R")
# Or on Windows:
scripts\utils\verify_app_data.bat
```

**Tests**:
- SQLite database integrity
- RDS backup validity
- CSV export format
- Required columns present

---

### `utils/test_sqlite.R`
**Purpose**: Test SQLite database operations

---

### Windows Batch Files
**Purpose**: Convenient wrappers for running scripts on Windows

- `verify_app_data.bat` - Run verification
- `test_local.bat` - Run local tests
- `process_pge_data.bat` - Process PGE data

## 🧪 CI/CD Scripts

These scripts run automatically in GitHub Actions on every pull request.

### `ci/lint.R`
**Purpose**: Check R code for style issues and errors

**Usage**:
```r
Rscript scripts/ci/lint.R
```

**Used in**: `.github/workflows/ci-tests.yml` (runs on every PR)

---

### `ci/coverage.R`
**Purpose**: Measure test coverage and upload to Codecov

**Usage**:
```r
Rscript scripts/ci/coverage.R
```

**Output**: `coverage.json`, `coverage-summary.txt`
**Used in**: CI pipeline after tests run

---

### `ci/test.R`
**Purpose**: Run unit tests with testthat

**Usage**:
```r
Rscript scripts/ci/test.R
```

**Tests**: `tests/testthat/`
**Used in**: CI pipeline

---

### `ci/style.R`
**Purpose**: Auto-format R code to consistent style

**Usage**:
```r
Rscript scripts/ci/style.R
```

**Note**: Modifies files in-place with `styler` package

## 📖 Documentation

For detailed documentation on the automation system, see:
- **[docs/automation/](../docs/automation/)** - Complete automation documentation

## 🔗 Related Files

- **`.github/workflows/fetch-pge-data.yml`** - GitHub Actions workflow (uses these scripts)
- **`data/`** - Output directory for processed data
- **`logs/`** - Log files from processing

## 🚀 Quick Commands

### Process manually downloaded PGE data:
```bash
Rscript scripts/automation/convert_pge_download_v2.R
```

### Verify data is ready for Shiny app:
```bash
Rscript scripts/utils/verify_app_data.R
```

### Test automation pipeline:
See [docs/automation/LOCAL_TESTING.md](../docs/automation/LOCAL_TESTING.md)
