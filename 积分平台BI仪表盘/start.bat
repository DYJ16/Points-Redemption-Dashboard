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
echo [启动] 正在启动 Flask 服务...
echo [访问] 浏览器打开 http://127.0.0.1:5000
echo [停止] 按 Ctrl+C 或运行 stop.bat
echo.
python -m app
pause
