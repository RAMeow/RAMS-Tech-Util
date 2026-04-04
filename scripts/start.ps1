<#
.NOTES
    Author         : RAM Tech Utility
    Runspace Author: @DeveloperDurp
    Project        : RAM Tech Utility
    Version        : #{replaceme}
#>

param (
    [string]$Config,
    [switch]$Run,
    [switch]$Noui,
    [switch]$Offline
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
$sync.selectedAppsStackPanel
$sync.selectedAppsPopup

$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Set the path for the RAM Tech Utility directory
$winutildir = "$env:LocalAppData\RAM-Tech-Utility"
New-Item $winutildir -ItemType Directory -Force | Out-Null

$logdir = "$winutildir\logs"
New-Item $logdir -ItemType Directory -Force | Out-Null

$sourceLogoPng = Join-Path $PSScriptRoot 'logo.png'
$sourceLogoIco = Join-Path $PSScriptRoot 'logo.ico'

if (Test-Path $sourceLogoPng) {
    Copy-Item $sourceLogoPng (Join-Path $winutildir 'logo.png') -Force
}

if (Test-Path $sourceLogoIco) {
    Copy-Item $sourceLogoIco (Join-Path $winutildir 'logo.ico') -Force
}

Start-Transcript -Path "$logdir\ram-tech-utility_$dateTime.log" -Append -NoClobber | Out-Null

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = "RAM Tech Utility (Admin)"
Clear-Host
