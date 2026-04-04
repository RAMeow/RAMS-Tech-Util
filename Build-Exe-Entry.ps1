Add-Type -AssemblyName PresentationFramework

$ErrorActionPreference = "Stop"

try {
    $appRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if (-not $appRoot) {
        $appRoot = [System.AppDomain]::CurrentDomain.BaseDirectory
    }

    Set-Location $appRoot

    $mainScript = Join-Path $appRoot "winutil.ps1"
    if (-not (Test-Path $mainScript)) {
        throw "Could not find main script: $mainScript"
    }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $mainScript
}
catch {
    [System.Windows.MessageBox]::Show(
        $_.Exception.Message,
        "RAM Tech Utility",
        "OK",
        "Error"
    ) | Out-Null
}
