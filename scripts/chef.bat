@setlocal EnableDelayedExpansion EnableExtensions
@for %%i in (a:\_packer_config*.cmd) do @call "%%~i"
@if defined PACKER_DEBUG (@echo on) else (@echo off)

title Installing Chef Client. Please wait...

:: Download chef client
if not exist "C:\Windows\Temp\chef.msi" (
  echo ==^> Downloading Chef Client
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://www.chef.io/chef/install.msi', 'C:\Windows\Temp\chef.msi')" > NUL
  @if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://www.chef.io/chef/install.msi', 'C:\Windows\Temp\chef.msi')"
)

:: Install chef client
REG QUERY HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\1945256682812F8459C51AA05AD1CF7D > NUL
if not %errorlevel% equ 0 (
  echo ==^> Installing Chef Client
  msiexec /qb /i C:\Windows\Temp\chef.msi
  @if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: msiexec /qb /i C:\Windows\Temp\chef.msi
)

:: Sleep
powershell -Command "Start-Sleep 1" <NUL
