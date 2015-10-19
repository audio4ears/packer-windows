# disable auto admin logon
Write-Host "==> Disabling AutoAdminLogon";
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' `
                 -Name AutoAdminLogon `
                 -PropertyType DWord `
                 -Value 0 `
                 -Force | Out-Null;
