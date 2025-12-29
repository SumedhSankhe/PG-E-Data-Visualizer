# Local Testing Guide

Test the PGE data automation pipeline locally before deploying to production.

## Quick Start

### Option 1: Windows (Easiest)

```cmd
cd C:\Users\Sumedh\Documents\GitHub\PG-E-Data-Visualizer
test_local.bat
```

### Option 2: WSL/Linux

```bash
cd /mnt/c/Users/Sumedh/Documents/GitHub/PG-E-Data-Visualizer
Rscript scripts/test_local.R
```

### Option 3: RStudio

1. Open RStudio
2. Set working directory: `setwd("C:/Users/Sumedh/Documents/GitHub/PG-E-Data-Visualizer")`
3. Run: `source("scripts/test_local.R")`

---

## What the Test Does

The test script (`scripts/test_local.R`) performs a complete end-to-end test:

### 1. **Generates Sample PGE Data**
- Creates 14 days of realistic hourly energy consumption
- Higher usage during day (7am-10pm): 0.8-2.5 kWh
- Lower usage at night: 0.3-0.8 kWh
- Saves to `test_output/pge_latest.csv`

### 2. **Tests Data Processing**
- Reads the CSV file
- Creates SQLite database (`test_output/pge_meter_data.sqlite`)
- Inserts data with proper schema
- Creates indexes for performance
- Saves RDS backup (`test_output/meterData.rds`)

### 3. **Tests Database Queries**
- Total row count
- Date range
- Total consumption
- Average hourly consumption
- Peak usage hour

### 4. **Tests Shiny App Loading**
- Uses the `read_meter_data_safely()` function from `global.R`
- Verifies SQLite database loading works
- Tests RDS fallback mechanism

### 5. **Validates Complete Pipeline**
- Ensures all data transformations work
- Checks column names and types
- Verifies date/time handling

---

## Expected Output

You should see output like this:

```
========================================
PGE Data Automation - Local Test
========================================

Step 1: Generating sample PGE data...
  ✓ Generated 336 rows of sample data
  ✓ Date range: 2025-12-14 00:00:00 to 2025-12-27 23:00:00
  ✓ Total consumption: 450.32 kWh

  ✓ Saved sample CSV: test_output/pge_latest.csv

Step 2: Testing data processing...
  ✓ Loaded CSV: 336 rows
  ✓ Created SQLite database
  ✓ Inserted data into database
  ✓ Database contains 336 rows
  ✓ Saved RDS backup: 336 rows

Step 3: Testing database queries...
  ✓ Total rows: 336
  ✓ Date range: 2025-12-14 00:00:00, 2025-12-27 23:00:00
  ✓ Total consumption: 450.32
  ✓ Avg hourly: 1.34
  ✓ Peak hour: 19, 1.87

Step 4: Testing Shiny app data loading...
  ✓ Loaded 336 rows via Shiny app function
  ✓ Columns: dttm_start, hour, value, day, day2
  ✓ Date range: 2025-12-14 00:00:00 to 2025-12-27 23:00:00

Step 5: Testing RDS fallback...
  ✓ RDS fallback works: 336 rows

========================================
TEST SUMMARY
========================================
✓ Sample data generated: 336 rows
✓ CSV file created: test_output/pge_latest.csv
✓ SQLite database created: test_output/pge_meter_data.sqlite
✓ RDS backup created: test_output/meterData.rds
✓ Database queries work
✓ Shiny app loading function works
✓ RDS fallback works

All tests passed! ✓

Next steps:
1. Run Shiny app locally and verify it loads test data
2. When you get PGE credentials, test the Python fetch script
3. Test full pipeline with real PGE data

Test files location: test_output/
========================================
```

---

## Testing the Shiny App

After running the test script, test the Shiny app with the test data:

### Step 1: Copy Test Database to Data Directory

```r
# In R or RStudio:
file.copy("test_output/pge_meter_data.sqlite", "data/pge_meter_data.sqlite", overwrite = TRUE)
file.copy("test_output/meterData.rds", "data/meterData.rds", overwrite = TRUE)
```

Or in Windows:
```cmd
copy test_output\pge_meter_data.sqlite data\pge_meter_data.sqlite
copy test_output\meterData.rds data\meterData.rds
```

### Step 2: Run the Shiny App

**Option A: RStudio**
1. Open `ui.R` or `server.R`
2. Click "Run App" button

**Option B: Command Line**
```r
shiny::runApp()
```

### Step 3: Verify in the App

The app should:
- ✅ Load without errors
- ✅ Show 14 days of data (from the test)
- ✅ Display energy consumption charts
- ✅ Allow date range selection
- ✅ Show all analysis modules working

---

## Testing the Python Script (When You Have PGE Credentials)

Once you receive PGE credentials:

### Step 1: Set Environment Variables

```bash
# Linux/WSL
export PGE_CLIENT_ID="your_client_id"
export PGE_CLIENT_SECRET="your_client_secret"
export PGE_ACCESS_TOKEN="your_access_token"
```

```cmd
REM Windows
set PGE_CLIENT_ID=your_client_id
set PGE_CLIENT_SECRET=your_client_secret
set PGE_ACCESS_TOKEN=your_access_token
```

### Step 2: Install Python Package

```bash
pip install pgesmd-self-access pandas
```

### Step 3: Test Python Fetch Script

```bash
python scripts/fetch_pge_data.py
```

Should create: `data/pge_latest.csv` with real PGE data

### Step 4: Test Processing

```r
Rscript scripts/process_pge_data.R
```

Should update: `data/pge_meter_data.sqlite` with real data

---

## Testing the Complete Pipeline

### Full End-to-End Test:

1. **Fetch data** (with real credentials):
   ```bash
   python scripts/fetch_pge_data.py
   ```

2. **Process data**:
   ```r
   Rscript scripts/process_pge_data.R
   ```

3. **Run Shiny app**:
   ```r
   shiny::runApp()
   ```

4. **Verify** the app shows your actual PGE data!

---

## Troubleshooting

### Test Script Fails

**Error: "package 'XXX' is not available"**
```r
install.packages(c('data.table', 'DBI', 'RSQLite', 'logger'))
```

**Error: "cannot open file 'global.R'"**
- Make sure you're in the project root directory
- Check: `getwd()` should show `.../PG-E-Data-Visualizer`

**Error: Database locked**
- Close any R sessions that might have the database open
- Delete test database and try again:
  ```r
  unlink("test_output/pge_meter_data.sqlite")
  ```

### Shiny App Issues

**App doesn't load data**
- Check that database file exists: `file.exists("data/pge_meter_data.sqlite")`
- Check logs in `logs/` directory
- Try RDS fallback: delete SQLite and ensure RDS file exists

**Date range is empty**
- Verify data exists: `readRDS("data/meterData.rds")`
- Check `dttm_start` column is POSIXct type

### Python Script Issues

**Import Error: No module named 'pgesmd_self_access'**
```bash
pip install pgesmd-self-access
```

**Authentication Error**
- Verify environment variables are set: `echo $PGE_CLIENT_ID`
- Check credentials are correct
- Access token may have expired - re-authorize

---

## Clean Up Test Files

To remove all test files:

```r
unlink("test_output", recursive = TRUE)
```

Or Windows:
```cmd
rmdir /s /q test_output
```

---

## Success Checklist

After testing locally, you should have verified:

- ✅ Test script runs without errors
- ✅ SQLite database is created correctly
- ✅ RDS backup is created
- ✅ Database queries return expected results
- ✅ Shiny app loads test data successfully
- ✅ All app modules work with test data
- ✅ RDS fallback mechanism works
- ✅ (When you have credentials) Python script fetches real data
- ✅ (When you have credentials) Real data processes correctly

Once all tests pass locally, you're ready to deploy to GitHub Actions and shinyapps.io!

---

## Next Steps

1. **Run the local test** to verify everything works
2. **Test the Shiny app** with test data
3. **Wait for PGE approval** to get credentials
4. **Test with real PGE data** locally
5. **Configure GitHub Secrets** with credentials
6. **Deploy to production** via GitHub Actions

**Ready to test?** Run `test_local.bat` or `Rscript scripts/test_local.R` now!
