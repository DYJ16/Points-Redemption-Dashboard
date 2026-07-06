@echo off
chcp 65001 > nul
cd /d "%~dp0"
echo ========================================
echo  释放端口 5000 (停止 Flask 服务)
echo ========================================
echo.
set PORT=5000
set FOUND=0
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
    echo [停止] PID %%P (端口 %PORT%)
    taskkill /F /PID %%P > nul 2>&1
    set FOUND=1
)
if "%FOUND%"=="0" (
    echo [信息] 端口 %PORT% 没有正在运行的服务
) else (
    echo [完成] 端口 %PORT% 已释放
)
echo.
echo [备用] 关闭所有 python 进程...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq 积分平台BI仪表盘*" 2>nul
echo 完成。
timeout /t 3 > nul
