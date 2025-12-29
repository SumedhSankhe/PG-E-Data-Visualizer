@echo off
REM Local Testing Script for PGE Data Automation
REM Run this from the project root directory

echo ========================================
echo PGE Data Automation - Local Test
echo ========================================
echo.

REM Run the R test script
"C:\Program Files\R\R-4.4.0\bin\Rscript.exe" scripts\test_local.R

echo.
echo Test complete!
pause
