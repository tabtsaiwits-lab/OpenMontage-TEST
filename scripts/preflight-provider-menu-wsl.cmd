@echo off
REM 在 WSL 內執行 provider_menu_summary()，避免 Windows CMD 以 UNC 為 cwd 時失敗。
setlocal
cd /d "%USERPROFILE%" 2>nul
if errorlevel 1 cd /d "%SystemRoot%"
wsl.exe -d Ubuntu -e bash "/home/test/OpenMontage/scripts/preflight_provider_menu.sh"
echo.
pause
