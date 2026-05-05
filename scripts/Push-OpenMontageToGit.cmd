@echo off
REM CMD 不支援以 UNC 路徑作為「啟動時」的目前目錄；先切到本機目錄再呼叫 PowerShell。
REM （勿依賴 pushd 到 \\wsl.localhost\...，部分環境在啟動子程序時仍會繼承 UNC cwd。）
setlocal
set "PS1=%~dp0Push-OpenMontageToGit.ps1"
cd /d "%USERPROFILE%" 2>nul
if errorlevel 1 cd /d "%SystemRoot%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set EXITCODE=%ERRORLEVEL%
if not "%EXITCODE%"=="0" pause
exit /b %EXITCODE%
