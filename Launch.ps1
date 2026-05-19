# Right-click -> Run with PowerShell (if .bat fails)
Set-Location $PSScriptRoot
$flutter = "C:\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) { $flutter = "flutter" }

Write-Host "Rep Battle - pub get..." -ForegroundColor Cyan
& $flutter pub get
if ($LASTEXITCODE -ne 0) { Read-Host "pub get failed. Press Enter"; exit 1 }

Write-Host "Starting Chrome..." -ForegroundColor Cyan
& $flutter run -d chrome
Read-Host "Press Enter to close"
