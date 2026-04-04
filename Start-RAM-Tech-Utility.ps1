
param(
    [string]$Config,
    [switch]$Run,
    [switch]$NoUI,
    [switch]$Offline
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$root = $PSScriptRoot
Set-Location $root

$Host.UI.RawUI.WindowTitle = "RAM Tech Utility"

$compiled = Join-Path $root 'winutil.ps1'
if (-not (Test-Path $compiled)) {
    Write-Host 'Compiling RAM Tech Utility from source...' -ForegroundColor Cyan
    try {
        & (Join-Path $root 'Compile.ps1')
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    catch {
        Write-Host "Compile failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Open Compile.ps1 in PowerShell to see the exact failing line.' -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path $compiled)) {
    Write-Host 'RAM Tech Utility could not create winutil.ps1 during startup.' -ForegroundColor Red
    exit 1
}

$argList = @()
if ($Config) { $argList += @('-Config', $Config) }
if ($Run) { $argList += '-Run' }
if ($NoUI) { $argList += '-NoUI' }
if ($Offline) { $argList += '-Offline' }

& $compiled @argList
