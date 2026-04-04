param(
    [string]$Config,
    [switch]$Run,
    [switch]$NoUI,
    [switch]$Offline
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    $root = [System.AppDomain]::CurrentDomain.BaseDirectory
    if ([string]::IsNullOrWhiteSpace($root)) {
        throw "Could not resolve application folder."
    }

    Set-Location $root

    if (-not (Test-IsAdmin)) {
        $argList = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', ('"{0}"' -f (Join-Path $root 'Build-Exe-Entry.ps1'))
        )

        if ($Config) { $argList += @('-Config', ('"{0}"' -f $Config)) }
        if ($Run) { $argList += '-Run' }
        if ($NoUI) { $argList += '-NoUI' }
        if ($Offline) { $argList += '-Offline' }

        Start-Process -FilePath 'powershell.exe' -Verb RunAs -WorkingDirectory $root -ArgumentList ($argList -join ' ')
        exit
    }

    $Host.UI.RawUI.WindowTitle = "RAM Tech Utility"

    $compiled = Join-Path $root 'winutil.ps1'
    if (-not (Test-Path $compiled)) {
        Write-Host 'Compiling RAM Tech Utility from source...' -ForegroundColor Cyan
        try {
            & (Join-Path $root 'Compile.ps1')
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
        catch {
            Write-Host "Compile failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host 'Open Compile.ps1 in PowerShell to see the exact failing line.' -ForegroundColor Yellow
            Read-Host 'Press Enter to exit'
            exit 1
        }
    }

    if (-not (Test-Path $compiled)) {
        Write-Host 'RAM Tech Utility could not create winutil.ps1 during startup.' -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }

    $runArgs = @()
    if ($Config) { $runArgs += @('-Config', $Config) }
    if ($Run) { $runArgs += '-Run' }
    if ($NoUI) { $runArgs += '-NoUI' }
    if ($Offline) { $runArgs += '-Offline' }

    & $compiled @runArgs
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
        Read-Host 'Press Enter to exit'
    }
}
