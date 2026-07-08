@echo off
chcp 65001 > nul
cd /d "%~dp0"

set FLASK_PORT_VALUE=5002
if exist .env (
    for /f "tokens=1,* delims==" %%A in (.env) do (
        if /I "%%A"=="FLASK_PORT" set FLASK_PORT_VALUE=%%B
    )
)

echo ========================================
echo  释放端口 %FLASK_PORT_VALUE% (停止 Flask 服务)
echo ========================================
echo.

set FOUND=0
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":%FLASK_PORT_VALUE% " ^| findstr "LISTENING"') do (
    echo [停止] PID %%P (端口 %FLASK_PORT_VALUE%)
    taskkill /F /PID %%P > nul 2>&1
    set FOUND=1
)

if "%FOUND%"=="0" (
    echo [信息] 端口 %FLASK_PORT_VALUE% 没有正在运行的服务
) else (
    echo [完成] 端口 %FLASK_PORT_VALUE% 已释放
)

timeout /t 3 > nul
