@echo off
REM Process PGE Downloaded Data
REM Converts PGE Green Button CSV to Shiny app format

echo ========================================
echo Processing Your PGE Data
echo ========================================
echo.

REM Run the conversion script
"C:\Program Files\R\R-4.4.0\bin\Rscript.exe" scripts\convert_pge_download.R

echo.
echo Done! You can now run the Shiny app.
pause
