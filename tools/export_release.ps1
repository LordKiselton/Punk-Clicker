# Release APK export - reads signing from export_presets.credentials.cfg (gitignored).
# Usage: powershell -File tools/export_release.ps1 [-Version 105]
param(
    [string]$Version = "105",
    [string]$Godot = "C:\Godot461\Godot_v4.6.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

if (-not (Test-Path $Godot)) {
    throw "Godot not found: $Godot"
}

$TestScript = Join-Path $PSScriptRoot "test.ps1"
if (-not (Test-Path $TestScript)) {
    throw "Missing preflight test script: $TestScript"
}
& $TestScript -Godot $Godot

$CredPath = Join-Path $Root "export_presets.credentials.cfg"
if (-not (Test-Path $CredPath)) {
    throw "Missing credentials file: $CredPath"
}

function Read-Cred([string]$key) {
    $line = Get-Content $CredPath | Where-Object { $_ -match ("^\s*" + [regex]::Escape($key) + "=") } | Select-Object -First 1
    if (-not $line) { throw "Missing $key in credentials" }
    if ($line -match '="([^"]*)"') { return $Matches[1] }
    throw "Bad format for $key"
}

$ks = Read-Cred "keystore/release"
if (-not (Test-Path $ks)) {
    throw "Release keystore not found: $ks"
}

$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $ks
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = Read-Cred "keystore/release_user"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = Read-Cred "keystore/release_password"

$Out = Join-Path $Root "build/balagan-release-v$Version.apk"
New-Item -ItemType Directory -Force -Path (Join-Path $Root "build") | Out-Null
$Log = Join-Path $Root "build/export_v$Version.log"
Remove-Item -Force -ErrorAction SilentlyContinue $Log

Write-Host "Exporting $Out ..."
& $Godot --headless --path $Root --export-release "Android" $Out 2>&1 | Tee-Object -FilePath $Log
if ($LASTEXITCODE -ne 0) { throw "Export failed - see $Log" }

if (-not (Test-Path $Out)) { throw "APK missing after export" }
Write-Host "OK: $Out ($([math]::Round((Get-Item $Out).Length / 1MB, 1)) MB)"

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) {
    throw "Python not found; cannot run post-export APK audit"
}
& $Python.Source (Join-Path $PSScriptRoot "apk_audit.py") $Out
if ($LASTEXITCODE -ne 0) {
    throw "APK content audit failed"
}

$ApkSigner = $null
if ($env:ANDROID_HOME -and (Test-Path (Join-Path $env:ANDROID_HOME "build-tools"))) {
    $ApkSigner = Get-ChildItem (Join-Path $env:ANDROID_HOME "build-tools") -Recurse -Filter "apksigner.bat" |
        Sort-Object FullName -Descending |
        Select-Object -First 1
}
if ($ApkSigner) {
    & $ApkSigner.FullName verify --verbose $Out
    if ($LASTEXITCODE -ne 0) {
        throw "APK signature verification failed"
    }
    Write-Host "APK signature verified."
} else {
    Write-Warning "apksigner.bat not found via ANDROID_HOME; content audit passed but signature was not independently verified."
}
