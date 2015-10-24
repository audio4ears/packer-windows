#------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------

function  Get-SysInfo {
    # define hash structure
    $os = @{};
    $os['Caption'] = "";
    $os['DomainRole'] = "";
    $os['Manufacturer'] = "";
    $os['Model'] = "";
    $os['Name'] = "";
    $os['ProductType'] = "";
    $os['Version'] = @{};
    $os['isServer'] = $false;
    $os['isVirtual'] = $false;

    # populate hash with operating system info
    $wmiOS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName .;
    $os.Caption = $wmiOS.Caption;
    $os.ProductType = $wmiOS.ProductType;
    $wmiCS = Get-WmiObject -Class Win32_ComputerSystem -ComputerName .;
    $os.DomainRole = $wmiCS.DomainRole;
    $os.Name = $wmiCS.Name;
    $os.Manufacturer = $wmiCS.Manufacturer;
    $os.Model = $wmiCS.Model;
    $ver = [environment]::OSVersion.Version;
    $os['Version']['Major'] = $ver.Major;
    $os['Version']['Minor'] = $ver.Minor;
    $os['Version']['Build'] = $ver.Build;

    # determine if os is server version
    if ($os.ProductType -eq 3) {
        $os.isServer = $true;
    }
    # determine if os is virtual
    if ($os.Model -imatch "(HVM|Parallels|Virtual Machine|VirtualBox|VMware|Xen)") {
        $os.isVirtual = $true;
    }

    # return
    return $os;
}


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

$sysinfo = Get-SysInfo;
write-host "==> Customizing $($sysinfo.Caption)" -ForegroundColor Green;


# ----- SCRIPT PREREQUSITES -----

# disable user account control
write-host "==> Turning off User Account Control (UAC)";
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
                 -Name EnableLUA `
                 -PropertyType DWord `
                 -Value 0 `
                 -Force | Out-Null;
write-host "==> Changing remote UAC account policy";
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system `
                 -Name LocalAccountTokenFilterPolicy `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;

# set powershell execution policy
write-host "==> Setting the PowerShell ExecutionPolicy to Bypass";
Set-ExecutionPolicy -ExecutionPolicy Bypass `
                    -Force | Out-Null;


# ----- NETWORKING -----

# set network location to private
write-host "==> Setting Public Network Connection Locations to Private";
if ( ($sysinfo.Version.Major -ge 6) -and (1,3,4,5 -notcontains $sysinfo.DomainRole) ) {
    $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"));
    $networkConnections = $networkListManager.GetNetworkConnections();
    $networkConnections | foreach {
        if ($_.GetNetwork().GetCategory() -eq 0) {    
            $_.GetNetwork().SetCategory(1);
        }
    }
}

# disable find other machines on the network prompt
write-host "==> Disabling new network prompt";
if (!(Test-Path -Path HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff)) {
    New-Item -Path HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff `
             -Force | Out-Null;
}

# enable icmpv4 ping
Write-Host "==> Enabling ICMPv4 Ping Support";
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" `
                    -Profile Any `
                    -Enabled True;

# disable ipv6
write-host "==> Disabling IPv6 protocol";
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters `
                 -Name DisabledComponents `
                 -PropertyType DWord `
                 -Value 0xffffffff `
                 -Force | Out-Null;


# ----- CUSTOMIZE TERMINAL -----

# enable command prompt quickedit mode
write-host "==> Enabling Powershell and Command Prompt QuickEdit mode";
New-ItemProperty -Path HKCU:\Console `
                 -Name QuickEdit `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;


# ----- CUSTOMIZE WINDOWS GUI -----

# show run command in Start Menu
write-host "==> Enabling Show Run in Start Menu flag";
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name Start_ShowRun `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;

# set taskbar icons to small
write-host "==> Setting taskbar icons to small";
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name TaskbarSmallIcons `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;

# set control panel icons to small
write-host "==> Setting Control Panel icons to small";
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel `
                 -Name AllItemsIconView `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel `
                 -Name StartupPage `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;

# hide windows store apps on the taskbar
write-host "==> Hide Windows Store apps on the taskbar";
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name StoreAppsOnTaskbar `
                 -PropertyType DWord `
                 -Value 0 `
                 -Force | Out-Null;

# disable available user names at login
write-host "==> Disabling available user names at login";
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
                 -Name dontdisplaylastusername `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;


# ----- CUSTOMIZE EXPLORER -----

# item check boxes
write-host "==> Setting item check boxes flag to disable";
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name AutoCheckSelect `
                 -PropertyType DWord `
                 -Value 0 `
                 -Force | Out-Null;

# show file extensions
write-host "==> Setting show file extensions flag to enable";
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name HideFileExt `
                 -PropertyType DWord `
                 -Value 0 `
                 -Force | Out-Null;

# hide hidden files and folders
write-host "==> Setting hide hidden files and folders flag to disable";
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name Hidden `
                 -PropertyType DWord `
                 -Value 2 `
                 -Force | Out-Null;

# display full path
write-host "==> Setting display full path flag to enable";
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name FullPath `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                 -Name FullPathAddress `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;


# ----- SERVER VERSIONS ONLY -----

if ($sysinfo.isServer) {

    # ----- CUSTOMIZE WINDOWS GUI -----

    # show admin tools in start menu
    write-host "==> Enabling Administrative Tools in Start Menu";
    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
                     -Name StartMenuAdminTools `
                     -PropertyType DWord `
                     -Value 1 `
                     -Force | Out-Null;


    # ------ REMOTE ADMINISTRATION -----

    # enable remote desktop connection
    Write-Host "==> Enabling Remote Desktop Connections";
    Set-NetFirewallRule -DisplayGroup "Remote Desktop" `
                     -Profile Any `
                     -Enabled True;
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                     -Name fDenyTSConnections `
                     -PropertyType DWord `
                     -Value 0 `
                     -Force | Out-Null;


    # ----- POWER SETTINGS -----

    # set power configuration to high performance
    write-host "==> Setting power configuration to High Performance";
    cmd.exe /c powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c;

    # diable hibernation file
    write-host "==> Setting Hibernation File Size to 0";
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Power `
                     -Name HibernateFileSizePercent `
                     -PropertyType DWord `
                     -Value 0 `
                     -Force | Out-Null;
    write-host "==> Disabling Hibernation Mode";
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Power `
                     -Name HibernateEnabled `
                     -PropertyType DWord `
                     -Value 0 `
                     -Force | Out-Null;
}

Start-Sleep -s 10;
