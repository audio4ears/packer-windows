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
write-host "==> Preparing $($sysinfo.Caption) for Sysprep" -ForegroundColor Green;


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

# copy setupcomplete scripts to c:\windows\setup\scripts\
write-host "==> Copying SetupComplete scripts";
# create c:\windows\setup\scripts if missing
if (!(Test-Path -Path "C:\Windows\Setup\Scripts")) {
  try {
    New-Item -Path "C:\Windows\Setup\Scripts" `
      -ItemType Directory `
      -Force | Out-Null;
  }
  Catch [system.exception] {
    $sysprep_error = $_.Exception.Message;
  }
}
# copy setupcomplete.cmd
if (Test-Path -Path "a:\SetupComplete.cmd") {
    try {
        Copy-Item "a:\SetupComplete.cmd" `
            -Destination "$env:windir\Setup\Scripts\SetupComplete.cmd" `
            -ErrorAction Stop `
            -Force;
    }
    Catch [system.exception] {
        $sysprep_error = $_.Exception.Message;
    }
}
# copy setupcomplete.ps1 or use customize-windows.ps1 instead
if (Test-Path -Path "a:\SetupComplete.ps1") {
    try {
        Copy-Item "a:\SetupComplete.ps1" `
            -Destination "$env:windir\Setup\Scripts\SetupComplete.ps1" `
            -ErrorAction Stop `
            -Force;
    }
    Catch [system.exception] {
        $sysprep_error = $_.Exception.Message;
    }
}
elseif (Test-Path -Path "a:\customize-windows.ps1") {
    try {
        Copy-Item "a:\customize-windows.ps1" `
            -Destination "$env:windir\Setup\Scripts\SetupComplete.ps1" `
            -ErrorAction Stop `
            -Force;
    }
    Catch [system.exception] {
        $sysprep_error = $_.Exception.Message;
    }
}

# remove previous sysprep answerfiles
# https://technet.microsoft.com/en-us/library/cc749415%28v=ws.10%29.aspx
Write-Host "==> Removing previous Sysprep answerfiles"
$answerfiles = @('Autounattend.xml',
                  'Unattend.xml');
$directories = @("$env:windir\Panther",
                  "$env:windir\Panther\Unattend",
                  "$env:windir\System32\Sysprep",
                  "$env:SystemDrive");
$directories | % {
    if (Test-Path -Path $_ -PathType Container) {
        $dir = $_;
        $answerfiles | % {
            if (Test-Path -Path "$dir\$_") {
                Write-Host "Removed: $dir\$_";
                Remove-Item -Path "$dir\$_" -Force;
            }
        }
    }
}


# ------ SYSPREP ------
Write-Host "==> Beginning Sysprep";
# copy unattend.xml to c:\windows\system32\sysprep directory
if (Test-Path -Path "a:\Unattend.xml") {
    try {
        Copy-Item "a:\Unattend.xml" `
            -Destination "$env:windir\Panther" `
            -ErrorAction Stop `
            -Force;
            #-Destination "$env:windir\System32\Sysprep" `
    }
    Catch [system.exception] {
        $sysprep_error = $_.Exception.Message;
    }
}
else {
    $sysprep_error = "File not found - a:\Unattend.xml";
}

# if no errors are found, proceed with sysprep
If ($sysprep_error) {
    Write-Host "==> ERROR: $sysprep_error" -ForegroundColor Red;
    Write-Host "==> ERROR: Please run Sysprep manually" -ForegroundColor Red;
}
#else {
#    $exe = "$env:windir\System32\Sysprep\sysprep.exe";
#    &$exe /generalize /oobe /quit /unattend:C:\Windows\System32\Sysprep\Unattend.xml;
#}
