# RAM Remote Support Launcher

$scriptUrl = "https://www.ramscomputerrepair.net/remote.ps1"

try {
    irm $scriptUrl | iex
}
catch {
    [System.Windows.MessageBox]::Show(
        "Failed to launch RAM Remote Support.`nCheck internet connection or try again.",
        "RAM'S COMPUTER REPAIR"
    )
}