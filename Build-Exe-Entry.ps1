$ErrorActionPreference = "Stop"

try {
    Add-Type -AssemblyName System.Windows.Forms

    $appRoot = [System.AppDomain]::CurrentDomain.BaseDirectory
    if (-not $appRoot) {
        throw "Could not resolve application base directory."
    }

    $batPath = Join-Path $appRoot "Start-RAM-Tech-Utility.bat"
    if (-not (Test-Path $batPath)) {
        throw "Could not find launcher: $batPath"
    }

    Start-Process -FilePath $batPath -WorkingDirectory $appRoot
}
catch {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "RAM Tech Utility",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    catch {
        Write-Host $_.Exception.Message
    }
}
