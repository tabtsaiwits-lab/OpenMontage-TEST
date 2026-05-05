#Requires -Version 5.1
<#
.SYNOPSIS
    從 Windows 對 WSL 路徑下的 OpenMontage 倉庫執行 git status 與 git push，並顯示結果。

.DESCRIPTION
    Push-OpenMontageToGit.cmd 會先 cd 到 %USERPROFILE%，避免「CMD 不支援 UNC 為啟動目錄」錯誤。
    使用 Git for Windows 的 -C 指定 UNC 倉庫路徑。請先完成：
    git config --global credential.helper manager
    git config --global --add safe.directory "//wsl.localhost/Ubuntu/home/test/OpenMontage"

    從 \\wsl.localhost\... 執行時，常見錯誤為「未經數位簽署」：請勿直接 .\xxx.ps1，
    改雙擊同資料夾的 Push-OpenMontageToGit.cmd，或手動：
    powershell -NoProfile -ExecutionPolicy Bypass -File .\Push-OpenMontageToGit.ps1

    若仍被擋，可對 .ps1 解除封鎖後再試（僅 RemoteSigned 情境可能有幫助）：
    Unblock-File -LiteralPath '\\wsl.localhost\Ubuntu\home\test\OpenMontage\scripts\Push-OpenMontageToGit.ps1'

.EXAMPLE
    # 建議：在檔案總管雙擊 Push-OpenMontageToGit.cmd

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\Push-OpenMontageToGit.ps1
#>

$ErrorActionPreference = 'Continue'

# WSL 專案於 Windows 的 UNC 路徑（若你的路徑不同請改此變數）
$Repo = "\\wsl.localhost\Ubuntu\home\test\OpenMontage"

# 避免從 UNC 當前目錄啟動 Git 子程序時出現怪問題
Set-Location -LiteralPath $env:USERPROFILE

Write-Host "Repository: $Repo" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $Repo)) {
    Write-Host "ERROR: repo path not found: $Repo" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "--- git status ---" -ForegroundColor Yellow
& git.exe -C $Repo status
if ($LASTEXITCODE -ne 0) {
    Write-Host "git status failed (exit $LASTEXITCODE)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "--- git push -u origin main ---" -ForegroundColor Yellow
& git.exe -C $Repo push -u origin main 2>&1 | ForEach-Object { Write-Host $_ }
$pushCode = $LASTEXITCODE

Write-Host ""
if ($pushCode -eq 0) {
    Write-Host "Done: push succeeded (exit $pushCode)" -ForegroundColor Green
} else {
    Write-Host "Done: push failed (exit $pushCode)" -ForegroundColor Red
}

Read-Host "`nPress Enter to close"
