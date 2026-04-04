$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps1 = Join-Path $root "Build-Exe-Entry.ps1"
$icon = Join-Path $root "logo.ico"
$out = Join-Path $root "RAM-Tech-Utility.exe"
$payload = Join-Path $root "winutil.ps1"

if (-not (Test-Path $ps1)) { throw "Missing Build-Exe-Entry.ps1" }
if (-not (Test-Path $icon)) { throw "Missing logo.ico" }
if (-not (Test-Path $payload)) { throw "Missing winutil.ps1" }

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ps2exeModule = Get-ChildItem "$HOME\Documents\PowerShell\Modules\ps2exe" -Recurse -Filter "*.psm1" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (-not $ps2exeModule) {
    throw "ps2exe module not found. Run: Install-Module ps2exe -Scope CurrentUser -Force"
}

Import-Module $ps2exeModule.FullName

Invoke-PS2EXE `
  -inputFile $ps1 `
  -outputFile $out `
  -iconFile $icon `
  -noConsole `
  -embedFiles @{
    "$env:LOCALAPPDATA\RAM-Tech-Utility\winutil.ps1" = $payload
  } `
  -verbose
