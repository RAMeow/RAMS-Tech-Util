function Invoke-WPFRAMShowRoadmap {
    $roadmap = @"
RAM Tools roadmap

Current module tracks:

Repairs
- Windows repair actions
- Cleanup helpers
- technician one-click tasks

Diagnostics
- Quick health checks
- network and update checks
- common issue triage

Business Tools
- New PC setup bundles
- small business onboarding
- standard software packs

Planned later:
- Client presets
- Intake workflows
- Service note helpers

This tab is the starter structure for custom RAM-native modules.
"@

    Write-Host "[RAM Tools] Displaying roadmap" -ForegroundColor Cyan
    Show-CustomDialog -Title "RAM Tools Roadmap" -Message $roadmap -Width 560 -Height 460 -EnableScroll $true
}
