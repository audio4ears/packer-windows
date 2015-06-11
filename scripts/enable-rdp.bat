@setlocal EnableDelayedExpansion EnableExtensions
@for %%i in (a:\_packer_config*.cmd) do @call "%%~i"
@if defined PACKER_DEBUG (@echo on) else (@echo off)

title Enabling Remote Desktop. Please wait...

:: Enabling 'Remote Desktop' firewall group
echo ==^> Enabling Remote Desktop firewall group
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
@if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: netsh advfirewall firewall set rule group="remote desktop" new enable=Yes

:: Allow remote connections to this computer
echo ==^> Allow remote connections to this computer
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /f /v fDenyTSConnections /t REG_DWORD /d 0
@if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /f /v fDenyTSConnections /t REG_DWORD /d 0

:: Disable available user names at login
echo ==^> Disable available user names at login
reg add "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v dontdisplaylastusername /t REG_DWORD /d 1
@if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: reg add "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v dontdisplaylastusername /t REG_DWORD /d 1

:: Disable printer redirect
echo ==^> Disable printer redirect
reg add "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd" /f /v fEnablePrintRDR /t REG_DWORD /d 0
@if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: reg add "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd" /f /v fEnablePrintRDR /t REG_DWORD /d 0
