$ErrorActionPreference = "Stop"

try {
    $appRoot = [System.AppDomain]::CurrentDomain.BaseDirectory
    if (-not $appRoot) {
        throw "Could not resolve application base directory."
    }

    Set-Location $appRoot

    $mainScript = Join-Path $appRoot "winutil.ps1"
    if (-not (Test-Path $mainScript)) {
        throw "Could not find main script: $mainScript"
    }

    Start-Process powershell.exe -Verb RunAs -WorkingDirectory $appRoot -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$mainScript`""
    )
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "RAM Tech Utility",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}
