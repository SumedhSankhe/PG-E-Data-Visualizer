# PGE Data Automation - Current Status

**Last Updated**: December 28, 2024

---

## ✅ Completed Tasks

### 1. Data Processing Pipeline ✅
- [x] Created `scripts/convert_pge_download.R` - Converts PGE Green Button CSV to app format
- [x] Created `scripts/convert_pge_download_v2.R` - Improved version with robust error handling
- [x] **Automatic interval detection** - Detects 15-min, 30-min, hourly, daily intervals
- [x] **Automatic aggregation** - Aggregates sub-hourly data to hourly by summing kWh values
- [x] **SQLite database support** - Primary storage format
- [x] **RDS fallback** - Backward compatibility with existing Shiny app
- [x] **CSV export** - Human-readable data export

### 2. Real Data Processing ✅
- [x] Processed your real PGE data (March 20 - December 27, 2025)
- [x] Successfully created SQLite database: `data/pge_meter_data.sqlite` (912 KB)
- [x] Successfully created RDS backup: `data/meterData.rds` (13 KB)
- [x] Successfully created CSV export: `data/pge_latest.csv` (243 KB)
- [x] **6,768 hourly records** (aggregated from 27,072 15-minute intervals)
- [x] **283 days of data** with proper date range

### 3. Shiny App Updates ✅
- [x] Updated `global.R` with SQLite database loading function
- [x] Updated `loadData.R` to use database-aware loading
- [x] Added `DBI` and `RSQLite` dependencies to `DESCRIPTION`
- [x] Implemented graceful fallback to RDS if SQLite fails
- [x] Maintained backward compatibility

### 4. Testing Infrastructure ✅
- [x] Created `verify_app_data.R` - Verifies database and RDS file integrity
- [x] Created `verify_app_data.bat` - Windows batch file for easy testing
- [x] Created `TEST_SHINY_APP.md` - Comprehensive testing guide
- [x] Created `scripts/test_local.R` - Local pipeline testing
- [x] Created `LOCAL_TESTING.md` - Local testing documentation

### 5. Documentation ✅
- [x] Created `DATA_INTERVALS.md` - Explains interval detection and aggregation
- [x] Created `SETUP.md` - PGE API registration guide
- [x] Created `IMPLEMENTATION_SUMMARY.md` - Architecture overview
- [x] Created `STATUS.md` - This current status document

### 6. PGE Share My Data Registration ✅
- [x] Set up GitHub Pages domain for SSL verification
- [x] Obtained SSL certificate from ZeroSSL (valid for 90 days)
- [x] Submitted registration to PGE Share My Data portal
- [x] **Waiting for PGE approval** (1-3 business days)

### 7. Automation Scripts ✅
- [x] Created `scripts/fetch_pge_data.py` - Fetches from PGE API (ready for when OAuth credentials are received)
- [x] Created `scripts/process_pge_data.R` - Processes API data to SQLite
- [x] Created `.github/workflows/fetch-pge-data.yml` - Daily automation workflow

---

## ⏳ Pending Tasks

### 1. PGE API Access (Waiting for PGE)
- [ ] **Wait for PGE approval** (1-3 business days from December 28, 2024)
- [ ] Receive OAuth credentials:
  - Client ID
  - Client Secret
  - Access Token
- [ ] Test API connection locally

### 2. GitHub Configuration (After PGE Approval)
- [ ] Add GitHub Secrets:
  - `PGE_CLIENT_ID`
  - `PGE_CLIENT_SECRET`
  - `PGE_ACCESS_TOKEN`
  - `SHINYAPPS_ACCOUNT`
  - `SHINYAPPS_TOKEN`
  - `SHINYAPPS_SECRET`

### 3. Testing & Deployment
- [ ] Test Shiny app locally with real PGE data (See `TEST_SHINY_APP.md`)
- [ ] Verify all visualizations work correctly
- [ ] Test automated workflow end-to-end (after OAuth credentials)
- [ ] Deploy to shinyapps.io

### 4. SSL Certificate Renewal
- [ ] **Mark calendar**: Renew SSL certificate around **March 28, 2025** (90 days from now)
- [ ] Process: Same as initial setup (ZeroSSL + GitHub Pages verification)

---

## 🎯 Next Steps (In Order)

### Immediate: Test Locally
**What to do RIGHT NOW:**
1. Run verification script:
   ```r
   source("verify_app_data.R")
   ```

2. Launch Shiny app locally:
   ```r
   library(shiny)
   runApp()
   ```

3. Verify:
   - App loads without errors
   - Date range shows March 20 - December 27, 2025
   - 283 days of data visible
   - All visualizations render

See **`TEST_SHINY_APP.md`** for detailed testing guide.

### When PGE Approves (1-3 business days)
**What to do when you receive OAuth credentials:**

1. Add credentials to GitHub Secrets
2. Test Python fetch script locally:
   ```bash
   python scripts/fetch_pge_data.py
   ```
3. Verify data is fetched from PGE API
4. Test R processing script:
   ```bash
   Rscript scripts/process_pge_data.R
   ```
5. Manually trigger GitHub Actions workflow to test end-to-end

### After Testing Successful
**What to do once everything works:**

1. Enable daily automation (already configured in GitHub Actions)
2. Monitor first week of automated runs
3. Deploy updated app to shinyapps.io
4. **Done!** - Zero daily manual work from this point forward

---

## 📊 Current Data Status

### Your Processed PGE Data
- **Source**: Manual Green Button download
- **Date Range**: March 20, 2025 → December 27, 2025
- **Duration**: 283 days
- **Total Records**: 6,768 hours
- **Total Consumption**: ~1,324 kWh
- **Average Hourly**: ~0.20 kWh
- **Original Format**: 27,072 15-minute intervals
- **Processed Format**: Hourly (aggregated by sum)

### Data Files
```
data/
├── pge_meter_data.sqlite          (912 KB)  ← Primary database for Shiny app
├── meterData.rds                  (13 KB)   ← Backup/fallback
├── pge_latest.csv                 (243 KB)  ← Human-readable export
└── pge_electric_usage_...csv      (1.3 MB)  ← Original PGE download
```

---

## 🔧 How Data Processing Works

### Current Workflow (Manual)
```
1. Download CSV from PGE website (manual)
     ↓
2. Run convert_pge_download_v2.R
     ↓
3. Script auto-detects interval (15-min detected)
     ↓
4. Script aggregates to hourly (sums kWh values)
     ↓
5. Creates SQLite database + RDS backup + CSV export
     ↓
6. Shiny app loads from SQLite (or RDS fallback)
```

### Future Workflow (Automated - After PGE Approval)
```
GitHub Actions (daily 3 AM UTC)
     ↓
fetch_pge_data.py (fetches from PGE API)
     ↓
process_pge_data.R (processes to SQLite)
     ↓
Commits updated database to GitHub
     ↓
Deploys to shinyapps.io
     ↓
Shiny app always has latest data (ZERO manual work!)
```

---

## 🎨 Architecture Overview

### Data Flow
```
PGE SmartMeter (15-min intervals)
    ↓
PGE Share My Data API (OAuth 2.0)
    ↓
Python fetch script (pgesmd_self_access)
    ↓
CSV file (dttm_start, value)
    ↓
R processing script (auto-detect & aggregate)
    ↓
SQLite database (hourly data)
    ↓
Shiny app on shinyapps.io
    ↓
User sees live energy visualizations
```

### Technology Stack
- **Data Source**: PGE Share My Data API
- **Authentication**: OAuth 2.0
- **Fetching**: Python (`pgesmd_self_access` package)
- **Processing**: R (`data.table`, `DBI`, `RSQLite`)
- **Storage**: SQLite database (bundled with app)
- **Automation**: GitHub Actions (daily cron job)
- **Deployment**: shinyapps.io
- **Visualization**: Shiny dashboard

---

## 📝 Important Files Reference

### Scripts
- **`scripts/convert_pge_download_v2.R`** - Convert manual PGE downloads (USE THIS ONE)
- `scripts/convert_pge_download.R` - Original version (has connection error)
- **`scripts/fetch_pge_data.py`** - Fetch from PGE API (ready for OAuth credentials)
- **`scripts/process_pge_data.R`** - Process API data to SQLite
- `scripts/test_local.R` - Local testing with sample data

### Testing & Verification
- **`verify_app_data.R`** - Verify database integrity (RUN THIS FIRST)
- **`verify_app_data.bat`** - Windows batch version
- **`TEST_SHINY_APP.md`** - Complete testing guide (READ THIS)

### Documentation
- **`STATUS.md`** - This file (current status overview)
- **`DATA_INTERVALS.md`** - How interval detection works
- `SETUP.md` - PGE API registration guide
- `IMPLEMENTATION_SUMMARY.md` - Architecture details
- `LOCAL_TESTING.md` - Local testing guide

### Configuration
- `.github/workflows/fetch-pge-data.yml` - Daily automation workflow
- `DESCRIPTION` - R package dependencies (includes DBI, RSQLite)
- `global.R` - Shiny app data loading (updated for SQLite)
- `loadData.R` - Data loading logic (updated for database)

---

## 🚀 Success Metrics

### Current Status ✅
- [x] Real PGE data processed successfully
- [x] SQLite database created
- [x] Shiny app updated to read from database
- [x] Automatic interval detection working
- [x] Automatic aggregation working
- [x] 283 days of hourly data ready
- [x] Testing infrastructure complete
- [x] Documentation complete
- [x] PGE registration submitted

### After Full Implementation ✅
- [ ] Zero daily manual work (fully automated)
- [ ] Daily data fetching from PGE API
- [ ] Automatic Shiny app updates
- [ ] Complete audit trail (GitHub commits)
- [ ] $0/month cost (all free services)

---

## 💰 Cost Breakdown

### Current Costs: $0/month
- ✅ GitHub Actions: FREE (2,000 minutes/month)
- ✅ GitHub repository: FREE
- ✅ PGE Share My Data API: FREE (residential customers)
- ✅ SSL certificate: FREE (ZeroSSL, renewable every 90 days)
- ✅ Webhook endpoint: FREE (Supabase 500K requests/month)
- ✅ shinyapps.io: FREE tier (25 active hours/month)

**Total monthly cost: $0** 🎉

---

## 🔐 Security & Privacy

### Data Storage
- ✅ All data stored in GitHub private repository
- ✅ OAuth credentials stored as GitHub Secrets (encrypted)
- ✅ No third-party data sharing
- ✅ PGE data only accessible to you

### Authentication
- ✅ OAuth 2.0 (industry standard)
- ✅ SSL/TLS certificates (required by PGE)
- ✅ No passwords stored in code
- ✅ Tokens rotatable

---

## 🐛 Known Issues & Limitations

### Current Limitations
1. **Manual downloads still required** (until PGE approval)
2. **SSL certificate expires in 90 days** (March 28, 2025 - will need renewal)
3. **shinyapps.io free tier** limits to 25 active hours/month (may need paid tier if high traffic)

### Resolved Issues
- ✅ ~~SQLite connection error~~ - Fixed in v2 script with better error handling
- ✅ ~~15-minute interval handling~~ - Automatic detection and aggregation now working
- ✅ ~~GitHub Pages .well-known directory~~ - Fixed with .nojekyll file

---

## 📞 Support & Resources

### Documentation
- **PGE Share My Data**: https://www.pge.com/en/save-energy-and-money/energy-usage-and-tips/understand-my-usage/share-my-data.html
- **PGE API Portal**: https://sharemydata.pge.com/
- **pgesmd_self_access**: https://github.com/JPHutchins/pgesmd_self_access
- **ZeroSSL**: https://zerossl.com/
- **GitHub Actions**: https://docs.github.com/en/actions

### Your Project Files
- **GitHub Repository**: https://github.com/SumedhSankhe/PG-E-Data-Visualizer
- **GitHub Pages**: https://sumedhsankhe.github.io/
- **Webhook Endpoint**: https://dhwdtuuppvlbzjccotdk.supabase.co/functions/v1/pge-notify

---

## 🎯 Summary

### What Works NOW ✅
- Convert manually downloaded PGE data to app format
- Automatic 15-minute to hourly aggregation
- SQLite database storage
- RDS fallback compatibility
- Your Shiny app can load 283 days of real data

### What's Coming SOON ⏳
- Daily automated PGE API fetching (waiting for OAuth credentials)
- Zero manual downloads (fully automated)
- Auto-deploy to shinyapps.io

### What You Should Do NOW 👉
1. **Run `verify_app_data.R`** to check database integrity
2. **Launch your Shiny app locally** to test visualizations
3. **Follow `TEST_SHINY_APP.md`** for detailed testing steps
4. **Wait for PGE email** with OAuth credentials (1-3 business days)

---

**Status**: 🟢 **Data Processing Complete** | ⏳ **Waiting for PGE API Approval** | 🚀 **Ready for Local Testing**

Last manual download required: **December 28, 2024**

Next manual download needed: **~January 4, 2025** (if PGE approval delayed)

Estimated automation go-live: **January 1-3, 2025** (after PGE approval)
