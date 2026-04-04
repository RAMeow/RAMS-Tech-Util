function Invoke-WPFRAMOpenModuleFolder {
    $ramModuleRoot = Join-Path $PSScriptRoot "..\..\overrides\ram-modules"
    if (-not (Test-Path $ramModuleRoot)) {
        New-Item -Path $ramModuleRoot -ItemType Directory -Force | Out-Null
    }

    Write-Host "[RAM Tools] Opening RAM module folder: $ramModuleRoot" -ForegroundColor Cyan
    Start-Process $ramModuleRoot
}
