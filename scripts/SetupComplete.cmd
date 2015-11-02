rem This script hands off SetupComplete functionality to PowerShell

powershell -command "& {Set-ExecutionPolicy Bypass}"
powershell C:\Windows\Setup\Scripts\SetupComplete.ps1
