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
$preprocessingFilePath = Join-Path $workingdir "tools\Invoke-Preprocessing.ps1"
. $preprocessingFilePath

$excludedFiles = @()

# Add directories only if they exist
$gitDir = Join-Path $workingdir ".git"
$binaryDir = Join-Path $workingdir "binary"

if (Test-Path $gitDir) { $excludedFiles += $gitDir }
if (Test-Path $binaryDir) { $excludedFiles += $binaryDir }

# Add files that should always be excluded
$alwaysExcluded = @(
    (Join-Path $workingdir ".gitignore"),
    (Join-Path $workingdir ".gitattributes"),
    (Join-Path $workingdir ".github\CODEOWNERS"),
    (Join-Path $workingdir "LICENSE"),
    $preprocessingFilePath,
    "*.png",
    (Join-Path $workingdir ".preprocessor_hashes.json")
)

foreach ($excludePath in $alwaysExcluded) {
    if ($excludePath -like "*.png") {
        $excludedFiles += $excludePath
    }
    elseif (Test-Path $excludePath) {
        $excludedFiles += $excludePath
    }
}

$msg = "Pre-req: Code Formatting"
Invoke-Preprocessing -WorkingDir $workingdir -ExcludedFiles $excludedFiles -ProgressStatusMessage $msg

# Create the script in memory
Update-Progress "Pre-req: Allocating Memory" 0
$script_content = [System.Collections.Generic.List[string]]::new()

Update-Progress "Adding: Version" 10
$startScriptPath = Join-Path $workingdir "scripts\start.ps1"
$script_content.Add(
    (Get-Content $startScriptPath -Raw).Replace('#{replaceme}', (Get-Date -Format "yy.MM.dd"))
)

Update-Progress "Adding: Functions" 20
Get-ChildItem (Join-Path $workingdir "functions") -Recurse -File | ForEach-Object {
    $script_content.Add((Get-Content $_.FullName -Raw))
}

Update-Progress "Adding: Config *.json" 40
Get-ChildItem (Join-Path $workingdir "config") -File | Where-Object { $_.Extension -eq ".json" } | ForEach-Object {
    $json = Get-Content $_.FullName -Raw
    $jsonAsObject = $json | ConvertFrom-Json

    # Add 'WPFInstall' as a prefix to every entry-name in 'applications.json'
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

# Read the entire XAML file as a single string
$xamlPath = Join-Path $workingdir "xaml\inputXML.xaml"
$xaml = Get-Content $xamlPath -Raw

Update-Progress "Adding: Xaml" 90
$script_content.Add(@"
`$inputXML = @'
$xaml
'@
"@)

Update-Progress "Adding: autounattend.xml" 95
$autounattendPath = Join-Path $workingdir "tools\autounattend.xml"
$autounattendRaw = Get-Content $autounattendPath -Raw

# Strip XML comments (<!-- ... -->, including multi-line)
$autounattendRaw = [regex]::Replace(
    $autounattendRaw,
    '<!--.*?-->',
    '',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Drop blank lines and trim trailing whitespace per line
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

$mainScriptPath = Join-Path $workingdir "scripts\main.ps1"
$script_content.Add((Get-Content $mainScriptPath -Raw))

Update-Progress "Removing temporary files" 99
Remove-Item (Join-Path $workingdir "xaml\inputApp.xaml") -ErrorAction SilentlyContinue
Remove-Item (Join-Path $workingdir "xaml\inputTweaks.xaml") -ErrorAction SilentlyContinue
Remove-Item (Join-Path $workingdir "xaml\inputFeatures.xaml") -ErrorAction SilentlyContinue

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
