#------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------

function Find-SoftwareMount {
    param (
        [Alias("f")]$file
    )
    # get filesystem drives
    $fs_drives = @($env:USERPROFILE);
    $fs_drives += Get-PSDrive -PSProvider FileSystem | % {"$($_.Name):"};
    # check for mounted software
    foreach ($drive in $fs_drives) {
        if (Test-Path -Path "$drive\$file") {
            return $drive;
            break;
        }
    }
}

function Download-VMTools {
    param (
        [Alias("e")]$install_exe,
        [Alias("p")]$install_path,
        [Alias("u")]$download_url
    )
    # download vmware tools
    $download = $download_url.Split('/')[-1];
    if (!(Test-Path -Path "$install_path\$download")) {
        $request = New-Object System.Net.WebClient;
        $request.DownloadFile($download_url, $("$install_path\$download"));
    }
    # extract vmware tools
    if (!(Test-Path -Path "$install_path\$install_exe")) {
        # extract download
        Start-Process "$env:ProgramFiles\7-Zip\7z.exe" -ArgumentList "e", "-y", "$install_path\$download", "-o$install_path" -Wait;
        # check for additional files to extract
        while ($extract= Get-ChildItem -Path $install_path -Recurse | ? {$_.Name -match "(iso|zip)$"}) {
            Start-Process "$env:ProgramFiles\7-Zip\7z.exe" -ArgumentList "x", "-y", "$($extract.FullName)", "-o$install_path" -Wait;
            Remove-Item $extract.FullName -Force | Out-Null;
        }
    }
}


#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

# software
$7zx86_url = "http://www.7-zip.org/a/7z938.msi";
$7zx64_url = "http://www.7-zip.org/a/7z938-x64.msi";
$vbox_url = "http://download.virtualbox.org/virtualbox/5.0.4/VBoxGuestAdditions_5.0.4.iso";
$vmware_ws_url = "http://softwareupdate.vmware.com/cds/vmw-desktop/ws/12.0.0/2985596/windows/packages/tools-windows.tar";
$vmware_fusion_url = "http://softwareupdate.vmware.com/cds/vmw-desktop/fusion/8.0.1/3094680/packages/com.vmware.fusion.tools.windows.zip.tar";

# set vars
$vmware_url = $vmware_fusion_url;
$temp_path = "$env:windir\Temp\vmtools";


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

write-host "==> Installing VM Guest Tools" -ForegroundColor Green;


# ----- SCRIPT PREREQUSITES -----

# set vars based on bitness
$7z_url = $7zx86_url
$vmware_exe = "setup.exe";
$vbox_exe = "VBoxWindowsAdditions-x86.exe";
if ($env:PROCESSOR_ARCHITECTURE -ieq "AMD64" ) {
    $7z_url = $7zx64_url;
    $vmware_exe = "setup64.exe";
    $vbox_exe = "VBoxWindowsAdditions-amd64.exe";
}

# install 7-Zip
write-host "==> Installing 7-Zip";
$7z_bin = $7z_url.Split('/')[-1];
if (!(Test-Path -Path "$env:windir\Temp\$7z_bin")) {
    $request = New-Object System.Net.WebClient;
    $out = "$env:windir\Temp\$7z_bin";
    $request.DownloadFile($7z_url, $out);
}
$msi = "$env:windir\Temp\$7z_bin";
$arguments = @("/qb", "/i", $msi);
Start-Process -FilePath msiexec.exe `
                -ArgumentList $arguments `
                -Wait `
                -PassThru;


# ----- INSTALL VM TOOLS -----

# install vm guest tools
if ($env:PACKER_BUILDER_TYPE.Contains("vmware")) {
    $install_exe = $vmware_exe;
    $download_url = $vmware_url;
    # download vmware tools
    if (!($install_path = Find-SoftwareMount -f "VMwareToolsUpgrader.exe")) {
        $install_path = $temp_path;
        If (!(Test-Path -Path $install_path)) {
            New-Item $install_path -type directory -Force | Out-Null;
        }
        Write-Host "==> Downloading VMware Tools";
        Download-VMTools -e $install_exe -p $install_path -u $download_url;
    }
    # install vmware tools
    Write-Host "==> Installing VMware Tools";
    Start-Process "$install_path\$install_exe" -ArgumentList "/S", "/v", "/qn", "REBOOT=R", "ADDLOCAL=ALL" -Wait;
}
elseif ($env:PACKER_BUILDER_TYPE.Contains("virtualbox")) {
    $install_exe = $vbox_exe;
    $download_url = $vbox_url;
    # download vmware tools
    if (!($install_path = Find-SoftwareMount -f $install_exe)) {
        $install_path = $temp_path;
        If (!(Test-Path -Path $install_path)) {
            New-Item $install_path -type directory -Force | Out-Null;
        }
        Write-Host "==> Downloading VirtualBox Guest Additions";
        Download-VMTools -e $install_exe -p $install_path -u $download_url;
    }
    # install vmware tools
    if (Test-Path -Path "a:\oracle-cert.cer") {
        Write-Host "==> Installing Oracle certificate to keep install silent";
        certutil -addstore -f "TrustedPublisher" "a:\oracle-cert.cer";
        Write-Host "==> Installing VirtualBox Guest Additions";
        Start-Process "$install_path\$install_exe" -ArgumentList "/S" -Wait;
    }
}
else {
    Write-Host "==> ERROR: Unknown PACKER_BUILDER_TYPE: $env:PACKER_BUILDER_TYPE";
    exit;
}

# uninstall 7-zip
write-host "==> Un-Installing 7-Zip";
$7z_bin = $7z_url.Split('/')[-1];
if (!(Test-Path -Path "$env:windir\Temp\$7z_bin")) {
    $request = New-Object System.Net.WebClient;
    $out = "$env:windir\Temp\$7z_bin";
    $request.DownloadFile($7z_url, $out);
}
$msi = "$env:windir\Temp\$7z_bin";
$arguments = @("/qb", "/x", $msi);
Start-Process -FilePath msiexec.exe `
                -ArgumentList $arguments `
                -Wait `
                -PassThru;
