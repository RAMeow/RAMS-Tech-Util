<#
.NOTES
    Author         : RAM Tech Utility
    Project        : RAM Tech Utility
    Version        : #{replaceme}
#>

param (
    [string]$Config,
    [switch]$Run,
    [switch]$Noui,
    [switch]$Offline,
    [switch]$ClearCachedData
)

if ($Config) {
    $PARAM_CONFIG = $Config
}

$PARAM_RUN = $false
if ($Run) {
    $PARAM_RUN = $true
}

$PARAM_NOUI = $false
if ($Noui) {
    $PARAM_NOUI = $true
}

$PARAM_OFFLINE = $false
if ($Offline) {
    $PARAM_OFFLINE = $true
}

$PARAM_CLEARCACHEDDATA = $false
if ($ClearCachedData) {
    $PARAM_CLEARCACHEDDATA = $true
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "RAM Tech Utility needs to be run as Administrator. Attempting to relaunch."
    $argList = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        } elseif ($_.Value -is [array]) {
            "-$($_.Key) `"$($_.Value -join ',')`""
        } elseif ($_.Value) {
            "-$($_.Key) `"$($_.Value)`""
        }
    }

    $selfPath = if ($PSCommandPath) {
        $PSCommandPath
    } elseif ($MyInvocation.MyCommand.Path) {
        $MyInvocation.MyCommand.Path
    } else {
        throw "Could not determine the launcher script path for elevation."
    }

    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $powershellCmd }

    if ($processCmd -eq "wt.exe") {
        Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -File `"$selfPath`" $($argList -join ' ')" -Verb RunAs
    } else {
        Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$selfPath`" $($argList -join ' ')" -Verb RunAs
    }

    exit
}

# Load DLLs
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms


function Clear-RAMLocalCache {
    param(
        [string]$CacheRoot,
        [switch]$CloseAfterClear
    )

    if ([string]::IsNullOrWhiteSpace($CacheRoot)) { return $false }

    try {
        if (Test-Path $CacheRoot) {
            Remove-Item -Path $CacheRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        [System.Windows.MessageBox]::Show(
            "Cached local RAM Tech Utility data has been cleared.`n`nReopen from the website launcher or the newest package to pull the latest version.",
            "RAM Tech Utility",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null

        if ($CloseAfterClear -and $sync.ContainsKey('Form') -and $sync['Form']) {
            $sync['Form'].Close()
        }

        return $true
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Could not clear cached data.`n`n$($_.Exception.Message)",
            "RAM Tech Utility",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        return $false
    }
}

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $PSScriptRoot
$sync.version = "#{replaceme}"
$sync.configs = @{}
$sync.Buttons = [System.Collections.Generic.List[PSObject]]::new()
$sync.preferences = @{}
$sync.ProcessRunning = $false
$sync.selectedApps = [System.Collections.Generic.List[string]]::new()
$sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
$sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
$sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()
$sync.currentTab = "Install"
$sync.cacheRoot = Join-Path $env:LOCALAPPDATA 'RAM-Tech-Utility'
$sync.selectedAppsStackPanel
$sync.selectedAppsPopup

$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Set the path for the RAM Tech Utility directory
$winutildir = "$env:LocalAppData\RAM-Tech-Utility"
if ($PARAM_CLEARCACHEDDATA) {
    Clear-RAMLocalCache -CacheRoot $sync.cacheRoot | Out-Null
    exit
}

New-Item $winutildir -ItemType Directory -Force | Out-Null

$logdir = "$winutildir\logs"
New-Item $logdir -ItemType Directory -Force | Out-Null

$sourceLogoPng = Join-Path $PSScriptRoot 'logo.png'
$sourceLogoIco = Join-Path $PSScriptRoot 'logo.ico'
$destLogoPng = Join-Path $winutildir 'logo.png'
$destLogoIco = Join-Path $winutildir 'logo.ico'

if (Test-Path $sourceLogoPng) {
    $sourceLogoPngResolved = [System.IO.Path]::GetFullPath($sourceLogoPng)
    $destLogoPngResolved = [System.IO.Path]::GetFullPath($destLogoPng)

    if ($sourceLogoPngResolved -ne $destLogoPngResolved) {
        Copy-Item $sourceLogoPngResolved $destLogoPngResolved -Force
    }
}

if (Test-Path $sourceLogoIco) {
    $sourceLogoIcoResolved = [System.IO.Path]::GetFullPath($sourceLogoIco)
    $destLogoIcoResolved = [System.IO.Path]::GetFullPath($destLogoIco)

    if ($sourceLogoIcoResolved -ne $destLogoIcoResolved) {
        Copy-Item $sourceLogoIcoResolved $destLogoIcoResolved -Force
    }
}

Start-Transcript -Path "$logdir\ram-tech-utility_$dateTime.log" -Append -NoClobber | Out-Null

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = "RAM Tech Utility (Admin)"

try {
    $rawUI = $Host.UI.RawUI
    $currentBuffer = $rawUI.BufferSize

    $newWidth = 65
    #92
    $newHeight = 24
    #14

    if ($currentBuffer.Width -lt $newWidth) {
        $currentBuffer.Width = $newWidth
    }
    if ($currentBuffer.Height -lt $newHeight) {
        $currentBuffer.Height = $newHeight
    }

    $rawUI.BufferSize = $currentBuffer
    $rawUI.WindowSize = New-Object System.Management.Automation.Host.Size($newWidth, $newHeight)
}
catch {
    Write-Host "Could not resize PowerShell window: $($_.Exception.Message)" -ForegroundColor Yellow
}

Clear-Host
