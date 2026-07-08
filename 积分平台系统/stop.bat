@echo off
chcp 65001 >nul
setlocal

REM ============================================================
REM  Points Platform stop script
REM  - Kill via PID file
REM  - Kill via port scan
REM  - Kill via window title (fallback)
REM ============================================================

cd /d "%~dp0"

set "PORT=5000"
set "PID_FILE=%~dp0instance\app.pid"

echo.
echo ============================================================
echo   Points Platform - Stopping...
echo ============================================================
echo.

set "KILLED=0"

REM --- Method 1: PID file ---
if exist "%PID_FILE%" (
    for /f "usebackq delims=" %%p in ("%PID_FILE%") do (
        set "PID=%%p"
    )
    if defined PID (
        echo [1/3] Killing PID %PID% ...
        taskkill /F /PID %PID% >nul 2>nul
        if not errorlevel 1 set "KILLED=1"
    )
    del /q "%PID_FILE%" >nul 2>nul
)

REM --- Method 2: Port scan ---
echo [2/3] Scanning port %PORT% ...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
    echo       killing PID %%p
    taskkill /F /PID %%p >nul 2>nul
    set "KILLED=1"
)

REM --- Method 3: window title ---
echo [3/3] Cleaning window PointsPlatformServer ...
taskkill /F /FI "WINDOWTITLE eq PointsPlatformServer*" >nul 2>nul

echo.
if "%KILLED%"=="1" (
    echo   STOPPED.
) else (
    echo   No running service found.
)
echo.
pause
endlocal
