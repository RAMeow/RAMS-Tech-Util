$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SelfPath {
    try {
        return [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    }
    catch {
        if ($PSCommandPath) {
            return $PSCommandPath
        }

        if ($MyInvocation.MyCommand.Path) {
            return $MyInvocation.MyCommand.Path
        }

        throw "Could not determine launcher path."
    }
}

try {
    $payloadRoot = Join-Path $env:LOCALAPPDATA "RAM-Tech-Utility"
    New-Item -Path $payloadRoot -ItemType Directory -Force | Out-Null

    $mainScript = Join-Path $payloadRoot "winutil.ps1"

    if (-not (Test-Path $mainScript)) {
        throw "Embedded payload was not extracted: $mainScript"
    }

    if (-not (Test-IsAdmin)) {
        $selfPath = Get-SelfPath
        Start-Process -FilePath $selfPath -Verb RunAs -WorkingDirectory $payloadRoot
        exit
    }

    Start-Process -FilePath "powershell.exe" -WorkingDirectory $payloadRoot -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$mainScript`""
    )

    exit
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
        Read-Host "Press Enter to exit"
    }

    exit 1
}
