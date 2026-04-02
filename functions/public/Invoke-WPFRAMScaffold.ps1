function Invoke-WPFRAMScaffold {
    param(
        [Parameter(Mandatory)]
        [string]$Module
    )

    $ramModuleRoot = Join-Path $PSScriptRoot "..\..\overrides\ram-modules"
    $safeName = ($Module -replace '[^A-Za-z0-9 _-]', '').Trim()
    $targetFolder = Join-Path $ramModuleRoot $safeName

    if (-not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
    }

    $readmePath = Join-Path $targetFolder 'README.txt'
    if (-not (Test-Path $readmePath)) {
        @"
RAM Tech Utility module scaffold

Module: $Module
Status: Placeholder scaffold

Use this folder for:
- scripts
- presets
- notes
- future UI assets
"@ | Set-Content -Path $readmePath -Encoding UTF8
    }

    Write-Host "[RAM Tools] Opened scaffold for $Module" -ForegroundColor Cyan

    $message = @"
$Module scaffold is ready.

Folder:
$targetFolder

This is a safe placeholder for future RAM-specific actions.
"@
    Show-CustomDialog -Title "$Module Scaffold" -Message $message
}
