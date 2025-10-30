New-Item -ItemType Directory -Path .\scripts -Force | Out-Null

$ps1 = @'
param(
  [switch]$Strict
)

$ErrorActionPreference = "Stop"
Write-Host "==> Senaryo Kilidi Çalışıyor (v1.1)..." -ForegroundColor Cyan

function Show-Files ($matches) {
  $matches | ForEach-Object {
    Write-Host ("  -> " + $_.Path + ":" + $_.LineNumber + "  " + $_.Line)
  }
}

# 0) Doküman var mı?
if (-not (Test-Path ".\docs\SENARYO_KILIDI.md")) {
  Write-Host "[UYARI] docs/SENARYO_KILIDI.md bulunamadı." -ForegroundColor Yellow
}

# 1) Pub & Analyze
Write-Host "-> flutter pub get"
flutter pub get | Out-Host

Write-Host "-> dart analyze --fatal-infos"
dart analyze --fatal-infos | Out-Host

# 2) users.role yazımı yasak (UI)
$forbiddenRoleWrite = Select-String -Path ".\lib\**\*.dart" -Pattern "collection\(\s*'users'\s*\).*?\.(set|update)\s*\(.*role" -CaseSensitive:$false
if ($forbiddenRoleWrite) {
  Write-Host "`n[HATA] UI katmanında users.role yazımı tespit edildi!" -ForegroundColor Red
  Show-Files $forbiddenRoleWrite
  exit 1
}

# 3) OTP’den doğrudan sozlesme_kabul’a geçiş yasak
$otpFile = Get-ChildItem -Path .\lib -Recurse -Filter "telefon_dogrulama_sayfasi.dart" | Select-Object -First 1
if ($otpFile) {
  $badJump = Select-String -Path $otpFile.FullName -Pattern "RouteNames\.sozlesmeKabul"
  if ($badJump) {
    Write-Host "`n[HATA] OTP ekranından doğrudan /sozlesme_kabul'a navigasyon tespit edildi!" -ForegroundColor Red
    Show-Files $badJump
    exit 1
  }
  # DEV bypass yalnız kDebugMode içinde mi? (basit kontrol)
  $bypassCheck = Select-String -Path $otpFile.FullName -Pattern "kDebugMode" -SimpleMatch
  if (-not $bypassCheck) {
    Write-Host "`n[UYARI] OTP dev bypass için kDebugMode referansı bulunamadı." -ForegroundColor Yellow
  }
}

# 4) Rol sayfası: registrations yazılmalı, users.*(set|update) olmamalı
$rolFile = Get-ChildItem -Path .\lib -Recurse -Filter "rol_secimi_sayfasi.dart" | Select-Object -First 1
if ($rolFile) {
  $mustRegistration = Select-String -Path $rolFile.FullName -Pattern "collection\('registrations'\)" -SimpleMatch
  $badUsersWrite = Select-String -Path $rolFile.FullName -Pattern "collection\('users'\).*?\.(set|update)" -SimpleMatch
  if (-not $mustRegistration -or $badUsersWrite) {
    Write-Host "`n[HATA] rol_secimi_sayfasi.dart senaryo yazım kuralına uymuyor!" -ForegroundColor Red
    if (-not $mustRegistration) { Write-Host "  -> registrations yazımı bulunamadı" }
    if ($badUsersWrite)         { Write-Host "  -> users.*(set|update) tespit edildi" }
    exit 1
  }
}

# 5) İlgi sayfası: (varsa) interests/ilgiler izleri
$ilgiFile = Get-ChildItem -Path .\lib -Recurse -Filter "ilgi_secimi_sayfasi.dart" | Select-Object -First 1
if ($ilgiFile) {
  $hasInterests = Select-String -Path $ilgiFile.FullName -Pattern "interests|ilgiler" -CaseSensitive:$false
  if (-not $hasInterests) {
    Write-Host "`n[UYARI] ilgi_secimi_sayfasi.dart içinde ilgi alanı kaydı referansı bulunamadı." -ForegroundColor Yellow
  }
}

# 6) Hukuk ekranı: versiyon etiketleri referansı
$legalFile = Get-ChildItem -Path .\lib -Recurse -Filter "*sozlesme*_sayfasi.dart" | Select-Object -First 1
if ($legalFile) {
  $hasTags = Select-String -Path $legalFile.FullName -Pattern "_vSozlesme|_vRiza|_vAyd|_vGiz"
  if (-not $hasTags) {
    Write-Host "`n[UYARI] Hukuk ekranında versiyon etiketleri referansı bulunamadı." -ForegroundColor Yellow
  }
}

# 7) Rota zinciri izleri (hafif kontrol)
$appRouter = Get-ChildItem -Path .\lib -Recurse -Filter "app_router.dart" | Select-Object -First 1
if ($appRouter) {
  $hasRol = Select-String -Path $appRouter.FullName -Pattern "RouteNames\.rolSec"
  $hasIlgi = Select-String -Path $appRouter.FullName -Pattern "RouteNames\.ilgiSec"
  $hasLegal = Select-String -Path $appRouter.FullName -Pattern "RouteNames\.sozlesmeKabul"
  if (-not $hasRol -or -not $hasIlgi -or -not $hasLegal) {
    Write-Host "`n[HATA] app_router.dart içinde MVP rotaları eksik!" -ForegroundColor Red
    if (-not $hasRol)   { Write-Host "  -> /rol_sec tanımı yok" }
    if (-not $hasIlgi)  { Write-Host "  -> /ilgi_sec tanımı yok" }
    if (-not $hasLegal) { Write-Host "  -> /sozlesme_kabul tanımı yok" }
    exit 1
  }
}

# 8) Strict mod: daha derin taramalar
if ($Strict -and $otpFile) {
  $otpToRol = Select-String -Path $otpFile.FullName -Pattern "RouteNames\.rolSec"
  if (-not $otpToRol) {
    Write-Host "`n[HATA] OTP ekranı /rol_sec'e yönlendirmiyor!" -ForegroundColor Red
    exit 1
  }
}

Write-Host "`n==> Senaryo Kilidi: GEÇTİ ✅" -ForegroundColor Green
'@

Set-Content -LiteralPath .\scripts\senaryo_kilidi.ps1 -Value $ps1 -Encoding UTF8
