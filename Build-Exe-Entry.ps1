$ErrorActionPreference = "Stop"

try {
    $appRoot = [System.AppDomain]::CurrentDomain.BaseDirectory
    if ([string]::IsNullOrWhiteSpace($appRoot)) {
        throw "Could not resolve application folder."
    }

    $batPath = Join-Path $appRoot "Start-RAM-Tech-Utility.bat"
    if (-not (Test-Path $batPath)) {
        throw "Could not find launcher: $batPath"
    }

    Start-Process -FilePath "cmd.exe" -WorkingDirectory $appRoot -ArgumentList "/c `"$batPath`""
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "RAM Tech Utility"
    ) | Out-Null
}