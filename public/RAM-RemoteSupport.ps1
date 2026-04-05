Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# =============================================
# RAM'S COMPUTER REPAIR - Remote Support Tool
# Branded PowerShell + WPF launcher scaffold
# =============================================

# -----------------------------
# CONFIG
# -----------------------------
$AppConfig = @{
    BusinessName    = "RAM'S COMPUTER REPAIR"
    AppTitle        = "RAM Remote Support"
    Tagline         = "Helping you stay connected and productive."
    Phone           = "956-244-5094"
    Website         = "https://www.ramscomputerrepair.net/"
    ReviewUrl       = "https://g.page/r/CYdLrRruJw6LEB0/review"
    RustDeskPath    = "C:\Program Files\RustDesk\rustdesk.exe"
    SupportEmail    = "Ram@RamsComputerRepair.Net"
    Version         = "0.6.9"
    CollectInfoOut  = "$env:PUBLIC\Documents\RAM-System-Info.txt"
    DiagOut         = "$env:PUBLIC\Documents\RAM-Diagnostics.txt"
    LogoPath = Join-Path ([AppDomain]::CurrentDomain.BaseDirectory) "logo.png"
    TechModePin     = "8520"
}

function Show-Message {
    param(
        [string]$Message,
        [string]$Title = "RAM Remote Support"
    )
    [System.Windows.MessageBox]::Show($Message, $Title) | Out-Null
}

function Show-FileSavedDialog {
    param(
        [string]$FilePath,
        [string]$Title = "File Saved"
    )

    $safePath = $FilePath.Replace('&', '&amp;').Replace("'", '&apos;')

    [xml]$dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$Title"
        Height="190"
        Width="480"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#111827"
        Foreground="White"
        FontFamily="Segoe UI">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Text="Your report was saved successfully."
                   FontSize="15"
                   FontWeight="Bold"
                   Margin="0,0,0,12"/>
        <TextBlock Grid.Row="1"
                   TextWrapping="Wrap"
                   Foreground="#D1D5DB">
            <Run Text="Path: "/>
            <Hyperlink x:Name="FileHyperlink" NavigateUri="$safePath">
                <Run Text="$safePath"/>
            </Hyperlink>
        </TextBlock>
        <StackPanel Grid.Row="2"
                    Orientation="Horizontal"
                    HorizontalAlignment="Right"
                    Margin="0,14,0,0">
            <Button x:Name="OpenFolderButton"
                    Content="Open Folder"
                    Width="100"
                    Height="32"
                    Margin="0,0,8,0"
                    Background="#374151"
                    Foreground="White"/>
            <Button x:Name="CloseButton"
                    Content="Close"
                    Width="90"
                    Height="32"
                    Background="#2563EB"
                    Foreground="White"/>
        </StackPanel>
    </Grid>
</Window>
"@

    $dialogReader = New-Object System.Xml.XmlNodeReader $dialogXaml
    $dialogWindow = [Windows.Markup.XamlReader]::Load($dialogReader)
    $fileHyperlink    = $dialogWindow.FindName("FileHyperlink")
    $openFolderButton = $dialogWindow.FindName("OpenFolderButton")
    $closeButton      = $dialogWindow.FindName("CloseButton")

    $fileHyperlink.Add_Click({
        try { Start-Process -FilePath $FilePath | Out-Null }
        catch { Show-Message "Unable to open file.`n`n$($_.Exception.Message)" }
    })
    $openFolderButton.Add_Click({
        try { Start-Process explorer.exe "/select,`"$FilePath`"" | Out-Null }
        catch { Show-Message "Unable to open folder.`n`n$($_.Exception.Message)" }
    })
    $closeButton.Add_Click({ $dialogWindow.Close() })
    $null = $dialogWindow.ShowDialog()
}

function Open-Url {
    param([string]$Url)
    try { Start-Process $Url | Out-Null }
    catch { Show-Message "Unable to open: $Url`n`n$($_.Exception.Message)" }
}

function Get-RustDeskPath {
    $candidatePaths = @(
        $AppConfig.RustDeskPath,
        "$PSScriptRoot\rustdesk.exe",
        "$env:ProgramFiles\RustDesk\rustdesk.exe",
        "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe",
        "$env:LOCALAPPDATA\Programs\RustDesk\rustdesk.exe"
    ) | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique
    foreach ($path in $candidatePaths) { if (Test-Path $path) { return $path } }
    return $null
}

function Start-RustDesk {
    $rustDeskExe = Get-RustDeskPath
    if ($rustDeskExe) {
        try { Start-Process -FilePath $rustDeskExe | Out-Null }
        catch { Show-Message "RustDesk was found, but could not be launched.`n`n$($_.Exception.Message)" }
    }
    else {
        Show-Message "RustDesk was not found.`n`nChecked common install locations and this tool's folder.`n`nPlace rustdesk.exe beside this launcher or install RustDesk first."
    }
}

function Get-LatestRustDeskDownloadLink {
    try {
        $page = Invoke-WebRequest -Uri 'https://github.com/rustdesk/rustdesk/releases/latest' -UseBasicParsing
        if ($page.Links) {
            $link = $page.Links | Where-Object { $_.href -match '/rustdesk/rustdesk/releases/download/.+/rustdesk.+x86_64\.exe' } | Select-Object -First 1
            if ($link) {
                if ($link.href -like 'http*') { return $link.href }
                return ('https://github.com' + $link.href)
            }
        }
        return $null
    }
    catch { return $null }
}

function Install-RustDesk {
    try {
        $existingRustDesk = Get-RustDeskPath
        if ($existingRustDesk) {
            $answer = [System.Windows.MessageBox]::Show('RustDesk appears to already be installed. Reinstall or update it now?','RustDesk Already Installed',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Show-Message 'Installing RustDesk usually requires administrator approval. Please rerun this tool as administrator if the install fails or Windows prompts for elevation.' 'Administrator Notice'
        }
        $installChoice = [System.Windows.MessageBox]::Show('Download and install RustDesk now from an official source?','Install RustDesk',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($installChoice -ne [System.Windows.MessageBoxResult]::Yes) { return }
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Start-Process -FilePath $wingetCmd.Source -ArgumentList 'install --id=RustDesk.RustDesk -e --accept-package-agreements --accept-source-agreements' -Verb RunAs -Wait
        }
        else {
            $downloadLink = Get-LatestRustDeskDownloadLink
            if (-not $downloadLink) { throw 'Could not determine the latest RustDesk download link.' }
            $tempInstaller = Join-Path $env:TEMP 'rustdesk-install.exe'
            Invoke-WebRequest -Uri $downloadLink -OutFile $tempInstaller -UseBasicParsing
            Start-Process -FilePath $tempInstaller -ArgumentList '--silent-install' -Verb RunAs -Wait
        }
        $installedPath = Get-RustDeskPath
        if ($installedPath) {
            Show-Message 'RustDesk install completed successfully.' 'Install Complete'
            Update-InternetStatus
        }
        else {
            Show-Message 'RustDesk install finished, but the launcher could not confirm the executable path yet. You may need to reopen the tool or finish any remaining installer prompts.' 'Install Check'
        }
    }
    catch {
        Show-Message "RustDesk install failed.`n`n$($_.Exception.Message)" 'Install Error'
    }
}

function Collect-SystemInfo {
    try {
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $bios           = Get-CimInstance Win32_BIOS
        $os             = Get-CimInstance Win32_OperatingSystem
        $cpu            = Get-CimInstance Win32_Processor | Select-Object -First 1
        $lastBoot = $null
        try {
            if ($os.LastBootUpTime -is [datetime]) { $lastBoot = $os.LastBootUpTime } else { $lastBoot = [datetime]$os.LastBootUpTime }
        } catch { $lastBoot = $null }
        if ($lastBoot) {
            $uptimeSpan     = (Get-Date) - $lastBoot
            $uptimeReadable = "{0} days, {1} hours, {2} minutes" -f [int]$uptimeSpan.TotalDays, $uptimeSpan.Hours, $uptimeSpan.Minutes
        } else { $uptimeReadable = 'Unavailable' }
        $ramGB   = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        $disks   = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        $network = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' }
        $report = [System.Collections.Generic.List[string]]::new()
        $report.Add('====================================')
        $report.Add("RAM'S COMPUTER REPAIR - SYSTEM INFO")
        $report.Add("Generated: $(Get-Date)")
        $report.Add('====================================')
        $report.Add('')
        $report.Add("Computer Name: $env:COMPUTERNAME")
        $report.Add("Manufacturer : $($computerSystem.Manufacturer)")
        $report.Add("Model        : $($computerSystem.Model)")
        $report.Add("Serial       : $($bios.SerialNumber)")
        $report.Add("OS           : $($os.Caption) $($os.Version)")
        $report.Add("CPU          : $($cpu.Name)")
        $report.Add("Last Boot    : $(if ($lastBoot) { $lastBoot } else { 'Unavailable' })")
        $report.Add("System Uptime: $uptimeReadable")
        $report.Add("Memory (GB)  : $ramGB")
        $report.Add('')
        $report.Add('Storage:')
        foreach ($disk in $disks) {
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $report.Add("  $($disk.DeviceID)  Size: $sizeGB GB  Free: $freeGB GB")
        }
        $report.Add('')
        $report.Add('IPv4 Addresses:')
        foreach ($ip in $network) { $report.Add("  $($ip.InterfaceAlias): $($ip.IPAddress)") }
        $report | Set-Content -Path $AppConfig.CollectInfoOut -Encoding UTF8
        Show-FileSavedDialog -FilePath $AppConfig.CollectInfoOut -Title 'System Info Saved'
    }
    catch { Show-Message "Failed to collect system information.`n`n$($_.Exception.Message)" }
}

function Run-BasicDiagnostics {
    try {
        $report = [System.Collections.Generic.List[string]]::new()
        $report.Add('====================================')
        $report.Add("RAM'S COMPUTER REPAIR - DIAGNOSTICS")
        $report.Add("Generated: $(Get-Date)")
        $report.Add('====================================')
        $report.Add('')
        $report.Add('PING TEST:')
        try {
            $ping = Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction Stop
            foreach ($reply in $ping) { $report.Add("  Reply from $($reply.Address): Time=$($reply.ResponseTime)ms Status=$($reply.StatusCode)") }
        } catch { $report.Add("  Ping test failed: $($_.Exception.Message)") }
        $report.Add('')
        $report.Add('DISK SUMMARY:')
        Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
            $sizeGB = [math]::Round($_.Size / 1GB, 2)
            $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            $report.Add("  $($_.DeviceID)  Size: $sizeGB GB  Free: $freeGB GB")
        }
        $report.Add('')
        $report.Add('TOP MEMORY PROCESSES:')
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | ForEach-Object {
            $memMB = [math]::Round($_.WorkingSet / 1MB, 2)
            $report.Add("  $($_.ProcessName) - $memMB MB")
        }
        $report.Add('')
        $report.Add('LAST BOOT TIME:')
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $report.Add("  $($os.LastBootUpTime)")
        } catch { $report.Add('  Unable to read last boot time') }
        $report | Set-Content -Path $AppConfig.DiagOut -Encoding UTF8
        Show-FileSavedDialog -FilePath $AppConfig.DiagOut -Title 'Diagnostics Saved'
    }
    catch { Show-Message "Failed to run diagnostics.`n`n$($_.Exception.Message)" }
}

function Copy-PlaceholderSupportText {
    $supportText = @"
Call RAM'S COMPUTER REPAIR at $($AppConfig.Phone)
Website: $($AppConfig.Website)
Email: $($AppConfig.SupportEmail)
"@
    try { Set-Clipboard -Value $supportText; Show-Message 'Support contact details copied to clipboard.' }
    catch { Show-Message "Could not copy support details to clipboard.`n`n$($_.Exception.Message)" }
}

function Set-LogoImage {
    param($ImageControl, $FallbackControl)
    if (-not $ImageControl) { return }
    if (-not (Test-Path $AppConfig.LogoPath)) { return }
    try {
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.UriSource = New-Object System.Uri($AppConfig.LogoPath)
        $bitmap.EndInit()
        $ImageControl.Source = $bitmap
        $ImageControl.Visibility = 'Visible'
        if ($FallbackControl) { $FallbackControl.Visibility = 'Collapsed' }
    } catch {}
}

function Show-Section {
    param([string]$SectionName)
    $ModeSelectionPanel.Visibility = if ($SectionName -eq 'ModeSelection') { 'Visible' } else { 'Collapsed' }
    $CustomerPanel.Visibility      = if ($SectionName -eq 'Customer') { 'Visible' } else { 'Collapsed' }
    $TechPanel.Visibility          = if ($SectionName -eq 'Tech') { 'Visible' } else { 'Collapsed' }
    if ($ConsentPanel) {
        $ConsentPanel.Visibility = if ($SectionName -eq 'Tech') { 'Collapsed' } else { 'Visible' }
    }
}

function Request-TechModePin {
    [xml]$pinXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Technician PIN Required"
        Height="240"
        Width="380"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#111827"
        Foreground="White"
        FontFamily="Segoe UI">
    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Text="Technician Tools" FontSize="18" FontWeight="Bold"/>
        <TextBlock Grid.Row="1" Margin="0,10,0,0" Text="Enter the technician PIN to continue." Foreground="#D1D5DB" TextWrapping="Wrap"/>
        <PasswordBox x:Name="PinBox" Grid.Row="2" Height="34" Margin="0,14,0,0" MaxLength="32" VerticalContentAlignment="Center"/>
        <TextBlock x:Name="ErrorText" Grid.Row="3" Margin="0,10,0,0" Foreground="#FCA5A5" Visibility="Collapsed" Text="Incorrect PIN."/>
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
            <Button x:Name="CancelButton" Content="Cancel" Width="90" Height="34" Margin="0,0,8,0" Background="#374151" Foreground="White" BorderBrush="#4B5563"/>
            <Button x:Name="OkButton" Content="Unlock" Width="90" Height="34" Background="#2563EB" Foreground="White" BorderThickness="0"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $pinReader = New-Object System.Xml.XmlNodeReader $pinXaml
    $pinWindow = [Windows.Markup.XamlReader]::Load($pinReader)
    $pinBox       = $pinWindow.FindName('PinBox')
    $errorText    = $pinWindow.FindName('ErrorText')
    $cancelButton = $pinWindow.FindName('CancelButton')
    $okButton     = $pinWindow.FindName('OkButton')
    $script:PinAccepted = $false
    $unlockAction = {
        if ($pinBox.Password -eq $AppConfig.TechModePin) {
            $script:PinAccepted = $true
            $pinWindow.Close()
        } else {
            $errorText.Visibility = 'Visible'
            $pinBox.Clear()
            $pinBox.Focus()
        }
    }
    $okButton.Add_Click($unlockAction)
    $cancelButton.Add_Click({ $pinWindow.Close() })
    $pinBox.Add_KeyDown({ if ($_.Key -eq 'Enter') { & $unlockAction } })
    $pinWindow.Add_ContentRendered({ $pinBox.Focus() })
    $null = $pinWindow.ShowDialog()
    return $script:PinAccepted
}

function Get-ConnectionType {
    try {
        $configs = Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPv4DefaultGateway -or $_.IPv6DefaultGateway }
        if (-not $configs) { return 'Offline' }
        $types = foreach ($cfg in $configs) {
            $alias = [string]$cfg.InterfaceAlias
            $desc  = [string]$cfg.InterfaceDescription
            $combined = ($alias + ' ' + $desc).ToLowerInvariant()
            if ($combined -match 'vpn|wireguard|openvpn|tunnel|pptp|l2tp|ikev2|forticlient|cisco anyconnect|globalprotect|tailscale|zerotier') { 'VPN' }
            elseif ($combined -match 'wi-?fi|wireless|wlan|802\.11') { 'Wi-Fi' }
            elseif ($combined -match 'bluetooth') { 'Bluetooth' }
            elseif ($combined -match 'usb|rndis|mobile|tether') { 'USB' }
            elseif ($combined -match 'ethernet|gigabit|gbe|lan|realtek|intel\(r\) ethernet') { 'Ethernet' }
            else { 'Other' }
        }
        $priority = @('VPN','Ethernet','Wi-Fi','USB','Bluetooth','Other')
        foreach ($p in $priority) { if ($types -contains $p) { return $p } }
        return ($types | Select-Object -First 1)
    } catch { return 'Unknown' }
}

function Test-InternetConnection {
    try {
        $targets = @('1.1.1.1','8.8.8.8')
        foreach ($target in $targets) { if (Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue) { return $true } }
        return $false
    } catch { return $false }
}

function Update-InternetStatus {
    if (-not $InternetStatusText) { return }
    $InternetStatusText.Text = 'Internet Status: Checking...'
    if ($ConnectionTypeText) { $ConnectionTypeText.Text = 'Connection: Detecting...'; $ConnectionTypeText.Foreground = [System.Windows.Media.Brushes]::Gainsboro }
    if ($InternetStatusLed) { $InternetStatusLed.Fill = [System.Windows.Media.Brushes]::Goldenrod }
    $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    $connectionType = Get-ConnectionType
    if ($ConnectionTypeText) { $ConnectionTypeText.Text = "Connection: $connectionType" }
    if (Test-InternetConnection) {
        $InternetStatusText.Text = 'Internet Status: Connected'
        $InternetStatusText.Foreground = [System.Windows.Media.Brushes]::LightGreen
        if ($ConnectionTypeText) { $ConnectionTypeText.Foreground = [System.Windows.Media.Brushes]::Gainsboro }
        if ($InternetStatusLed) { $InternetStatusLed.Fill = [System.Windows.Media.Brushes]::LimeGreen }
    } else {
        $InternetStatusText.Text = 'Internet Status: Not Connected'
        $InternetStatusText.Foreground = [System.Windows.Media.Brushes]::Salmon
        if ($ConnectionTypeText) { $ConnectionTypeText.Foreground = [System.Windows.Media.Brushes]::Salmon }
        if ($InternetStatusLed) { $InternetStatusLed.Fill = [System.Windows.Media.Brushes]::Red }
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RAM Remote Support"
        Height="780"
        Width="500"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#111827"
        Foreground="White"
        FontFamily="Segoe UI">
    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0"
                CornerRadius="18"
                Background="#1F2937"
                Padding="18"
                Margin="0,0,0,14"
                BorderBrush="#2563EB"
                BorderThickness="1.5">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="72"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border Width="60"
                        Height="60"
                        CornerRadius="14"
                        Background="#0F172A"
                        BorderBrush="#374151"
                        BorderThickness="1"
                        VerticalAlignment="Top">
                    <Grid>
                        <Image x:Name="LogoImage"
                               Width="48"
                               Height="48"
                               Stretch="Uniform"
                               Visibility="Collapsed"/>
                        <TextBlock x:Name="LogoFallbackText"
                                   Text="RAM"
                                   HorizontalAlignment="Center"
                                   VerticalAlignment="Center"
                                   FontSize="18"
                                   FontWeight="Bold"
                                   Foreground="#FFFFFF"/>
                    </Grid>
                </Border>
                <StackPanel Grid.Column="1" Margin="14,0,0,0">
                    <TextBlock x:Name="BusinessNameText"
                               Text="RAM'S COMPUTER REPAIR"
                               FontSize="24"
                               FontWeight="Bold"
                               TextWrapping="Wrap"/>
                    <Border Background="#2563EB"
                            CornerRadius="8"
                            Padding="8,4"
                            Margin="0,8,0,0"
                            HorizontalAlignment="Left">
                        <TextBlock x:Name="AppTitleText"
                                   Text="RAM Remote Support"
                                   FontSize="13"
                                   FontWeight="SemiBold"
                                   Foreground="White"/>
                    </Border>
                    <TextBlock x:Name="TaglineText"
                               Text="Helping you stay connected and productive."
                               FontSize="12"
                               Foreground="#D1D5DB"
                               Margin="0,10,0,0"
                               TextWrapping="Wrap"/>
                </StackPanel>
            </Grid>
        </Border>

        <Border x:Name="ConsentPanel"
                Grid.Row="1"
                CornerRadius="12"
                Background="#0F172A"
                Padding="14"
                Margin="0,0,0,14"
                BorderBrush="#374151"
                BorderThickness="1">
            <StackPanel>
                <TextBlock Text="Before starting remote support, please make sure you trust the technician assisting you."
                           TextWrapping="Wrap"
                           FontSize="12"
                           Foreground="#E5E7EB"/>
                <CheckBox x:Name="ConsentCheckBox"
                          Content="I consent to remote support for this session."
                          Margin="0,10,0,0"
                          Foreground="White"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="2">
            <Grid x:Name="ModeSelectionPanel">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Grid Grid.Row="0" Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0"
                            CornerRadius="16"
                            Background="#1F2937"
                            BorderBrush="#374151"
                            BorderThickness="1"
                            Margin="0,0,8,0"
                            Padding="16">
                        <StackPanel>
                            <TextBlock Text="Customer Mode" FontSize="17" FontWeight="Bold"/>
                            <TextBlock Text="Simple support actions for customers needing help."
                                       Margin="0,10,0,14"
                                       TextWrapping="Wrap"
                                       Foreground="#D1D5DB"/>
                            <Button x:Name="OpenCustomerModeButton"
                                    Content="Open Customer Mode"
                                    Height="42"
                                    Background="#2563EB"
                                    Foreground="White"
                                    BorderThickness="0"/>
                        </StackPanel>
                    </Border>
                    <Border Grid.Column="1"
                            CornerRadius="16"
                            Background="#1F2937"
                            BorderBrush="#374151"
                            BorderThickness="1"
                            Margin="8,0,0,0"
                            Padding="16">
                        <StackPanel>
                            <TextBlock Text="Technician Tools" FontSize="17" FontWeight="Bold"/>
                            <TextBlock Text="Diagnostics and advanced actions for RAM support staff."
                                       Margin="0,10,0,14"
                                       TextWrapping="Wrap"
                                       Foreground="#D1D5DB"/>
                            <Button x:Name="OpenTechModeButton"
                                    Content="Open Technician Tools"
                                    Height="42"
                                    Background="#374151"
                                    Foreground="White"
                                    BorderBrush="#4B5563"/>
                        </StackPanel>
                    </Border>
                </Grid>

                <Border Grid.Row="1"
                        VerticalAlignment="Top"
                        CornerRadius="16"
                        Background="#1F2937"
                        Padding="18"
                        BorderBrush="#374151"
                        BorderThickness="1">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <Grid Grid.Row="0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="3*"/>
                                <ColumnDefinition Width="2*" MinWidth="240"/>
                            </Grid.ColumnDefinitions>

                            <TextBlock Grid.ColumnSpan="2"
                                       Text="Use this tool only with RAM'S COMPUTER REPAIR support staff."
                                       FontSize="12"
                                       Foreground="#D1D5DB"
                                       TextWrapping="Wrap"
                                       Margin="0,34,0,0"/>

                            <StackPanel Grid.Column="0" Margin="0,0,18,0">
                                <TextBlock Text="Need help right now?"
                                           FontSize="18"
                                           FontWeight="Bold"
                                           TextWrapping="Wrap"/>
                            </StackPanel>

                            <StackPanel Grid.Column="1"
                                        HorizontalAlignment="Right"
                                        VerticalAlignment="Top">
                                <TextBlock x:Name="PhoneText"
                                           Text="956-244-5094"
                                           FontSize="24"
                                           FontWeight="Bold"
                                           Foreground="#FFFFFF"
                                           HorizontalAlignment="Right"
                                           TextWrapping="NoWrap"
                                           TextTrimming="None"
                                           MinWidth="220"/>
                            </StackPanel>
                        </Grid>

                        <StackPanel Grid.Row="1" Margin="0,14,0,0">

    <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="!"
                   FontSize="16"
                   FontWeight="Bold"
                   Width="20"
                   Height="20"
                   TextAlignment="Center"
                   Background="#F87171"
                   Foreground="White"
                   Margin="0,0,8,0"
                   Padding="0"/>

        <TextBlock Text="SCAM WARNING"
                   FontSize="16"
                   FontWeight="Bold"
                   Foreground="#F87171"
                   VerticalAlignment="Center"/>
    </StackPanel>

    <TextBlock Text="RAM'S COMPUTER REPAIR will NEVER contact you unexpectedly to start a remote support session. ANY unsolicited call is a scam! DO NOT allow access! Hang up immediately and call us directly using the number shown here."
               FontSize="13"
               FontWeight="Bold"
               Foreground="#FCA5A5"
               TextWrapping="Wrap"
               Margin="0,4,0,0"/>

</StackPanel>
                    </Grid>
                </Border>
            </Grid>

            <Grid x:Name="CustomerPanel" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <DockPanel Margin="0,0,0,12">
                    <Button x:Name="CustomerBackButton"
                            Content="Back"
                            Width="90"
                            Height="34"
                            Background="#374151"
                            Foreground="White"
                            BorderBrush="#4B5563"
                            DockPanel.Dock="Left"/>
                    <TextBlock Text="Customer Mode"
                               FontSize="18"
                               FontWeight="Bold"
                               VerticalAlignment="Center"
                               Margin="12,0,0,0"/>
                </DockPanel>
                <Button x:Name="StartSupportButton"
                        Grid.Row="1"
                        Content="Start Remote Support"
                        Height="56"
                        Margin="0,0,0,10"
                        FontSize="16"
                        FontWeight="Bold"
                        Background="#2563EB"
                        Foreground="White"
                        BorderThickness="0"/>
                <UniformGrid Grid.Row="2" Rows="3" Columns="2" Margin="0,0,0,10">
                    <Button x:Name="WebsiteButton"
                            Content="Open Website"
                            Height="46"
                            Margin="0,0,8,10"
                            Background="#1F2937"
                            Foreground="White"
                            BorderBrush="#374151"/>
                    <Button x:Name="ReviewButton"
                            Content="Read Google Reviews"
                            Height="46"
                            Margin="8,0,0,10"
                            Background="#1F2937"
                            Foreground="White"
                            BorderBrush="#374151"/>
                    <Button x:Name="CopySupportButton"
                            Content="Copy Contact Info"
                            Height="46"
                            Margin="0,0,8,10"
                            Background="#374151"
                            Foreground="White"
                            BorderBrush="#4B5563"/>
                    <Button x:Name="InstallRustDeskButton"
                            Content="Install RustDesk"
                            Height="46"
                            Margin="8,0,0,10"
                            Background="#2563EB"
                            Foreground="White"
                            BorderThickness="0"/>
                    <Button x:Name="CollectInfoButton"
                            Content="Collect System Info"
                            Height="46"
                            Margin="0,0,8,0"
                            Background="#1F2937"
                            Foreground="White"
                            BorderBrush="#374151"/>
                </UniformGrid>
            </Grid>

            <Grid x:Name="TechPanel" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <DockPanel Margin="0,0,0,12">
                    <Button x:Name="TechBackButton"
                            Content="Back"
                            Width="90"
                            Height="34"
                            Background="#374151"
                            Foreground="White"
                            BorderBrush="#4B5563"
                            DockPanel.Dock="Left"/>
                    <TextBlock Text="Technician Tools"
                               FontSize="18"
                               FontWeight="Bold"
                               VerticalAlignment="Center"
                               Margin="12,0,0,0"/>
                </DockPanel>
                <UniformGrid Grid.Row="1" Rows="8" Columns="2" Margin="0,0,0,10">
                    <Button x:Name="DiagnosticsButton" Content="Run Diagnostics" Height="46" Margin="0,0,8,10" Background="#2563EB" Foreground="White" BorderThickness="0"/>
                    <Button x:Name="TechCollectInfoButton" Content="Collect System Info" Height="46" Margin="8,0,0,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="TaskManagerButton" Content="Task Manager" Height="46" Margin="0,0,8,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="ResourceMonitorButton" Content="Resource Monitor" Height="46" Margin="8,0,0,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="EventViewerButton" Content="Event Viewer" Height="46" Margin="0,0,8,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="ReliabilityMonitorButton" Content="Reliability Monitor" Height="46" Margin="8,0,0,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="DeviceManagerButton" Content="Device Manager" Height="46" Margin="0,0,8,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="ServicesButton" Content="Services" Height="46" Margin="8,0,0,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="CmdButton" Content="Command Prompt" Height="46" Margin="0,0,8,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="MemoryDiagnosticButton" Content="Memory Diagnostic" Height="46" Margin="8,0,0,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="AdminPowerShellButton" Content="Admin PowerShell" Height="46" Margin="0,0,8,10" Background="#2563EB" Foreground="White" BorderThickness="0"/>
                    <Button x:Name="CopyRamTechCommandButton" Content="Copy RAM Tech Command" Height="46" Margin="8,0,0,10" Background="#2563EB" Foreground="White" BorderThickness="0"/>
                    <Button x:Name="TechWebsiteButton" Content="Open Website" Height="46" Margin="0,0,8,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                    <Button x:Name="TechPortalButton" Content="Open Portal" Height="46" Margin="8,0,0,10" Background="#1F2937" Foreground="White" BorderBrush="#374151"/>
                </UniformGrid>
            </Grid>
        </Grid>

        <Grid Grid.Row="3" Margin="0,14,0,0">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Border Grid.Row="0" CornerRadius="10" Background="#1F2937" Padding="10" Margin="0,0,0,10" BorderBrush="#374151" BorderThickness="1">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="1.25*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="0.95*"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Left">
                        <Ellipse x:Name="InternetStatusLed" Width="12" Height="12" Fill="#F59E0B" Stroke="#111827" StrokeThickness="1" Margin="0,0,8,0"/>
                        <TextBlock x:Name="InternetStatusText" Text="Internet Status: Checking..." FontSize="12" FontWeight="SemiBold" Foreground="#D1D5DB" VerticalAlignment="Center"/>
                    </StackPanel>
                    <Button x:Name="RefreshInternetButton" Grid.Column="1" Content="Refresh" Width="72" Height="28" Margin="28,0,8,0" Background="#374151" Foreground="White" BorderBrush="#4B5563" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    <TextBlock x:Name="ConnectionTypeText" Grid.Column="2" Text="Connection: Detecting..." FontSize="12" FontWeight="SemiBold" Foreground="#D1D5DB" VerticalAlignment="Center" HorizontalAlignment="Right"/>
                </Grid>
            </Border>
            <DockPanel Grid.Row="1">
                <TextBlock x:Name="FooterBrandText" DockPanel.Dock="Left" Foreground="#9CA3AF" FontSize="11" Text="RAM'S COMPUTER REPAIR"/>
                <TextBlock x:Name="FooterVersionText" DockPanel.Dock="Right" HorizontalAlignment="Right" Foreground="#9CA3AF" FontSize="11" Text="Version 0.6.9"/>
            </DockPanel>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$ConsentPanel            = $window.FindName("ConsentPanel")
$ConsentCheckBox         = $window.FindName("ConsentCheckBox")
$ModeSelectionPanel      = $window.FindName("ModeSelectionPanel")
$CustomerPanel           = $window.FindName("CustomerPanel")
$TechPanel               = $window.FindName("TechPanel")
$OpenCustomerModeButton  = $window.FindName("OpenCustomerModeButton")
$OpenTechModeButton      = $window.FindName("OpenTechModeButton")
$CustomerBackButton      = $window.FindName("CustomerBackButton")
$TechBackButton          = $window.FindName("TechBackButton")
$StartSupportButton      = $window.FindName("StartSupportButton")
$CollectInfoButton       = $window.FindName("CollectInfoButton")
$InstallRustDeskButton   = $window.FindName("InstallRustDeskButton")
$TechCollectInfoButton   = $window.FindName("TechCollectInfoButton")
$DiagnosticsButton       = $window.FindName("DiagnosticsButton")
$EventViewerButton       = $window.FindName("EventViewerButton")
$TaskManagerButton       = $window.FindName("TaskManagerButton")
$DeviceManagerButton     = $window.FindName("DeviceManagerButton")
$ServicesButton          = $window.FindName("ServicesButton")
$ReliabilityMonitorButton = $window.FindName("ReliabilityMonitorButton")
$ResourceMonitorButton   = $window.FindName("ResourceMonitorButton")
$MemoryDiagnosticButton  = $window.FindName("MemoryDiagnosticButton")
$CmdButton               = $window.FindName("CmdButton")
$AdminPowerShellButton   = $window.FindName("AdminPowerShellButton")
$WebsiteButton           = $window.FindName("WebsiteButton")
$TechWebsiteButton       = $window.FindName("TechWebsiteButton")
$TechPortalButton        = $window.FindName("TechPortalButton")
$CopyRamTechCommandButton = $window.FindName("CopyRamTechCommandButton")
$ReviewButton            = $window.FindName("ReviewButton")
$CopySupportButton       = $window.FindName("CopySupportButton")
$PhoneText               = $window.FindName("PhoneText")
$BusinessNameText        = $window.FindName("BusinessNameText")
$AppTitleText            = $window.FindName("AppTitleText")
$TaglineText             = $window.FindName("TaglineText")
$FooterBrandText         = $window.FindName("FooterBrandText")
$FooterVersionText       = $window.FindName("FooterVersionText")
$LogoImage               = $window.FindName("LogoImage")
$LogoFallbackText        = $window.FindName("LogoFallbackText")
$InternetStatusText      = $window.FindName("InternetStatusText")
$InternetStatusLed       = $window.FindName("InternetStatusLed")
$RefreshInternetButton   = $window.FindName("RefreshInternetButton")
$ConnectionTypeText      = $window.FindName("ConnectionTypeText")

$window.Title           = $AppConfig.AppTitle
$BusinessNameText.Text  = $AppConfig.BusinessName
$AppTitleText.Text      = $AppConfig.AppTitle
$TaglineText.Text       = $AppConfig.Tagline
$PhoneText.Text         = $AppConfig.Phone
$FooterBrandText.Text   = $AppConfig.BusinessName
$FooterVersionText.Text = "Version $($AppConfig.Version)"
Set-LogoImage -ImageControl $LogoImage -FallbackControl $LogoFallbackText
Show-Section -SectionName 'ModeSelection'
Update-InternetStatus

$OpenCustomerModeButton.Add_Click({ Show-Section -SectionName 'Customer' })
$OpenTechModeButton.Add_Click({ if (Request-TechModePin) { Show-Section -SectionName 'Tech' } })
$CustomerBackButton.Add_Click({ Show-Section -SectionName 'ModeSelection' })
$TechBackButton.Add_Click({ Show-Section -SectionName 'ModeSelection' })
$StartSupportButton.Add_Click({
    if (-not $ConsentCheckBox.IsChecked) {
        Show-Message 'Please confirm consent before starting remote support.'
        return
    }
    Start-RustDesk
})
$CollectInfoButton.Add_Click({ Collect-SystemInfo })
$TechCollectInfoButton.Add_Click({ Collect-SystemInfo })
$InstallRustDeskButton.Add_Click({ Install-RustDesk })
$DiagnosticsButton.Add_Click({ Run-BasicDiagnostics })
$EventViewerButton.Add_Click({ try { Start-Process eventvwr.msc | Out-Null } catch { Show-Message "Unable to open Event Viewer.`n`n$($_.Exception.Message)" } })
$TaskManagerButton.Add_Click({ try { Start-Process taskmgr.exe | Out-Null } catch { Show-Message "Unable to open Task Manager.`n`n$($_.Exception.Message)" } })
$DeviceManagerButton.Add_Click({ try { Start-Process devmgmt.msc | Out-Null } catch { Show-Message "Unable to open Device Manager.`n`n$($_.Exception.Message)" } })
$ServicesButton.Add_Click({ try { Start-Process services.msc | Out-Null } catch { Show-Message "Unable to open Services.`n`n$($_.Exception.Message)" } })
$ReliabilityMonitorButton.Add_Click({ try { Start-Process perfmon.exe -ArgumentList '/rel' | Out-Null } catch { Show-Message "Unable to open Reliability Monitor.`n`n$($_.Exception.Message)" } })
$ResourceMonitorButton.Add_Click({ try { Start-Process resmon.exe | Out-Null } catch { Show-Message "Unable to open Resource Monitor.`n`n$($_.Exception.Message)" } })
$MemoryDiagnosticButton.Add_Click({ try { Start-Process mdsched.exe | Out-Null } catch { Show-Message "Unable to open Memory Diagnostic.`n`n$($_.Exception.Message)" } })
$CmdButton.Add_Click({
    try { Start-Process cmd.exe | Out-Null }
    catch { Show-Message "Unable to open Command Prompt.`n`n$($_.Exception.Message)" }
})
$AdminPowerShellButton.Add_Click({
    try {
        Start-Process powershell.exe -Verb RunAs | Out-Null
    }
    catch {
        Show-Message "Unable to open Administrator PowerShell.`n`n$($_.Exception.Message)"
    }
})
$WebsiteButton.Add_Click({ Open-Url -Url $AppConfig.Website })
$TechWebsiteButton.Add_Click({ Open-Url -Url $AppConfig.Website })
$TechPortalButton.Add_Click({ Open-Url -Url ($AppConfig.Website.TrimEnd('/') + '/RAMeow') })
$CopyRamTechCommandButton.Add_Click({
    try {
        Set-Clipboard -Value 'irm "https://www.ramscomputerrepair.net/ram.ps1" | iex'
        Show-Message 'RAM Tech Utility launch command copied to clipboard.'
    }
    catch {
        Show-Message "Could not copy RAM Tech command to clipboard.`n`n$($_.Exception.Message)"
    }
})
$ReviewButton.Add_Click({ Open-Url -Url $AppConfig.ReviewUrl })
$CopySupportButton.Add_Click({ Copy-PlaceholderSupportText })
$RefreshInternetButton.Add_Click({ Update-InternetStatus })

$null = $window.ShowDialog()
