# Data Interval Handling

## Overview

PGE smart meters can provide energy usage data at different intervals:
- **15-minute intervals** (most common for residential SmartMeters)
- **Hourly intervals** (aggregated data)
- **Daily intervals** (for older meters or specific data types)

The automation pipeline **automatically detects** the interval type and processes accordingly.

---

## How It Works

### 1. **Python Fetch Script** (`scripts/fetch_pge_data.py`)

**What it does:**
- Fetches data from PGE Share My Data API
- Detects the data interval by measuring time difference between consecutive records
- Logs the detected interval (e.g., "15 minutes", "60 minutes")
- Saves raw data to CSV with just `dttm_start` and `value` columns
- **Does NOT aggregate** - leaves that to the R script

**Example log output:**
```
Detected data interval: ~15 minutes
Sub-hourly data detected (15 min intervals)
R processing script will aggregate to hourly
```

---

### 2. **R Processing Script** (`scripts/process_pge_data.R`)

**What it does:**
- Reads the CSV from Python script
- **Auto-detects interval** by calculating median time difference
- **Automatically aggregates** if interval < 60 minutes:
  - Rounds timestamps to nearest hour
  - Sums all values within each hour
  - Creates hourly records

**Aggregation logic:**
```r
# If 15-minute intervals detected:
# 00:00, 00:15, 00:30, 00:45 → aggregated to 00:00 (sum of all 4)
# 01:00, 01:15, 01:30, 01:45 → aggregated to 01:00 (sum of all 4)
```

**Example log output:**
```
Detected interval: 15 minutes
Aggregating 15-minute data to hourly
Aggregated 6,624 rows to 1,656 hourly rows
Average intervals per hour: 4.0
```

---

## Supported Intervals

### ✅ 15-Minute Intervals (Most Common)
- **Source**: PGE SmartMeter default interval
- **Processing**: Automatically aggregates 4 intervals → 1 hour
- **Method**: Sum of kWh values across the hour

**Example:**
```
Input (15-min):
  2025-03-20 00:00:00 → 0.04 kWh
  2025-03-20 00:15:00 → 0.15 kWh
  2025-03-20 00:30:00 → 0.07 kWh
  2025-03-20 00:45:00 → 0.09 kWh

Output (hourly):
  2025-03-20 00:00:00 → 0.35 kWh (sum)
```

### ✅ 30-Minute Intervals
- **Processing**: Automatically aggregates 2 intervals → 1 hour
- **Method**: Sum of kWh values

### ✅ Hourly Intervals
- **Processing**: No aggregation needed
- **Method**: Pass through as-is

### ✅ Daily Intervals
- **Processing**: Pass through (but Shiny app expects hourly)
- **Note**: Daily data will have limited visualization options

---

## Why Aggregate by Sum (Not Average)?

Energy consumption values are **cumulative** over the time period:
- A 15-min reading of **0.04 kWh** means "0.04 kWh consumed in those 15 minutes"
- An hourly reading should be the **total energy consumed that hour**
- Therefore, we **SUM** the 15-min intervals to get hourly total

**Example:**
```
Hour 1: 0.04 + 0.15 + 0.07 + 0.09 = 0.35 kWh (correct)
Hour 1: avg(0.04, 0.15, 0.07, 0.09) = 0.09 kWh (WRONG!)
```

---

## Handling Missing Data

### Missing Intervals
If some 15-minute intervals are missing:
```
Input:
  00:00 → 0.04 kWh
  00:15 → (missing)
  00:30 → 0.07 kWh
  00:45 → 0.09 kWh

Output:
  00:00 → 0.20 kWh (sum of 3 available values)
  Note: count = 3 (not 4)
```

The processing script logs: `Average intervals per hour: 3.5` if some are missing.

### Missing Hours
If entire hours are missing, they won't appear in the database (gaps in data).

The Shiny app handles this gracefully in visualizations.

---

## Manual Download Format

When you manually download Green Button data from PGE:

**Format:**
```csv
TYPE,DATE,START TIME,END TIME,USAGE (kWh),COST,NOTES
Electric usage,2025-03-20,00:00,00:14,0.04,$0.03,
Electric usage,2025-03-20,00:15,00:29,0.15,$0.03,
```

**Processing:** Use `scripts/convert_pge_download.R` which:
- Skips header rows
- Combines DATE + START TIME → dttm_start
- Uses USAGE (kWh) → value
- Auto-detects and aggregates to hourly

---

## API Data Format

From PGE Share My Data API (via `pgesmd_self_access`):

**Expected format:**
```python
{
  "timestamp": "2025-03-20T00:00:00",
  "consumption": 0.04,
  ...
}
```

The Python script automatically handles various column names:
- Timestamp: `timestamp`, `start_time`, `datetime`, `start`, `time`
- Value: `consumption`, `kwh`, `usage`, `value`, `energy`

---

## Validation

Both scripts validate:

### Python Script:
- ✅ Timestamp column exists
- ✅ Value column exists
- ✅ Values are numeric
- ✅ Timestamps are parseable

### R Script:
- ✅ Required columns present after processing
- ✅ Timestamps are POSIXct
- ✅ Values are numeric
- ✅ No duplicate timestamps after aggregation
- ✅ Data is sorted chronologically

---

## Troubleshooting

### "Detected interval: 0 minutes"
**Problem**: All timestamps are identical
**Solution**: Check API response, may indicate API error

### "Detected interval: 1440 minutes"
**Problem**: Daily data instead of hourly/15-min
**Impact**: Shiny app will have limited hourly visualizations
**Solution**: Check PGE API settings, request interval data

### "Aggregated 0 rows"
**Problem**: No valid data after filtering
**Solution**: Check for NaN values, timestamp parsing errors

### Very low "Average intervals per hour" (e.g., 1.2)
**Problem**: Many missing intervals
**Causes**:
- Meter communication issues
- Data collection problems
- API returning incomplete data
**Impact**: Hourly totals will be underestimated

---

## Future Enhancements

Potential improvements:

1. **Interpolation**: Fill missing intervals with interpolated values
2. **Quality flags**: Mark hours with incomplete data
3. **Multiple intervals**: Support mixed interval data in same file
4. **Downsampling**: Option to keep 15-min data (modify Shiny app)
5. **Smart aggregation**: Weight by actual interval length if irregular

---

## Configuration

If you want to **change aggregation behavior**:

### Keep sub-hourly data (don't aggregate):
Edit `scripts/process_pge_data.R`, line 56:
```r
# Change from:
if (median_diff_minutes < 60) {

# To:
if (FALSE) {  # Never aggregate
```

### Force aggregation even for hourly data:
```r
# Change from:
if (median_diff_minutes < 60) {

# To:
if (median_diff_minutes <= 60) {  # Aggregate all data
```

---

## Summary

✅ **Automatic detection** - No manual configuration needed
✅ **Smart aggregation** - Handles 15-min, 30-min, hourly data
✅ **Proper summing** - Energy values correctly totaled
✅ **Robust parsing** - Handles various API response formats
✅ **Validation** - Ensures data quality
✅ **Logging** - Clear visibility into what's happening

The pipeline **just works** regardless of what interval PGE provides! 🎯
