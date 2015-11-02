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
write-host "==> Installing WinRM" -ForegroundColor Green;


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


# -----INSTALL WINRM ---

# install winrm
Write-Host "==> Enabling WinRM";
Enable-PSRemoting -SkipNetworkProfileCheck -Force;
Set-Item WSMan:\localhost\MaxTimeoutms 1800000 -Force;
Set-Item WSMan:\localhost\Client\TrustedHosts * -Force;
Set-Item WSMan:\localhost\Client\Auth\Basic $true -Force;
Set-Item WSMan:\localhost\Service\AllowUnencrypted $true -Force;
Set-Item WSMan:\localhost\Service\Auth\Basic $true -Force;
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 2048 -Force;
Set-Item WSMan:\localhost\Listener\*\Port 5985 -Force;


# ------ REMOTE ADMINISTRATION -----

# enable remote desktop connection
Write-Host "==> Enabling Remote Management";
if ($sysinfo.Version.Major -ge 6) {
  Set-NetFirewallRule -DisplayGroup "Windows Remote Management" `
                    -Profile Any `
                    -Enabled True;
}
else {
  Set-NetFirewallRule -DisplayGroup "remote administration" `
                    -Profile Any `
                    -Enabled True;
}
