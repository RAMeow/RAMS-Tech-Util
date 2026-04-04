$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AppRoot {
    $baseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
    if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
        return $baseDir.TrimEnd('\')
    }

    throw "Could not resolve application folder."
}

function Get-SelfPath {
    return [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}

try {
    $root = Get-AppRoot
    Set-Location $root

    $mainScript = Join-Path $root "winutil.ps1"
    if (-not (Test-Path $mainScript)) {
        throw "Embedded winutil.ps1 was not extracted."
    }

    if (-not (Test-IsAdmin)) {
        $selfPath = Get-SelfPath
        Start-Process -FilePath $selfPath -Verb RunAs -WorkingDirectory $root
        exit
    }

    Start-Process -FilePath "powershell.exe" -WorkingDirectory $root -ArgumentList @(
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
