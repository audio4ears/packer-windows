#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

Write-Host "==> Enabling Microsoft Update";

# stop windows update service
Stop-Service -Name wuauserv -Force;

# enable microsoft update
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' `
                 -Name EnableFeaturedSoftware `
                 -PropertyType DWord `
                 -Value 1 `
                 -Force | Out-Null;

# disable recomended updates (aka optional updates)
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' `
                 -Name IncludeRecommendedUpdates `
                 -PropertyType DWord `
                 -Value 0 `
                 -Force | Out-Null;

# register microsoft update with automatic updates
$ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager -Strict;
$ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") | Out-Null;

# start windows update service
Start-Service -Name wuauserv;