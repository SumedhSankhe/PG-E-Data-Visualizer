# Testing Your Shiny App with Real PGE Data

## ✅ Data Processing Complete!

Your PGE energy data has been successfully processed:

### Data Summary
- **Date Range**: March 20, 2025 → December 27, 2025 (283 days)
- **Total Hours**: 6,768 hourly data points
- **Original Format**: 27,072 15-minute intervals (aggregated to hourly)
- **Total Consumption**: ~1,324 kWh
- **Source**: PGE Green Button Download

### Files Created
1. **`data/pge_meter_data.sqlite`** (912 KB) - Primary database for Shiny app
2. **`data/meterData.rds`** (13 KB) - Backup/fallback format
3. **`data/pge_latest.csv`** (243 KB) - Human-readable export

---

## Quick Verification

### Option 1: Run Verification Script (Recommended)

**Windows:**
```batch
verify_app_data.bat
```

**R Console:**
```r
source("verify_app_data.R")
```

This will test that your Shiny app can load the SQLite database correctly.

---

## Testing Your Shiny App Locally

### Step 1: Launch the App

**In RStudio:**
1. Open `app.R` or `global.R`
2. Click "Run App" button

**From R Console:**
```r
library(shiny)
runApp()
```

**From Command Line:**
```batch
R -e "shiny::runApp()"
```

### Step 2: Verify Data Loaded Correctly

The app should now show:
- **Date range**: March 20, 2025 to December 27, 2025
- **283 days** of energy usage data
- **Hourly visualizations** (not 15-minute intervals)

### Step 3: Check Key Features

Test these features to ensure everything works:

#### 1. Data Range Display
- Check that date range shows March 20 - December 27, 2025
- Verify total days shows 283

#### 2. Time Series Plot
- Should show smooth hourly energy usage over 9+ months
- Zoom in to verify hourly granularity (not 15-min)

#### 3. Heatmap
- Should display 283 days × 24 hours
- Check for proper color scaling

#### 4. Day Comparison
- Select different days to compare
- Verify hourly profiles are visible

#### 5. Statistics
- Total consumption: ~1,324 kWh
- Average hourly consumption: ~0.20 kWh
- Peak usage hours should be identifiable

---

## Expected vs Actual

### What Should Work ✅
- App launches without errors
- Data loads from SQLite database
- All visualizations render correctly
- Date range reflects your real PGE data (Mar 20 - Dec 27, 2025)
- Hourly granularity (aggregated from 15-min intervals)

### What Would Indicate Problems ❌
- Error: "Cannot find data file"
- Date range still shows old dates (if using cached data)
- Plots show strange patterns or missing data
- App crashes on launch

---

## Troubleshooting

### Issue: App shows old date range
**Solution**: The app might have cached old RDS data
```r
# Remove old RDS and restart app
file.remove("data/meterData.rds")
# Re-run conversion script to recreate it
source("scripts/convert_pge_download_v2.R")
```

### Issue: SQLite error on app launch
**Solution**: App will automatically fall back to RDS file
- Check `verify_app_data.R` output for details
- RDS file should work as fallback

### Issue: Missing packages
**Solution**: Install required packages
```r
install.packages(c("shiny", "shinydashboard", "data.table",
                   "ggplot2", "plotly", "DT", "shinycssloaders",
                   "shinyjs", "openxlsx", "logger", "DBI", "RSQLite"))
```

---

## Next Steps After Local Testing

### 1. Verify Everything Works Locally ✅
- [x] Data loads from SQLite database
- [ ] All visualizations render correctly
- [ ] Date range is correct (Mar 20 - Dec 27, 2025)
- [ ] No errors in console

### 2. Prepare for Deployment

Once local testing is successful, you can deploy to shinyapps.io:

#### Manual Deployment (Current)
```r
library(rsconnect)
deployApp()
```

#### Automated Deployment (Future with GitHub Actions)
When you receive PGE API credentials, the GitHub Actions workflow will automatically:
1. Fetch latest data from PGE API daily
2. Update SQLite database
3. Auto-deploy to shinyapps.io

---

## Understanding Your Data

### Original PGE Format
- **Interval**: 15 minutes
- **Total records**: 27,072
- **File size**: 1.3 MB
- **Format**: CSV with DATE, START TIME, USAGE (kWh) columns

### Processed Format
- **Interval**: Hourly (aggregated from 15-min)
- **Total records**: 6,768
- **Method**: Sum of all 15-min intervals per hour
- **Storage**: SQLite database + RDS backup

### Why Aggregation?
The Shiny app expects hourly data. PGE provides 15-minute intervals, so we:
1. **Group** by hour (00:00, 01:00, 02:00, etc.)
2. **Sum** all kWh values within that hour
3. **Result**: Total energy consumption per hour

**Example:**
```
15-min intervals for Hour 1:
  00:00 → 0.04 kWh
  00:15 → 0.15 kWh
  00:30 → 0.07 kWh
  00:45 → 0.09 kWh

Hourly aggregate:
  00:00 → 0.35 kWh (sum)
```

This is **correct** because energy consumption is cumulative over the time period.

---

## Viewing Your Data

### Quick Data Inspection

**In R Console:**
```r
# Load from SQLite
library(DBI)
library(RSQLite)
con <- dbConnect(RSQLite::SQLite(), "data/pge_meter_data.sqlite")
data <- dbReadTable(con, "meter_data")
head(data)
dbDisconnect(con)

# Or load from RDS
data <- readRDS("data/meterData.rds")
head(data)

# Or load from CSV
data <- read.csv("data/pge_latest.csv")
head(data)
```

**Expected columns:**
- `dttm_start` - Timestamp (POSIXct or character)
- `hour` - Hour of day (0-23)
- `value` - Energy consumption (kWh)
- `day` - Day number (1-283)
- `day2` - Copy of day (for compatibility)

---

## Success Criteria

Your Shiny app is ready when:
- ✅ App launches without errors
- ✅ Visualizations show March 20 - December 27, 2025 date range
- ✅ 283 days of data visible
- ✅ Hourly granularity throughout
- ✅ Heatmap displays properly
- ✅ Statistics are reasonable (~1,324 kWh total)
- ✅ No console errors

Once verified locally, you're ready to deploy to shinyapps.io! 🎉

---

## Notes

- **Data Source**: Manual PGE Green Button download
- **Processing**: Automatic interval detection and aggregation
- **Database**: SQLite (primary) + RDS (fallback)
- **Future**: Will switch to automated daily PGE API fetching once OAuth credentials are received

---

## Need Help?

If you encounter issues:
1. Run `verify_app_data.R` to diagnose data loading
2. Check R console for error messages
3. Verify all required packages are installed
4. Check that SQLite database file exists and is not corrupted
