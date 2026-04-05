param (
    [switch]$Run,
    [string]$Arguments
)

$ErrorActionPreference = "Stop"

$scriptname = "winutil.ps1"
$workingdir = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($workingdir)) {
    $workingdir = (Get-Location).Path
}

$generatedScriptPath = Join-Path $workingdir $scriptname

if ((Get-Item $generatedScriptPath -ErrorAction SilentlyContinue).IsReadOnly) {
    Remove-Item $generatedScriptPath -Force
}

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

function Update-Progress {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$StatusMessage,

        [Parameter(Mandatory, Position = 1)]
        [ValidateRange(0, 100)]
        [int]$Percent,

        [Parameter(Position = 2)]
        [string]$Activity = "Compiling"
    )

    Write-Progress -Activity $Activity -Status $StatusMessage -PercentComplete $Percent
}

Update-Progress "Pre-req: Running Preprocessor..." 0

# Dot source the 'Invoke-Preprocessing' function
$preprocessingFilePath = ".\tools\Invoke-Preprocessing.ps1"
. $preprocessingFilePath

$excludedFiles = @()

# Add directories only if they exist
if (Test-Path '.\.git\') { $excludedFiles += '.\.git\' }
if (Test-Path '.\binary\') { $excludedFiles += '.\binary\' }

# Add files that should always be excluded
$alwaysExcluded = @(
    '.\.gitignore',
    '.\.gitattributes',
    '.\.github\CODEOWNERS',
    '.\LICENSE',
    $preprocessingFilePath,
    '*.png',
    '*.ico',
    '*.jpg',
    '*.jpeg',
    '*.gif',
    '*.webp',
    '*.bmp',
    '*.avif',
    '*.svg',
    '*.exe',
    '*.dll',
    '*.zip',
    '*.7z',
    '*.pdf',
    '.\.preprocessor_hashes.json'
)

foreach ($excludePath in $alwaysExcluded) {
    if ($excludePath.Contains('*') -or $excludePath.Contains('?')) {
        $excludedFiles += $excludePath
    }
    elseif (Test-Path -LiteralPath $excludePath) {
        $excludedFiles += $excludePath
    }
}

$msg = "Pre-req: Code Formatting"
Invoke-Preprocessing -WorkingDir $workingdir -ExcludedFiles $excludedFiles -ProgressStatusMessage $msg

# Create the script in memory
Update-Progress "Pre-req: Allocating Memory" 0
$script_content = [System.Collections.Generic.List[string]]::new()

Update-Progress "Adding: Version" 10

$versionFile = Join-Path $workingdir "version.txt"

if (-not (Test-Path $versionFile)) {
    throw "Missing version.txt"
}

$version = (Get-Content -LiteralPath $versionFile -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($version)) {
    throw "version.txt is empty"
}

$script_content.Add(
    (Get-Content -LiteralPath ".\scripts\start.ps1" -Raw).Replace('#{replaceme}', $version)
)

Update-Progress "Adding: Functions" 20
Get-ChildItem ".\functions" -Recurse -File -Filter "*.ps1" | ForEach-Object {
    $script_content.Add((Get-Content -LiteralPath $_.FullName -Raw))
}

Update-Progress "Adding: Config *.json" 40
Get-ChildItem ".\config" -File | Where-Object { $_.Extension -eq ".json" } | ForEach-Object {
    $json = Get-Content -LiteralPath $_.FullName -Raw
    $jsonAsObject = $json | ConvertFrom-Json

    if ($_.Name -eq "applications.json") {
        foreach ($appEntryName in @($jsonAsObject.PSObject.Properties.Name)) {
            $appEntryContent = $jsonAsObject.$appEntryName
            $jsonAsObject.PSObject.Properties.Remove($appEntryName)
            $jsonAsObject | Add-Member -MemberType NoteProperty -Name "WPFInstall$appEntryName" -Value $appEntryContent
        }
    }

    $json = @"
$($jsonAsObject | ConvertTo-Json -Depth 3)
"@

    $sync.configs.$($_.BaseName) = $json | ConvertFrom-Json
    $script_content.Add("`$sync.configs.$($_.BaseName) = @'`r`n$json`r`n'@ | ConvertFrom-Json")
}

$xaml = Get-Content -LiteralPath ".\xaml\inputXML.xaml" -Raw

Update-Progress "Adding: Xaml" 90
$script_content.Add(@"
`$inputXML = @'
$xaml
'@
"@)

Update-Progress "Adding: autounattend.xml" 95
$autounattendRaw = Get-Content -LiteralPath ".\tools\autounattend.xml" -Raw
$autounattendRaw = [regex]::Replace(
    $autounattendRaw,
    '<!--.*?-->',
    '',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

$autounattendXml = (
    $autounattendRaw -split "`r?`n" |
    Where-Object { $_.Trim() -ne '' } |
    ForEach-Object { $_.TrimEnd() }
) -join "`r`n"

$script_content.Add(@"
`$WinUtilAutounattendXml = @'
$autounattendXml
'@
"@)

$script_content.Add((Get-Content -LiteralPath ".\scripts\main.ps1" -Raw))

Update-Progress "Removing temporary files" 99
Remove-Item ".\xaml\inputApp.xaml" -ErrorAction SilentlyContinue
Remove-Item ".\xaml\inputTweaks.xaml" -ErrorAction SilentlyContinue
Remove-Item ".\xaml\inputFeatures.xaml" -ErrorAction SilentlyContinue

Set-Content -Path $generatedScriptPath -Value ($script_content -join "`r`n") -Encoding ascii
Write-Progress -Activity "Compiling" -Completed

Update-Progress -Activity "Validating" -StatusMessage "Checking winutil.ps1 Syntax" -Percent 0
try {
    Get-Command -Syntax $generatedScriptPath | Out-Null
}
catch {
    Write-Warning "Syntax validation for 'winutil.ps1' has failed."
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Progress -Activity "Validating" -Completed

if ($Run) {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    if ($Arguments) {
        & $generatedScriptPath $Arguments
    }
    else {
        & $generatedScriptPath
    }

    exit
}
