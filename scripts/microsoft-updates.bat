@setlocal EnableDelayedExpansion EnableExtensions
@for %%i in (a:\_packer_config*.cmd) do @call "%%~i"
@if defined PACKER_DEBUG (@echo on) else (@echo off)

title Configuring Microsoft Update. Please wait...

:: stop 'Windows Update' service
for /F "tokens=3 delims=: " %%H in ('sc query "wuauserv" ^| findstr "STATE"') do (
  if /I "%%H" NEQ "STOPPED" (
    sc stop "wuauserv"
    timeout 5
  )
)

:: enable 'Microsoft Updates'
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v EnableFeaturedSoftware /t REG_DWORD /d 1 /f

:: disable 'Recomended Updates' aka Optional Updates
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v IncludeRecommendedUpdates /t REG_DWORD /d 0 /f

:: register the Microsoft Update service with Automatic Updates.
echo Set ServiceManager = CreateObject("Microsoft.Update.ServiceManager") > A:\temp.vbs
echo Set NewUpdateService = ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") >> A:\temp.vbs
cscript A:\temp.vbs

:: start 'Windows Update' service
for /F "tokens=3 delims=: " %%H in ('sc query "wuauserv" ^| findstr "STATE"') do (
  if /I "%%H" NEQ "RUNNING" (
    sc start "wuauserv"
    timeout 5
  )
)
