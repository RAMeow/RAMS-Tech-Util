$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SelfPath {
    [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}

try {
    $payloadRoot = Join-Path $env:LOCALAPPDATA "RAM-Tech-Utility"
    $mainScript = Join-Path $payloadRoot "winutil.ps1"

    if (-not (Test-Path $mainScript)) {
        throw "Embedded payload was not extracted: $mainScript"
    }

    if (-not (Test-IsAdmin)) {
        $selfPath = Get-SelfPath
        Start-Process -FilePath $selfPath -Verb RunAs
        exit
    }

    Start-Process -FilePath "powershell.exe" -WorkingDirectory $payloadRoot -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$mainScript`""
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
