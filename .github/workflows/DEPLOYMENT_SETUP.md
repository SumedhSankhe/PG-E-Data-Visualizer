# Deployment Automation Setup

This guide explains how to set up automatic deployment to shinyapps.io.

---

## Overview

Two workflows handle deployment:

1. **`deploy-shinyapps.yml`** - Deploys when code is merged to master
2. **`fetch-pge-data.yml`** - Fetches PGE data daily and deploys updated app

---

## Required GitHub Secrets

You need to add these secrets to your GitHub repository for deployment to work.

### How to Get Your shinyapps.io Credentials

1. **Log in to shinyapps.io**: https://www.shinyapps.io/
2. **Go to Account Settings**: Click your name → Account → Tokens
3. **Show Token**: Click "Show" on your token
4. **Copy the credentials** (you'll see three values)

### Add Secrets to GitHub

1. Go to your repo: https://github.com/SumedhSankhe/PG-E-Data-Visualizer
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Click **"New repository secret"**
4. Add each of these secrets:

| Secret Name | Description | Example |
|------------|-------------|---------|
| `SHINYAPPS_ACCOUNT` | Your shinyapps.io account name | `ssankhe` |
| `SHINYAPPS_TOKEN` | Your shinyapps.io token | `ABCD1234...` |
| `SHINYAPPS_SECRET` | Your shinyapps.io secret | `xyz789...` |

---

## Workflow 1: Deploy on Master Merge

**File**: `.github/workflows/deploy-shinyapps.yml`

**Triggers when**:
- Code is pushed to `master` or `main` branch
- Manual trigger via GitHub Actions UI

**What it does**:
1. Checks out code
2. Installs R and dependencies
3. Authorizes with shinyapps.io
4. Deploys the app
5. Shows deployment URL

**Example usage**:
- Merge a PR → Automatic deployment
- Or manually trigger: Actions → Deploy to shinyapps.io → Run workflow

---

## Workflow 2: Deploy After Data Update

**File**: `.github/workflows/fetch-pge-data.yml`

**Triggers when**:
- Daily at 3 AM UTC
- Manual trigger via GitHub Actions UI

**What it does**:
1. Fetches latest PGE data from API
2. Processes to SQLite database
3. Commits updated database to GitHub
4. **Deploys updated app to shinyapps.io**

This ensures your live app always has the latest data!

---

## Testing Deployment

### Test Locally First

Before relying on automation, test deployment locally:

```r
# Install rsconnect if needed
install.packages("rsconnect")

# Set your credentials (one-time setup)
rsconnect::setAccountInfo(
  name = "ssankhe",  # Your account name
  token = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)

# Deploy
rsconnect::deployApp(
  appName = "PG-E-Data-Visualizer",
  forceUpdate = TRUE
)
```

### Test Workflow Manually

After adding secrets:

1. Go to **Actions** tab
2. Select **"Deploy to shinyapps.io"**
3. Click **"Run workflow"**
4. Select branch: `master`
5. Click **"Run workflow"**
6. Watch the logs

---

## Deployment Flow

### On PR Merge to Master

```
PR merged to master
    ↓
deploy-shinyapps.yml triggered
    ↓
Install dependencies
    ↓
Authorize with shinyapps.io
    ↓
Deploy app
    ↓
✅ Live app updated!
```

### Daily Data Update

```
3 AM UTC (GitHub Actions cron)
    ↓
Fetch PGE API data
    ↓
Process to SQLite
    ↓
Commit to GitHub
    ↓
Deploy updated app to shinyapps.io
    ↓
✅ Live app has latest data!
```

---

## Troubleshooting

### "Error: Unable to connect to service"

**Problem**: Invalid credentials or account name

**Solution**:
1. Verify secrets are correct (check for typos)
2. Token hasn't expired (get new one from shinyapps.io)
3. Account name matches exactly

### "Error: Application name already in use"

**Problem**: App name exists but you don't own it

**Solution**:
- Change `appName` in workflow to match your existing app
- Or deploy manually first to create the app

### "Error: Account limit exceeded"

**Problem**: Free tier limits reached

**Solution**:
- Delete unused apps on shinyapps.io
- Or upgrade to a paid plan

### "Error: File size too large"

**Problem**: Database file too big for deployment

**Solution**:
- Add `data/pge_meter_data.sqlite` to `.rsconnect-ignore`
- App will fall back to RDS file

---

## shinyapps.io Free Tier Limits

Be aware of free tier limits:
- **25 active hours/month** - App shuts down after 25 hours of usage
- **5 applications** - Maximum number of apps
- **1 GB memory** - Per application

If you hit limits:
- Upgrade to paid tier ($9/month for 100 hours)
- Or reduce app usage

---

## Monitoring Deployments

### GitHub Actions

View deployment status:
- Go to **Actions** tab
- Look for ✅ (success) or ❌ (failure)
- Click on run to see detailed logs

### shinyapps.io Dashboard

View app status:
- Go to https://www.shinyapps.io/admin/
- Check:
  - Active hours used
  - Last deployment time
  - App logs and metrics

---

## Disabling Auto-Deployment

If you want to disable automatic deployment:

### Disable on Master Merge

Edit `.github/workflows/deploy-shinyapps.yml`:
```yaml
on:
  # push:  # Comment out this section
  #   branches:
  #     - master
  workflow_dispatch:  # Keep manual trigger
```

### Disable on Data Update

Edit `.github/workflows/fetch-pge-data.yml` and remove the deployment step.

---

## Best Practices

### 1. Test Before Deploying
Always test locally before pushing to master

### 2. Monitor Usage
Check shinyapps.io dashboard weekly for active hours

### 3. Version Control
Use git tags for major releases:
```bash
git tag -a v1.0.0 -m "Initial automated deployment"
git push --tags
```

### 4. Rollback if Needed
If deployment fails, revert:
```bash
git revert HEAD
git push
```
This will trigger redeployment of previous version.

### 5. Secrets Rotation
Rotate shinyapps.io tokens every 6 months for security

---

## Summary

✅ **Setup**: Add 3 GitHub secrets (account, token, secret)
✅ **Deploy on merge**: Automatic when PR merged to master
✅ **Deploy on data update**: Automatic when PGE data refreshes
✅ **Monitor**: GitHub Actions + shinyapps.io dashboard
✅ **Cost**: $0/month (within free tier limits)

---

## Next Steps

1. ✅ Add GitHub secrets (SHINYAPPS_ACCOUNT, SHINYAPPS_TOKEN, SHINYAPPS_SECRET)
2. ✅ Merge this PR to master (will trigger first deployment)
3. ✅ Verify deployment succeeded in Actions tab
4. ✅ Check app loads correctly at https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/
5. ✅ Test manual trigger to verify automation works
6. ⏳ Wait for PGE API approval, then test data update workflow

---

Last updated: December 28, 2024
