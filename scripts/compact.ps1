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
# VARIABLES
#------------------------------------------------------------------------------

# 7-zip
$7zx86_url = "http://www.7-zip.org/a/7z938.msi";
$7zx64_url = "http://www.7-zip.org/a/7z938-x64.msi";

# ultradefrag-portable
$udfx86_url = "http://downloads.sourceforge.net/ultradefrag/ultradefrag-portable-6.1.0.bin.i386.zip";
$udfx64_url = "http://downloads.sourceforge.net/ultradefrag/ultradefrag-portable-6.1.0.bin.amd64.zip";


#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

$sysinfo = Get-SysInfo;
write-host "==> Compacting Windows" -ForegroundColor Green;


# ----- CLEANUP -----

# remove windows updates temp files
write-host "==> Removing Windows Update instalation files";
Stop-Service -Name wuauserv -Force;
Remove-Item $env:windir\SoftwareDistribution\Download -Recurse -Force;
New-Item -Path $env:windir\SoftwareDistribution -Name Download -ItemType directory;
Start-Service -Name wuauserv;

# remove user temp files
write-host "==> Removing User Temp files";
Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction Ignore;

# remove windows temp files
write-host "==> Removing Windows Temp files";
Remove-Item $env:windir\TEMP\* -Recurse -Force -ErrorAction Ignore;


# ----- COMPACT OS -----

if ($sysinfo.isVirtual) {
    $break = $false;
    while ($break -eq $false) {
        try {
            # install 7-Zip
            write-host "==> Installing 7-Zip";
            $7z_url = $7zx86_url;
            if ($env:PROCESSOR_ARCHITECTURE -ieq "AMD64") {
                $7z_url = $7zx64_url;
            }
            $7z_bin = $7z_url.Split('/')[-1];
            if (!(Test-Path -Path "$env:windir\$7z_bin")) {
                $request = New-Object System.Net.WebClient;
                $out = "$env:windir\$7z_bin";
                $request.DownloadFile($7z_url, $out);
            }
            $msi = "$env:windir\$7z_bin";
            $arguments = @("/qb", "/i", $msi);
            Start-Process -FilePath msiexec.exe `
                            -ArgumentList $arguments `
                            -Wait `
                            -PassThru;

            # install ultradefrag
            write-host "==> Installing UltraDefrag Portable";
            $udf_url = $udfx86_url;
            if ($env:PROCESSOR_ARCHITECTURE -ieq "AMD64") {
                $udf_url = $udfx64_url;
            }
            $udf_dir = $($udf_url.Split('/')[-1]) -replace "(\.bin|\.zip)","";
            if (!(Test-Path -Path "$env:windir\ultradefrag.zip")) {
                $request = New-Object System.Net.WebClient;
                $out = "$env:windir\ultradefrag.zip";
                $request.DownloadFile($udf_url, $out);
            }
            if (!(Test-Path -Path "$env:windir\$udf_dir\udefrag.exe")) {
                $exe = "$env:ProgramFiles\7-Zip\7z.exe";
                &$exe x "$env:windir\ultradefrag.zip" -o"$($env:windir)" -y;
            }

            # install sdelete
            write-host "==> Installing Sysinternals SDelete";
            if (!(Test-Path -Path "$env:windir\SDelete.zip")) {
                $request = New-Object System.Net.WebClient;
                $url = 'https://download.sysinternals.com/files/SDelete.zip';
                $out = "$env:windir\SDelete.zip";
                $request.DownloadFile($url, $out);
            }
            if (!(Test-Path -Path "$env:windir\sdelete.exe")) {
                $exe = "$env:ProgramFiles\7-Zip\7z.exe";
                &$exe x "$env:windir\SDelete.zip" -o"$($env:windir)" -y;
            }
        }
        catch {
            write-host "==> ERROR: $_.Exception.Message" -ForegroundColor Red;
            $break = $true;
        }

        # uninstall 7-zip
        write-host "==> Uninstalling 7-zip";
        $msi = "$env:windir\$7z_bin";
        $arguments = @("/qb", "/x", $msi);
        Start-Process -FilePath msiexec.exe `
                        -ArgumentList $arguments `
                        -Wait `
                        -PassThru;

        # defrag windows c:\
        write-host "==> Defraging C:\ drive";
        $exe = "$env:windir\$udf_dir\udefrag.exe";
        &$exe --optimize --repeat C:;

        # sdelete windows c:\
        write-host "==> Zeroing out free space on C:\";
        If (!(Test-Path -Path HKCU:\Software\Sysinternals\SDelete)) {
            New-Item -Path HKCU:\Software\Sysinternals\SDelete `
                        -Force | Out-Null;
        }
        New-ItemProperty -Path HKCU:\Software\Sysinternals\SDelete `
                            -Name EulaAccepted `
                            -PropertyType DWord `
                            -Value 1 `
                            -Force | Out-Null;
        $exe = "$env:windir\sdelete.exe";
        &$exe -q -z C:;

        # exit
        $break = $true;
    }
}
