
param(
    [string]$Config,
    [switch]$Run,
    [switch]$NoUI,
    [switch]$Offline,
    [switch]$ClearCachedData
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$root = $PSScriptRoot
Set-Location $root

$Host.UI.RawUI.WindowTitle = "RAM Tech Utility"


function Clear-RAMLocalCache {
    param([string]$CacheRoot)

    if (-not [string]::IsNullOrWhiteSpace($CacheRoot) -and (Test-Path $CacheRoot)) {
        Write-Host "Clearing cached RAM Tech Utility data from $CacheRoot" -ForegroundColor Yellow
        Remove-Item -Path $CacheRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$cacheRoot = Join-Path $env:LOCALAPPDATA 'RAM-Tech-Utility'
if ($ClearCachedData) {
    $currentRoot = [System.IO.Path]::GetFullPath($root)
    $cacheRootResolved = [System.IO.Path]::GetFullPath($cacheRoot)

    if ($currentRoot.TrimEnd('\\') -eq $cacheRootResolved.TrimEnd('\\')) {
        Clear-RAMLocalCache -CacheRoot $cacheRoot
        Write-Host 'Cached local install cleared. Re-run from the website launcher or the newest extracted package.' -ForegroundColor Green
        exit 0
    }

    Clear-RAMLocalCache -CacheRoot $cacheRoot
}

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
if ($ClearCachedData) { $argList += '-ClearCachedData' }

& $compiled @argList
