param([switch]$Strict)

$ErrorActionPreference = "Stop"
Write-Host "==> CI-LOCAL: Senaryo Kilidi" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File .\scripts\senaryo_kilidi.ps1 @PSBoundParameters

Write-Host "`n==> CI-LOCAL: dart analyze --fatal-infos" -ForegroundColor Cyan
dart analyze --fatal-infos

Write-Host "`n==> CI-LOCAL: flutter test" -ForegroundColor Cyan
flutter test

Write-Host "`n==> CI-LOCAL: TAMAMLANDI ✅" -ForegroundColor Green
