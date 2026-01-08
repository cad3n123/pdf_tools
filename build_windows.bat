@echo off
setlocal enabledelayedexpansion

echo ==== Master PDF Tool Builder (Windows) ====

REM Where to output the final .exe
set "STARTDIR=%cd%"

REM Check if the master python script exists
if not exist "master_pdf_tool.py" (
    echo ERROR: master_pdf_tool.py not found in this folder!
    echo Please save the Python code provided into this folder as "master_pdf_tool.py"
    pause
    exit /b
)

REM Python.org local install path fallback
set "PYTHON_INSTALL_DIR=%LocalAppData%\Programs\PDFMasterPython"
set "FALLBACK_PYTHON_EXE=%PYTHON_INSTALL_DIR%\python.exe"
set "USE_PYTHON="

REM Step 1: Look for an existing non-Anaconda, non-MicrosoftStore Python
for /f "delims=" %%P in ('where python 2^>nul') do (
    echo Found Python at: %%P
    echo %%P | find /I "anaconda" >nul
    if not errorlevel 1 (
        echo Skipping Anaconda Python...
    ) else (
        echo %%P | find /I "WindowsApps" >nul
        if not errorlevel 1 (
            echo Skipping Microsoft Store placeholder...
        ) else (
            set "USE_PYTHON=%%P"
        )
    )
    if defined USE_PYTHON goto :found_python
)

REM Step 2: Install Python from python.org if needed
echo No clean Python found. Installing standalone copy...
mkdir "%PYTHON_INSTALL_DIR%"
curl -o python-installer.exe https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
start /wait python-installer.exe /quiet InstallAllUsers=0 TargetDir="%PYTHON_INSTALL_DIR%" Include_pip=1 PrependPath=0
del python-installer.exe
set "USE_PYTHON=%FALLBACK_PYTHON_EXE%"

:found_python
echo Using Python: %USE_PYTHON%

REM Step 3: Create temp folder and venv
set "TEMPDIR=%STARTDIR%\master_pdf_build_temp"
if exist "%TEMPDIR%" rmdir /s /q "%TEMPDIR%"
mkdir "%TEMPDIR%"
cd /d "%TEMPDIR%"

"%USE_PYTHON%" -m venv venv
call venv\Scripts\activate.bat

REM Step 4: Install packages (PyQt5, PyPDF2, PyMuPDF, PyInstaller)
echo Installing dependencies...
pip install --upgrade pip
pip install pyinstaller PyQt5 PyPDF2 pymupdf

REM Step 5: Copy script to temp dir for building
copy "%STARTDIR%\master_pdf_tool.py" .

REM Step 6: Build with onefile
echo Building .exe...
pyinstaller --onefile --windowed --name "MasterPDFTool" ^
  --exclude-module PyQt5.QtWebEngine ^
  --exclude-module PyQt5.QtMultimedia ^
  --exclude-module PyQt5.QtSvg ^
  --exclude-module PyQt5.QtNetwork ^
  master_pdf_tool.py

REM Step 7: Move output and clean up
move /Y dist\MasterPDFTool.exe "%STARTDIR%\MasterPDFTool.exe"
cd /d "%STARTDIR%"
rmdir /s /q "%TEMPDIR%"

echo.
echo ==== Build Complete! ====
echo You can now run MasterPDFTool.exe
pause