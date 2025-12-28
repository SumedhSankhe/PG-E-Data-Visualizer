@echo off
REM Verify Shiny App Data Loading
REM Run this to test that your processed PGE data is ready for the Shiny app

cd /d "%~dp0"
echo Running data verification...
echo.

R CMD BATCH --vanilla verify_app_data.R verify_app_data.Rout

echo.
echo ========================================
echo Verification complete!
echo ========================================
echo.
echo Check verify_app_data.Rout for detailed results
echo.

type verify_app_data.Rout

pause
