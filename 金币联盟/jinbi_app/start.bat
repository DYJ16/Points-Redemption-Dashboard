@echo off
chcp 65001 >nul
setlocal

REM ============================================================
REM  JinbiUnion startup script
REM  - Detect Python
REM  - Create venv and install deps on first run
REM  - Launch Flask in background, write PID file
REM  - Auto-open browser
REM ============================================================

cd /d "%~dp0"

set "PORT=5000"
set "PID_FILE=%~dp0instance\app.pid"
set "VENV_DIR=%~dp0.venv"

if not exist "instance" mkdir "instance"

echo.
echo ============================================================
echo   JinbiUnion - Starting...
echo ============================================================
echo.

REM --- 1. Python check ---
where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python not found. Install Python 3.8+ first.
    echo          https://www.python.org/downloads/
    pause
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PY_VERSION=%%i"
echo [1/4] Python: %PY_VERSION%

REM --- 2. Virtualenv ---
if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo [2/4] Creating virtualenv .venv ...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create venv
        pause
        exit /b 1
    )
) else (
    echo [2/4] venv exists
)

set "PY_EXE=%VENV_DIR%\Scripts\python.exe"

REM --- 3. Dependencies ---
echo [3/4] Installing dependencies ...
"%PY_EXE%" -m pip install --quiet --disable-pip-version-check -r requirements.txt
if errorlevel 1 (
    echo [ERROR] pip install failed
    pause
    exit /b 1
)
echo       deps ready

REM --- 4. Kill old process on port ---
netstat -ano | findstr ":%PORT% " | findstr "LISTENING" >nul 2>nul
if not errorlevel 1 (
    echo [WARN] port %PORT% busy, killing old process ...
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
        taskkill /F /PID %%p >nul 2>nul
    )
    timeout /t 2 /nobreak >nul
)

REM --- 5. Launch Flask in background ---
echo [4/4] Launching server ...
start "JinbiUnionServer" /MIN "%PY_EXE%" app.py >nul 2>&1

REM --- 6. Wait for port and write PID file ---
set /a WAIT=0
:wait_loop
netstat -ano | findstr ":%PORT% " | findstr "LISTENING" >nul 2>nul
if not errorlevel 1 goto :port_ready
set /a WAIT+=1
if %WAIT% GEQ 20 (
    echo [ERROR] server start timeout
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto :wait_loop
:port_ready
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
    echo %%p > "%PID_FILE%"
    goto :pid_written
)
:pid_written

echo.
echo ============================================================
echo   STARTED.
echo   URL:    http://127.0.0.1:%PORT%/
echo   PID:    %PID_FILE%
echo   STOP:   double-click stop.bat
echo ============================================================
echo.

REM --- 7. Open browser (3s delay) ---
timeout /t 3 /nobreak >nul
start "" "http://127.0.0.1:%PORT%/"

endlocal