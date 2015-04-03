@setlocal EnableDelayedExpansion EnableExtensions
@for %%i in (%~dp0\_packer_config*.cmd) do @call "%%~i"
@if defined PACKER_DEBUG (@echo on) else (@echo off)


title Setting network configuration. Please wait...

echo ==^> Disabling new network prompt
reg add "HKLM\System\CurrentControlSet\Control\Network\NewNetworkWindowOff"
echo ==^> Enabling icmpv4 Echo Request
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
echo ==^> Disabling ipv6 protocol
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /f /v DisabledComponents /t REG_DWORD /d 0xffffffff


title Setting folder options. Please wait...

echo ==^> Setting folder options
echo ==^> Show file extensions
:: Default is 1 - hide file extensions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v HideFileExt /t REG_DWORD /d 0
echo ==^> Show hidden files and folders
:: Default is 2 - do not show hidden files and folders
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v Hidden /t REG_DWORD /d 1
echo ==^> Display Full path
:: Default FullPath 0 and FullPathAddress 0
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v FullPath /t REG_DWORD /d 1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v FullPathAddress /t REG_DWORD /d 1


title Setting power configuration. Please wait...

echo ==^> Setting power configuration to High Performance
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo ==^> Zero Hibernation File
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /f /v HibernateFileSizePercent /t REG_DWORD /d 0
echo ==^> Disable Hibernation Mode
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /f /v HibernateEnabled /t REG_DWORD /d 0


title Setting command prompt personalization. Please wait...

echo ==^> Enable QuickEdit mode
:: Default is 1 - Disable QuickEdit mode
reg add "HKCU\Console /v QuickEdit /t REG_DWORD /d 0 /f
echo ==^> Show Run command in Start Menu
:: Default is 0 - Disable Show Run
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v Start_ShowRun /t REG_DWORD /d 1


title Setting UI personalization. Please wait...

echo ==^> Set taskbar icons: small
:: Default is 0 - Display Large Icons
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarSmallIcons /t REG_QWORD /d 1
echo ==^> Show Administrative Tools in Start Menu
:: Default is 0 - Don't Show Administrator Tools
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v StartMenuAdminTools /t REG_DWORD /d 1
echo ==^> Disable available user names at login
:: Default is 0 - Display Last UserName
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v dontdisplaylastusername /t REG_DWORD /d 1


:exit0

ver>nul

goto :exit

:exit1

verify other 2>nul

:exit
