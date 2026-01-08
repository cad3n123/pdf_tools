@echo off
echo ==============================================
echo      FORCE UNBLOCK & EXTRACT TOOL
echo ==============================================
echo.

if "%~1"=="" (
    echo DRAG AND DROP the stubborn ZIP file onto this script file.
    echo.
    pause
    exit /b
)

set "ZIPFILE=%~1"
set "OUTDIR=%~dpn1_extracted"

echo Target: "%ZIPFILE%"
echo.

echo 1. Stripping Security Tags (Unblocking)...
powershell -NoProfile -Command "Unblock-File -Path '%ZIPFILE%'"

echo 2. Forcing Extraction via PowerShell...
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%ZIPFILE%' -DestinationPath '%OUTDIR%' -Force"

echo.
echo ==============================================
echo SUCCESS! 
echo Files are in: "%OUTDIR%"
echo ==============================================
start "" "%OUTDIR%"
pause