$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps1 = Join-Path $root "Build-Exe-Entry.ps1"
$icon = Join-Path $root "logo.ico"
$logoPng = Join-Path $root "logo.png"
$logoIco = Join-Path $root "logo.ico"
$payload = Join-Path $root "winutil.ps1"
$versionFile = Join-Path $root "version.txt"

if (-not (Test-Path $ps1)) {
    throw "Missing Build-Exe-Entry.ps1"
}

if (-not (Test-Path $icon)) {
    throw "Missing logo.ico"
}

if (-not (Test-Path $logoPng)) {
    throw "Missing logo.png"
}

if (-not (Test-Path $logoIco)) {
    throw "Missing logo.ico"
}

if (-not (Test-Path $payload)) {
    throw "Missing winutil.ps1. Run the normal launcher once first so winutil.ps1 is generated."
}

# Auto-generate version from current local date and hour
# Example: April 4, 2026 at 2 AM -> 26.04.04.02
$version = Get-Date -Format "yy.MM.dd.HH"

# Persist the generated version for Compile.ps1 and reference
Set-Content -Path $versionFile -Value $version -Encoding utf8

$out = Join-Path $root "RAM-Tech-Utility.exe"
$releaseRoot = Join-Path $root "release"
$releaseFolder = Join-Path $releaseRoot "RAM-Tech-Utility-$version"
$releaseExe = Join-Path $releaseFolder "RAM-Tech-Utility.exe"
$releaseReadme = Join-Path $releaseFolder "README.txt"
$releaseZip = Join-Path $releaseRoot "RAM-Tech-Utility-$version.zip"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ps2exeModule = Get-ChildItem "$HOME\Documents\PowerShell\Modules\ps2exe" -Recurse -Filter "*.psm1" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (-not $ps2exeModule) {
    throw "ps2exe module not found. Run: Install-Module ps2exe -Scope CurrentUser -Force"
}

Import-Module $ps2exeModule.FullName -Force

Write-Host "Building RAM Tech Utility EXE..." -ForegroundColor Cyan
Write-Host "Version: $version" -ForegroundColor Cyan

Invoke-PS2EXE `
    -inputFile $ps1 `
    -outputFile $out `
    -iconFile $icon `
    -version $version `
    -title "RAM Tech Utility" `
    -product "RAM Tech Utility" `
    -company "RAMS COMPUTER REPAIR" `
    -description "RAM Tech Utility executable build" `
    -copyright "RAMS COMPUTER REPAIR" `
    -noConsole `
    -embedFiles @{
        "$env:LOCALAPPDATA\RAM-Tech-Utility\winutil.ps1" = $payload
        "$env:LOCALAPPDATA\RAM-Tech-Utility\logo.png" = $logoPng
        "$env:LOCALAPPDATA\RAM-Tech-Utility\logo.ico" = $logoIco
    } `
    -verbose

if (-not (Test-Path $out)) {
    throw "Build completed without creating RAM-Tech-Utility.exe"
}

New-Item -ItemType Directory -Path $releaseFolder -Force | Out-Null
Copy-Item $out $releaseExe -Force

$readmeContent = @"
RAM Tech Utility
Version: $version

RAM'S COMPUTER REPAIR
Harlingen, Texas
(956) 244-5094
www.ramscomputerrepair.net

This package contains the current EXE build of RAM Tech Utility.
Run the EXE and approve Administrator elevation if prompted.
"@

Set-Content -Path $releaseReadme -Value $readmeContent -Encoding utf8

if (Test-Path $releaseZip) {
    Remove-Item $releaseZip -Force
}

Compress-Archive -Path "$releaseFolder\*" -DestinationPath $releaseZip -Force

Write-Host ""
Write-Host "Build complete." -ForegroundColor Green
Write-Host "Version:     $version"
Write-Host "Root EXE:    $out"
Write-Host "Release EXE: $releaseExe"
Write-Host "Release ZIP: $releaseZip"
