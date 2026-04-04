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
Import-Module ps2exe

Invoke-PS2EXE `
  -inputFile $ps1 `
  -outputFile $out `
  -iconFile $icon `
  -noConsole `
  -embedFiles @{
    "$env:LOCALAPPDATA\RAM-Tech-Utility\winutil.ps1" = $payload
  } `
  -verbose
