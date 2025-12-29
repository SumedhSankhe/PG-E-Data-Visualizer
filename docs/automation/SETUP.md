# PGE Data Automation Setup Guide

This guide will walk you through setting up fully automated PGE data fetching and Shiny app deployment.

## Overview

Once configured, this system will:
1. **Fetch data daily** from PGE's Share My Data API (3 AM UTC)
2. **Update SQLite database** with new energy usage data
3. **Automatically redeploy** your Shiny app with the latest data
4. **Zero manual work** required after initial setup

---

## Prerequisites

- PGE account with SmartMeter
- GitHub account (you already have this)
- shinyapps.io account (you already have this)
- 3-4 hours for initial setup

---

## Part 1: PGE Share My Data Registration

### Step 1: Register for Self-Access

1. Go to https://sharemydata.pge.com/
2. Click "Register" or "Sign Up"
3. Select **"Self-Access User"** as your user type
4. Fill in your information:
   - Name
   - Email
   - Organization: "Personal Use" or your name
   - Description: "Personal energy data analysis"

### Step 2: Obtain SSL Certificate (FREE)

You need a valid SSL certificate from a recognized provider. **Option A (Recommended): Let's Encrypt**

1. If you have a domain:
   - Use Certbot: https://certbot.eff.org/
   - Follow instructions for your domain
   - Certificate is FREE and auto-renews

2. If you don't have a domain:
   - Use ZeroSSL: https://zerossl.com/
   - Create free account
   - Generate 90-day certificate
   - Download certificate files

**Option B: Cloudflare Origin Certificate**

1. If you use Cloudflare:
   - Go to SSL/TLS → Origin Server
   - Create Certificate
   - Download PEM files
   - FREE, lasts 15 years

### Step 3: Set Up Webhook Endpoint (FREE)

PGE requires a notification URI to send data-ready notifications.

**Option A (Recommended): Supabase Edge Functions**

1. Sign up at https://supabase.com (FREE)
2. Create new project: "pge-webhook"
3. Go to Edge Functions
4. Create new function: `pge-notification`
5. Use this code:

```javascript
// supabase/functions/pge-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // Log the notification from PGE
  console.log('PGE Notification received:', await req.text())

  // Return success response
  return new Response(
    JSON.stringify({ status: 'received' }),
    {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    }
  )
})
```

6. Deploy the function
7. Copy the function URL (e.g., `https://xyz.supabase.co/functions/v1/pge-notification`)

**Option B: Simple webhook service**

- Use webhook.site (temporary, for testing only)
- Use RequestBin
- Use Pipedream (free tier)

### Step 4: Complete PGE Registration

1. Return to https://sharemydata.pge.com/
2. Provide required information:
   - **SSL Certificate**: Upload your certificate file (.pem or .crt)
   - **Notification URI**: Your webhook endpoint URL
   - **Redirect URI**: Same as notification URI (or `http://localhost:3000` for testing)
3. Submit registration
4. Wait for PGE approval (usually 1-3 business days)
5. You'll receive:
   - **Client ID**
   - **Client Secret**
   - Instructions for OAuth authorization

### Step 5: Complete OAuth Authorization

Once approved:

1. Follow PGE's OAuth 2.0 authorization flow
2. You'll be redirected to PGE's authorization page
3. Log in with your PGE account credentials
4. Authorize access to your meter data
5. You'll receive an **Access Token** (save this securely!)

**Note**: Access tokens may expire. If automation fails, you may need to re-authorize.

---

## Part 2: GitHub Configuration

### Step 6: Add PGE API Secrets

1. Go to your GitHub repository:
   https://github.com/SumedhSankhe/PG-E-Data-Visualizer

2. Navigate to: **Settings → Secrets and variables → Actions**

3. Click **"New repository secret"** and add these secrets:

| Secret Name | Value | Where to find it |
|-------------|-------|------------------|
| `PGE_CLIENT_ID` | Your Client ID | From PGE registration email |
| `PGE_CLIENT_SECRET` | Your Client Secret | From PGE registration email |
| `PGE_ACCESS_TOKEN` | Your OAuth Access Token | From OAuth authorization flow |
| `PGE_CERT_PATH` | (Optional) Path to cert | Leave empty if not using client cert auth |

### Step 7: Add shinyapps.io Deployment Secrets

The workflow needs to deploy your app automatically. Get your shinyapps.io credentials:

1. **Get Account Name**:
   - Go to https://www.shinyapps.io/admin/#/dashboard
   - Your account name is in the URL: `shinyapps.io/admin/#/dashboard/ACCOUNT_NAME`
   - Or look at top-right corner of dashboard

2. **Get Token & Secret**:
   - Go to https://www.shinyapps.io/admin/#/tokens
   - Click **"Show"** next to your token
   - Or click **"Add Token"** to create new one
   - Copy **Token** and **Secret**

3. **Add to GitHub Secrets**:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `SHINYAPPS_ACCOUNT` | Your account name | `ssankhe` |
| `SHINYAPPS_TOKEN` | Your token | `ABC123...` |
| `SHINYAPPS_SECRET` | Your secret | `xyz789...` |

---

## Part 3: Testing the Setup

### Step 8: Test Locally (Optional)

Before running in GitHub Actions, test the scripts locally:

**Test Python script:**
```bash
# Set environment variables
export PGE_CLIENT_ID="your_client_id"
export PGE_CLIENT_SECRET="your_client_secret"
export PGE_ACCESS_TOKEN="your_access_token"

# Install package
pip install pgesmd-self-access pandas

# Run script
python scripts/fetch_pge_data.py
```

**Test R processing:**
```bash
# Install packages
R -e "install.packages(c('data.table', 'logger', 'DBI', 'RSQLite'))"

# Run script
Rscript scripts/process_pge_data.R
```

### Step 9: Deploy Code to GitHub

1. **Commit all new files**:
```bash
git add .github/workflows/fetch-pge-data.yml
git add scripts/fetch_pge_data.py
git add scripts/process_pge_data.R
git add DESCRIPTION
git add global.R
git add loadData.R
git commit -m "Add automated PGE data fetching and deployment"
git push
```

2. **Verify workflow appears**:
   - Go to your repository on GitHub
   - Click "Actions" tab
   - You should see "Fetch PGE Data" workflow listed

### Step 10: Manual Test Run

1. Go to **Actions** tab on GitHub
2. Click "Fetch PGE Data" workflow
3. Click **"Run workflow"** button (top right)
4. Select branch: `main`
5. Click green **"Run workflow"** button
6. Watch the workflow execute (takes ~5-10 minutes)

**Check for success**:
- All steps should have green checkmarks ✓
- Look for commit: "Auto-update: PGE data fetch [date]"
- Check that `data/pge_meter_data.sqlite` was updated
- Verify app was redeployed to shinyapps.io

---

## Part 4: Monitoring & Maintenance

### Daily Operation

**No manual work needed!** The system runs automatically at 3 AM UTC daily.

### Monitoring

1. **GitHub Actions**:
   - Check https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions
   - Green checkmarks = success
   - Red X = failure (you'll get email notification)

2. **Email Notifications**:
   - GitHub sends emails on workflow failures
   - Check your GitHub notification settings

3. **shinyapps.io Dashboard**:
   - Check https://www.shinyapps.io/admin/#/dashboard
   - View app logs
   - Monitor active hours usage

4. **Workflow Logs**:
   - Click on any workflow run to see detailed logs
   - Check "Process and merge data" step for data statistics
   - Review "Deploy to shinyapps.io" step for deployment status

### Troubleshooting

**Workflow fails with "PGE API Authentication failed":**
- Access token may have expired
- Re-authorize through PGE Share My Data portal
- Update `PGE_ACCESS_TOKEN` secret in GitHub

**Workflow fails with "No data returned from API":**
- Check PGE Share My Data portal for API status
- Verify your meter is reporting data
- Check date range in Python script

**Deployment fails:**
- Verify shinyapps.io secrets are correct
- Check shinyapps.io account hasn't exceeded free tier limits (25 active hours/month)
- Review deployment logs in workflow

**No new data appearing in app:**
- Check if workflow ran successfully
- Verify database file was updated (check commit history)
- Check app logs on shinyapps.io
- Try manual app restart on shinyapps.io dashboard

### Checking Data

**Via GitHub**:
- Look at commit history for "Auto-update" commits
- Download `data/pge_meter_data.sqlite` to inspect locally

**Via R (locally)**:
```r
library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "data/pge_meter_data.sqlite")

# Check row count
dbGetQuery(con, "SELECT COUNT(*) as count FROM meter_data")

# Check date range
dbGetQuery(con, "SELECT MIN(dttm_start) as min, MAX(dttm_start) as max FROM meter_data")

# View recent data
dbGetQuery(con, "SELECT * FROM meter_data ORDER BY dttm_start DESC LIMIT 10")

dbDisconnect(con)
```

---

## Backup & Recovery

### Automatic Backups

- GitHub maintains complete commit history of database
- Every update creates a new commit
- RDS backup file also created: `data/meterData.rds`

### Manual Backup

```bash
# Download database from GitHub
curl -L https://github.com/SumedhSankhe/PG-E-Data-Visualizer/raw/main/data/pge_meter_data.sqlite -o backup_$(date +%Y%m%d).sqlite

# Or via git
git pull
cp data/pge_meter_data.sqlite ~/backups/pge_$(date +%Y%m%d).sqlite
```

### Restore from Backup

If database gets corrupted:

1. Find a good commit in GitHub history
2. Download that version of the database
3. Commit it to replace current version
4. Push to GitHub

---

## Cost Summary

- **PGE Share My Data API**: FREE
- **SSL Certificate** (Let's Encrypt/ZeroSSL): FREE
- **Supabase** (webhook): FREE (500K requests/month)
- **GitHub Actions**: FREE (2,000 minutes/month)
- **shinyapps.io**: FREE tier (25 active hours/month)
- **Total**: $0/month

---

## Support & Resources

**PGE Share My Data**:
- Portal: https://sharemydata.pge.com/
- Documentation: https://www.pge.com/en/save-energy-and-money/energy-usage-and-tips/understand-my-usage/share-my-data.html
- Support: Contact PGE customer service

**pgesmd_self_access Package**:
- GitHub: https://github.com/JPHutchins/pgesmd_self_access
- PyPI: https://pypi.org/project/pgesmd-self-access/
- Issues: Report on GitHub

**GitHub Actions**:
- Docs: https://docs.github.com/en/actions
- Secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets

**shinyapps.io**:
- Dashboard: https://www.shinyapps.io/admin/
- Docs: https://docs.posit.co/shinyapps.io/
- Support: support@posit.co

---

## Success Checklist

After completing setup, you should have:

- ✅ PGE Share My Data account approved
- ✅ OAuth access token obtained
- ✅ SSL certificate configured
- ✅ Webhook endpoint set up
- ✅ GitHub secrets configured (7 total)
- ✅ GitHub Actions workflow running successfully
- ✅ SQLite database being updated daily
- ✅ Shiny app auto-deploying with new data
- ✅ Monitoring in place (email notifications)
- ✅ Zero daily manual work!

**Congratulations!** Your PGE energy data visualization is now fully automated! 🎉
