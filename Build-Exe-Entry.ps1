$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AppRoot {
    $baseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
    if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
        return $baseDir.TrimEnd('\')
    }

    if ($PSScriptRoot) {
        return $PSScriptRoot.TrimEnd('\')
    }

    throw "Could not resolve application folder."
}

function Get-SelfPath {
    try {
        return [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    } catch {
        if ($PSCommandPath) { return $PSCommandPath }
        if ($MyInvocation.MyCommand.Path) { return $MyInvocation.MyCommand.Path }
        throw "Could not resolve current launcher path."
    }
}

try {
    $root = Get-AppRoot
    $compiled = Join-Path $root "winutil.ps1"

    if (-not (Test-Path $compiled)) {
        throw "winutil.ps1 was not found in:`n$root`n`nRun Start-RAM-Tech-Utility.ps1 once first to generate it, then rebuild/test the EXE."
    }

    if (-not (Test-IsAdmin)) {
        $selfPath = Get-SelfPath

        if ($selfPath.ToLower().EndsWith(".exe")) {
            Start-Process -FilePath $selfPath -Verb RunAs -WorkingDirectory $root
        } else {
            Start-Process -FilePath "powershell.exe" -Verb RunAs -WorkingDirectory $root -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File", "`"$selfPath`""
            )
        }
        exit
    }

    Start-Process -FilePath "powershell.exe" -WorkingDirectory $root -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$compiled`""
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
