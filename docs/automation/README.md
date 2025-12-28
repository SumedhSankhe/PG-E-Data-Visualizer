# PGE Data Automation Documentation

This directory contains all documentation for the PGE data automation system.

## 📚 Documentation Index

### Quick Start
- **[STATUS.md](STATUS.md)** - Current project status, next steps, and quick reference
- **[TEST_SHINY_APP.md](TEST_SHINY_APP.md)** - How to test your Shiny app with real PGE data

### Setup & Configuration
- **[SETUP.md](SETUP.md)** - Complete setup guide for PGE Share My Data API
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Architecture overview and implementation details

### Technical Details
- **[DATA_INTERVALS.md](DATA_INTERVALS.md)** - How automatic interval detection and aggregation works
- **[LOCAL_TESTING.md](LOCAL_TESTING.md)** - Testing the automation pipeline locally

## 🎯 Where to Start

### If you want to...

**Test the Shiny app with your processed data:**
→ Read [TEST_SHINY_APP.md](TEST_SHINY_APP.md)

**Check current project status:**
→ Read [STATUS.md](STATUS.md)

**Set up PGE API automation:**
→ Read [SETUP.md](SETUP.md)

**Understand how data processing works:**
→ Read [DATA_INTERVALS.md](DATA_INTERVALS.md)

**Test automation scripts locally:**
→ Read [LOCAL_TESTING.md](LOCAL_TESTING.md)

**See architecture and what was implemented:**
→ Read [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

## 📁 Related Directories

- **`../../scripts/automation/`** - PGE data automation scripts
- **`../../scripts/utils/`** - Testing and verification utilities
- **`../../data/`** - Processed energy data files
- **`../../.github/workflows/`** - GitHub Actions automation

## 🔄 Automation Workflow

```
Daily at 3 AM UTC (GitHub Actions)
    ↓
fetch_pge_data.py - Fetch from PGE API
    ↓
process_pge_data.R - Process to SQLite
    ↓
Commit to GitHub
    ↓
Deploy to shinyapps.io
```

## 📊 Current Status

✅ **Data Processing**: Complete
✅ **Shiny App Integration**: Complete
⏳ **PGE API Access**: Waiting for approval
⏳ **Full Automation**: Ready when PGE approves

Last updated: December 28, 2024
