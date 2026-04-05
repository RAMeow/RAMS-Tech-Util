function Invoke-WinUtilInstallPSProfile {
    try {
        $message = @"
RAM Tech Utility PowerShell profile setup is not configured yet.

The old upstream profile installer has been disabled to prevent pulling or launching external branding or remote profile content.

If you want this feature later, replace this function with a RAM-specific profile installer.
"@

        Show-CustomDialog -Title "PowerShell Profile" -Message $message -EnableScroll $true
    }
    catch {
        Write-Host "PowerShell profile setup is not configured yet." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
