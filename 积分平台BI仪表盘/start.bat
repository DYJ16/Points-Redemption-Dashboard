@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo ========================================
echo  积分平台 BI 仪表盘 - 启动脚本
echo ========================================
echo.

if not exist .env (
    copy .env.example .env
    echo [初始化] 已创建 .env 配置文件
    echo.
)

set FLASK_PORT_VALUE=5002
for /f "tokens=1,* delims==" %%A in (.env) do (
    if /I "%%A"=="FLASK_PORT" set FLASK_PORT_VALUE=%%B
)

if not exist ".venv\Scripts\python.exe" (
    echo [环境] 未发现 .venv，正在使用本机 Python 创建虚拟环境...
    py -3.10 -m venv .venv
    if errorlevel 1 (
        python -m venv .venv
    )
)

echo [环境] 正在安装/检查依赖...
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
    echo [错误] 依赖安装失败，请检查 pip 网络或 Python 环境
    pause
    exit /b 1
)

echo.
echo [启动] 正在启动 Flask 服务...
echo [Python] .venv\Scripts\python.exe
echo [访问] 浏览器打开 http://127.0.0.1:%FLASK_PORT_VALUE%
echo [停止] 按 Ctrl+C 或运行 stop.bat
echo.
".venv\Scripts\python.exe" -m app
pause
